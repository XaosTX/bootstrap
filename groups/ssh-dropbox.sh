#!/bin/sh
# groups/ssh-dropbox.sh — restore SSH keys kept encrypted in Dropbox (the old deferred step). OFF by default.
# ITEMS: decrypt-keys
#
# Downloads every *.enc file in DROPBOX_KEY_DIR, decrypts it with the passphrase you type, and
# puts the keys into ~/.ssh. Files that already exist in ~/.ssh are never overwritten.
# The Dropbox token and the passphrase are typed in (hidden) and never stored.
# Archive format matches `encrypt`/`decrypt` in the dotfiles bin/: openssl aes-256-cbc + tar.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

DROPBOX_KEY_DIR="${DROPBOX_KEY_DIR:-/dotfiles/ssh_keys}"

if ! has_item decrypt-keys; then
  log_arrow "decrypt-keys not selected — nothing to do"
  exit 0
fi
if [ "${DRY_RUN:-0}" = 1 ]; then
  log_arrow "[dry-run] download *.enc from Dropbox $DROPBOX_KEY_DIR and decrypt into ~/.ssh"
  exit 0
fi
pkg_install curl jq openssl

# hidden prompt, from the terminal
ask_secret() {
  printf '%s: ' "$1" >&2
  stty -echo 2>/dev/null || true
  read -r as_val </dev/tty
  stty echo 2>/dev/null || true
  printf '\n' >&2
  printf '%s\n' "$as_val"
}

# Token: check it against the list endpoint; three tries
tries=0
while :; do
  token=$(ask_secret "Dropbox access token")
  # the token goes to curl on stdin (a config), so it stays off the command line
  status=$(printf 'header = "Authorization: Bearer %s"\nheader = "Content-Type: application/json"\n' "$token" \
    | curl -s -o /dev/null -w '%{http_code}' -K - -X POST \
        --data "{\"path\":\"$DROPBOX_KEY_DIR\"}" https://api.dropboxapi.com/2/files/list_folder) || status=000
  [ "$status" = 200 ] && break
  tries=$((tries + 1))
  if [ "$tries" -ge 3 ]; then
    log_error "Dropbox token rejected (HTTP $status) — giving up"
    exit 1
  fi
  log_error "Dropbox token rejected (HTTP $status) — try again"
done

# Encrypted files in the folder
enc_paths=$(printf 'header = "Authorization: Bearer %s"\nheader = "Content-Type: application/json"\n' "$token" \
  | curl -fsS -K - -X POST --data "{\"path\":\"$DROPBOX_KEY_DIR\"}" https://api.dropboxapi.com/2/files/list_folder \
  | jq -r '.entries[] | select(.path_lower | endswith(".enc")) | .path_lower')
if [ -z "$enc_paths" ]; then
  log_error "no .enc keys found in Dropbox $DROPBOX_KEY_DIR"
  exit 1
fi

mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Passphrase, asked once and checked on the first archive
pass=$(ask_secret "Private encryption key")

for path in $enc_paths; do
  name=$(basename "$path" .enc)
  if [ -e "$HOME/.ssh/$name" ]; then
    log_success "$name already in ~/.ssh — skipping"
    continue
  fi
  printf 'header = "Authorization: Bearer %s"\n' "$token" \
    | curl -fsS -K - -X POST -o "$work/$name.enc" \
        -H "Dropbox-API-Arg: {\"path\":\"$path\"}" https://content.dropboxapi.com/2/files/download

  # -pass env: keeps the passphrase out of the process list
  mkdir -p "$work/$name.x"
  if ! DF_KEY_PASS="$pass" openssl enc -aes-256-cbc -d -in "$work/$name.enc" -pass env:DF_KEY_PASS \
      | tar xz -C "$work/$name.x"; then
    log_error "could not decrypt $name — wrong passphrase?"
    exit 1
  fi
  for f in "$work/$name.x"/*; do
    base=$(basename "$f")
    if [ -e "$HOME/.ssh/$base" ]; then
      log_success "$base already in ~/.ssh — skipping"
      continue
    fi
    cp "$f" "$HOME/.ssh/$base"
    case "$base" in
      *.pub) chmod 644 "$HOME/.ssh/$base" ;;
      *)     chmod 600 "$HOME/.ssh/$base" ;;
    esac
    log_success "restored $base"
  done
done
