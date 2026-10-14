#!/bin/sh
# lib/pkg.sh — package-manager abstraction (design §3.2)
# Groups call pkg_update / pkg_install / pkg_has — never raw apt/dnf/apk/pacman.
# Requires lib/log.sh. Self-detects PKG_MGR if the entrypoint didn't set it.

if [ -z "${PKG_MGR:-}" ]; then
  # shellcheck disable=SC1091
  . "${BOOTSTRAP_DIR:-$HOME/g/bootstrap}/lib/os.sh"
  PKG_MGR=$(detect_pkg_mgr "$(detect_distro)")
fi

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO=sudo
fi

# generic name -> package name for the active manager (exceptions only; design §3.2 table)
pkg_map() {
  case "$PKG_MGR" in
    apt) case "$1" in
      fd)  echo fd-find ;;
      pip) echo python3-pip ;;
      dig) echo dnsutils ;;
      avahi)       echo avahi-daemon ;;
      nss-mdns)    echo libnss-mdns ;;
      nfs-client)  echo nfs-common ;;
      *)   echo "$1" ;;
    esac ;;
    dnf) case "$1" in
      build-essential) echo "@development-tools" ;;
      fd)  echo fd-find ;;
      pip) echo python3-pip ;;
      dig) echo bind-utils ;;
      avahi-utils) echo avahi-tools ;;
      nfs-client)  echo nfs-utils ;;
      *)   echo "$1" ;;
    esac ;;
    apk) case "$1" in
      build-essential) echo build-base ;;
      pip) echo py3-pip ;;
      dig) echo bind-tools ;;
      avahi-utils) echo avahi-tools ;;
      nfs-client)  echo nfs-utils ;;
      *)   echo "$1" ;;
    esac ;;
    brew) case "$1" in
      ncat) echo nmap ;;
      pip)  echo python3 ;;  # pip ships with the python3 formula; there is no pip formula
      *)    echo "$1" ;;
    esac ;;
    pacman) case "$1" in
      build-essential) echo base-devel ;;
      pip) echo python-pip ;;
      dig) echo bind ;;
      gh)  echo github-cli ;;
      nfs-client) echo nfs-utils ;;
      *)   echo "$1" ;;
    esac ;;
    *) echo "$1" ;;
  esac
}

# generic name -> the binary it provides (when they differ)
pkg_bin() {
  case "$1" in
    fd)   if [ "$PKG_MGR" = apt ]; then echo fdfind; else echo fd; fi ;;
    bat)  if [ "$PKG_MGR" = apt ]; then echo batcat; else echo bat; fi ;;
    ripgrep)              echo rg ;;
    dig|dnsutils)         echo dig ;;
    gnupg)                echo gpg ;;
    build-essential)      echo cc ;;
    python|python3)       echo python3 ;;
    pip)                  echo pip3 ;;
    neovim)               echo nvim ;;
    cifs-utils)           echo mount.cifs ;;
    nfs-client)           echo mount.nfs ;;
    avahi)                echo avahi-daemon ;;
    avahi-utils)          echo avahi-browse ;;
    google-chrome-stable) echo google-chrome ;;
    firefox-esr)          echo firefox-esr ;;
    *)                    echo "$1" ;;
  esac
}

pkg_has() {
  command -v "$(pkg_bin "$1")" >/dev/null 2>&1
}

pkg_update() {
  # shellcheck disable=SC2086
  case "$PKG_MGR" in
    apt)    run $SUDO apt-get update -y ;;
    dnf)    run $SUDO dnf check-update || true ;;
    apk)    run $SUDO apk update ;;
    pacman) run $SUDO pacman -Sy ;;
    brew)   run brew update ;;
    *) log_error "pkg_update: unsupported manager '$PKG_MGR'"; return 1 ;;
  esac
}

pkg_install() {
  for p in "$@"; do
    if pkg_has "$p"; then
      log_success "$p already installed"
      continue
    fi
    pi_mapped=$(pkg_map "$p")
    # shellcheck disable=SC2086
    if case "$PKG_MGR" in
      apt)    run $SUDO apt-get install -y "$pi_mapped" ;;
      dnf)    run $SUDO dnf install -y "$pi_mapped" ;;
      apk)    run $SUDO apk add "$pi_mapped" ;;
      pacman) run $SUDO pacman -S --noconfirm --needed "$pi_mapped" ;;
      brew)   run brew install "$pi_mapped" ;;
      *)      log_error "pkg_install: unsupported manager '$PKG_MGR'"; false ;;
    esac; then
      log_success "$p installed"
    else
      log_error "$p failed to install"
    fi
  done
}

# apt only: add a third-party signed repo (idempotent).
# apt_add_repo <name> <key-url> <repo-line>
apt_add_repo() {
  [ "$PKG_MGR" = apt ] || { log_error "apt_add_repo called on non-apt system"; return 1; }
  ar_keyring="/etc/apt/keyrings/$1.gpg"
  ar_list="/etc/apt/sources.list.d/$1.list"

  if [ ! -f "$ar_keyring" ]; then
    if [ "${DRY_RUN:-0}" = 1 ]; then
      log_arrow "[dry-run] fetch key $2 -> $ar_keyring"
    else
      # shellcheck disable=SC2086
      $SUDO mkdir -p /etc/apt/keyrings
      ar_tmp=$(mktemp)
      curl -fsSL "$2" -o "$ar_tmp"
      # keys ship armored or binary — normalize to a binary keyring
      # shellcheck disable=SC2086
      if grep -q "BEGIN PGP" "$ar_tmp"; then
        gpg --dearmor <"$ar_tmp" | $SUDO tee "$ar_keyring" >/dev/null
      else
        $SUDO cp "$ar_tmp" "$ar_keyring"
      fi
      rm -f "$ar_tmp"
      # shellcheck disable=SC2086
      $SUDO chmod 644 "$ar_keyring"
      log_success "keyring $ar_keyring added"
    fi
  fi

  if [ ! -f "$ar_list" ]; then
    if [ "${DRY_RUN:-0}" = 1 ]; then
      log_arrow "[dry-run] add repo: $3"
    else
      # shellcheck disable=SC2086
      echo "$3" | $SUDO tee "$ar_list" >/dev/null
      # shellcheck disable=SC2086
      $SUDO apt-get update -y
      log_success "repo $1 added"
    fi
  fi
}

# brew_bundle <Brewfile> — macOS packages and casks; prints only under DRY_RUN
brew_bundle() {
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] brew bundle --file=$1"
    return 0
  fi
  brew bundle --file="$1"
}
