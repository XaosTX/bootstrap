#!/bin/sh
# groups/homelab.sh — LAN / NAS integration
# ITEMS: mdns discovery nas-smb nas-nfs
#
# Mounts Synology shares on this box. NAS-side paths like /volume1/music never
# exist locally — the share `music` lands at $NAS_SMB_ROOT/music (default
# /mnt/nas/music). Entries are systemd automounts: nothing is mounted until
# something touches the path, and a powered-off NAS never blocks boot.
#
# Per-machine settings live in ~/.config/bootstrap/homelab.conf
# (copy groups/homelab.conf.example). No secrets in this repo — the SMB
# password is prompted once and written to a root-only credentials file.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

ITEMS="${ITEMS:-mdns nas-smb}"

# ──────────────────────────────────────────────
#  Config
# ──────────────────────────────────────────────
HOMELAB_CONF="${HOMELAB_CONF:-$HOME/.config/bootstrap/homelab.conf}"
if [ -f "$HOMELAB_CONF" ]; then
  # shellcheck disable=SC1090
  . "$HOMELAB_CONF"
  log_success "config: $HOMELAB_CONF"
else
  log_arrow "no $HOMELAB_CONF — using defaults"
  log_arrow "copy $BOOTSTRAP_DIR/groups/homelab.conf.example to customize"
fi

NAS_HOST="${NAS_HOST:-nas.local}"
NAS_SMB_USER="${NAS_SMB_USER:-$(id -un)}"
NAS_SMB_SHARES="${NAS_SMB_SHARES:-music photo video}"
NAS_SMB_ROOT="${NAS_SMB_ROOT:-/mnt/nas}"
NAS_SMB_OPTS="${NAS_SMB_OPTS:-}"
NAS_NFS_EXPORTS="${NAS_NFS_EXPORTS:-}"
NAS_NFS_ROOT="${NAS_NFS_ROOT:-/mnt/nfs}"
SMB_CRED_FILE="${SMB_CRED_FILE:-/etc/samba/credentials/$NAS_HOST}"
NAS_IDLE_TIMEOUT="${NAS_IDLE_TIMEOUT:-600}"

FSTAB=/etc/fstab
MARK_BEGIN='# >>> bootstrap homelab >>>'
MARK_END='# <<< bootstrap homelab <<<'

MY_UID=$(id -u)
MY_GID=$(id -g)

# ──────────────────────────────────────────────
#  Helpers
# ──────────────────────────────────────────────

# A share spec is `share`, `/volume1/share`, or either of those plus `:mountname`.
# Remote half: what the NAS calls it, minus any /volume<N>/ prefix and alias.
share_remote() {
  echo "${1%%:*}" | sed -e 's#^/*volume[0-9]*/##' -e 's#^/##' -e 's#/$##'
}
# Local half: the `:alias` when given, else the share name. Lets `PlexMediaServer`
# mount at /mnt/nas/plex without renaming anything on the NAS.
share_local() {
  case "$1" in
    *:*) echo "${1##*:}" ;;
    *)   share_remote "$1" ;;
  esac
}

ensure_mountpoint() {
  if [ -d "$1" ]; then
    log_success "$1 exists"
  else
    # shellcheck disable=SC2086
    run $SUDO mkdir -p "$1"
    log_success "created $1"
  fi
}

# Replace the marked block in /etc/fstab with stdin. Verifies before installing.
fstab_apply() {
  fa_body=$(cat)
  fa_new=$(mktemp)

  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip   { print }
  ' "$FSTAB" >"$fa_new"

  if [ -n "$fa_body" ]; then
    printf '%s\n%s\n%s\n' "$MARK_BEGIN" "$fa_body" "$MARK_END" >>"$fa_new"
  fi

  if diff -q "$FSTAB" "$fa_new" >/dev/null 2>&1; then
    rm -f "$fa_new"
    log_success "$FSTAB already up to date"
    return 0
  fi

  if [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] would write to $FSTAB:"
    printf '%s\n' "$fa_body" | sed 's/^/      /'
    rm -f "$fa_new"
    return 0
  fi

  # A bad fstab can strand a box at boot — refuse to install one that fails checks.
  if command -v findmnt >/dev/null 2>&1; then
    if ! findmnt --verify --tab-file "$fa_new" >/dev/null 2>&1; then
      log_error "generated fstab failed 'findmnt --verify' — NOT written"
      findmnt --verify --tab-file "$fa_new" 2>&1 | sed 's/^/      /' >&2 || true
      rm -f "$fa_new"
      return 1
    fi
  fi

  # shellcheck disable=SC2086
  $SUDO cp -a "$FSTAB" "$FSTAB.bootstrap.bak"
  # shellcheck disable=SC2086
  $SUDO cp "$fa_new" "$FSTAB"
  # shellcheck disable=SC2086
  $SUDO chmod 644 "$FSTAB"
  rm -f "$fa_new"
  log_success "$FSTAB updated (backup: $FSTAB.bootstrap.bak)"
}

# Prompt once for the SMB password, store it root-only. Never echoed, never in argv.
smb_credentials() {
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] would prompt for SMB password -> $SMB_CRED_FILE"
    return 0
  fi
  # shellcheck disable=SC2086
  if $SUDO test -f "$SMB_CRED_FILE"; then
    log_success "credentials already at $SMB_CRED_FILE"
    return 0
  fi
  if [ ! -r /dev/tty ]; then
    log_error "no TTY — cannot prompt for the SMB password"
    log_arrow "create $SMB_CRED_FILE by hand (username=/password= lines, chmod 600)"
    return 1
  fi

  printf 'SMB password for %s@%s: ' "$NAS_SMB_USER" "$NAS_HOST" >/dev/tty
  stty -echo </dev/tty
  read -r sc_pw </dev/tty
  stty echo </dev/tty
  printf '\n' >/dev/tty

  if [ -z "$sc_pw" ]; then
    log_error "empty password — skipping credentials file"
    return 1
  fi

  sc_dir=$(dirname "$SMB_CRED_FILE")
  # shellcheck disable=SC2086
  $SUDO mkdir -p "$sc_dir"
  # shellcheck disable=SC2086
  $SUDO chmod 700 "$sc_dir"
  # heredoc, not argv — the password never appears in `ps`
  # shellcheck disable=SC2086
  $SUDO sh -c "umask 077; cat > '$SMB_CRED_FILE'" <<EOF
username=$NAS_SMB_USER
password=$sc_pw
EOF
  sc_pw=""
  # shellcheck disable=SC2086
  $SUDO chown root:root "$SMB_CRED_FILE"
  # shellcheck disable=SC2086
  $SUDO chmod 600 "$SMB_CRED_FILE"
  log_success "credentials written to $SMB_CRED_FILE (root-only, 600)"
}

# ──────────────────────────────────────────────
#  mdns — make the NAS hostname resolve without DNS
# ──────────────────────────────────────────────
if has_item mdns; then
  pkg_install avahi nss-mdns
  if command -v systemctl >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    run $SUDO systemctl enable --now avahi-daemon.service || \
      log_error "could not enable avahi-daemon"
  fi
  if [ "${DRY_RUN:-0}" != 1 ]; then
    if getent hosts "$NAS_HOST" >/dev/null 2>&1; then
      log_success "$NAS_HOST resolves to $(getent hosts "$NAS_HOST" | awk '{print $1}')"
    else
      log_error "$NAS_HOST does not resolve — set NAS_HOST to the IP in $HOMELAB_CONF"
    fi
  fi
fi

# ──────────────────────────────────────────────
#  discovery — poke at the LAN
# ──────────────────────────────────────────────
if has_item discovery; then
  pkg_install avahi-utils arp-scan
  log_arrow "avahi-browse -art        # every mDNS service on the LAN"
  log_arrow "sudo arp-scan --localnet # every live host"
fi

# ──────────────────────────────────────────────
#  Build the fstab block
# ──────────────────────────────────────────────
FSTAB_BODY=""
add_line() { FSTAB_BODY="$FSTAB_BODY$1
"; }

if has_item nas-smb; then
  pkg_install cifs-utils
  smb_credentials || log_error "SMB credentials not set up — mounts will fail until they are"

  smb_opts="credentials=$SMB_CRED_FILE,uid=$MY_UID,gid=$MY_GID"
  smb_opts="$smb_opts,file_mode=0664,dir_mode=0775,iocharset=utf8"
  smb_opts="$smb_opts,nofail,_netdev,x-systemd.automount"
  smb_opts="$smb_opts,x-systemd.idle-timeout=$NAS_IDLE_TIMEOUT,x-systemd.mount-timeout=15"
  [ -n "$NAS_SMB_OPTS" ] && smb_opts="$smb_opts,$NAS_SMB_OPTS"

  for s in $NAS_SMB_SHARES; do
    sname=$(share_remote "$s")
    [ -z "$sname" ] && continue
    smp="$NAS_SMB_ROOT/$(share_local "$s")"
    ensure_mountpoint "$smp"
    add_line "//$NAS_HOST/$sname $smp cifs $smb_opts 0 0"
    log_arrow "smb  //$NAS_HOST/$sname -> $smp"
  done
fi

if has_item nas-nfs; then
  pkg_install nfs-client

  if [ -z "$NAS_NFS_EXPORTS" ]; then
    log_error "nas-nfs selected but NAS_NFS_EXPORTS is empty in $HOMELAB_CONF"
    log_arrow "example: NAS_NFS_EXPORTS=\"/volume1/music /volume1/video\""
  fi

  nfs_opts="nofail,_netdev,x-systemd.automount"
  nfs_opts="$nfs_opts,x-systemd.idle-timeout=$NAS_IDLE_TIMEOUT,x-systemd.mount-timeout=15"
  nfs_opts="$nfs_opts,soft,timeo=150,retrans=3"

  for e in $NAS_NFS_EXPORTS; do
    ename=$(share_remote "$e")
    [ -z "$ename" ] && continue
    # NFS wants the full DSM path; config may give either form (minus any alias)
    espec=${e%%:*}
    case "$espec" in
      /*) epath=$espec ;;
      *)  epath="/volume1/$espec" ;;
    esac
    nmp="$NAS_NFS_ROOT/$(share_local "$e")"
    ensure_mountpoint "$nmp"
    add_line "$NAS_HOST:$epath $nmp nfs $nfs_opts 0 0"
    log_arrow "nfs  $NAS_HOST:$epath -> $nmp"
  done
fi

# ──────────────────────────────────────────────
#  Apply
# ──────────────────────────────────────────────
if has_item nas-smb || has_item nas-nfs; then
  printf '%s' "$FSTAB_BODY" | fstab_apply

  if [ "${DRY_RUN:-0}" != 1 ] && command -v systemctl >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    run $SUDO systemctl daemon-reload
    log_success "systemd reloaded — automount units are live"
  fi

  log_arrow "shares mount on first access; 'ls $NAS_SMB_ROOT/…' triggers it"
  log_arrow "DSM: https://$NAS_HOST:5001"
fi

exit 0
