#!/bin/sh
# groups/desktop.sh — ITEMS: postman keepassxc wireshark
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

ITEMS="${ITEMS:-keepassxc}"

has_item keepassxc && pkg_install keepassxc
if has_item wireshark; then
  # apt asks a debconf question (allow non-root capture) — interactive is fine on a desktop
  pkg_install wireshark
fi

if has_item postman; then
  if command -v postman >/dev/null 2>&1 || [ -x /opt/Postman/Postman ]; then
    log_success "Postman already installed"
  elif [ "${PROFILE_HAS_SNAP:-0}" = 1 ] && command -v snap >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    run $SUDO snap install postman
    log_success "Postman installed via snap"
  elif [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] install Postman tarball to /opt/Postman (no snap on this profile)"
  else
    # Debian/Mint: no snap — official linux64 tarball into /opt
    pm_tmp=$(mktemp /tmp/postman-XXXXXX.tar.gz)
    curl -fsSL -o "$pm_tmp" "https://dl.pstmn.io/download/latest/linux_64"
    # shellcheck disable=SC2086
    $SUDO tar xzf "$pm_tmp" -C /opt
    rm -f "$pm_tmp"
    # shellcheck disable=SC2086
    $SUDO ln -sf /opt/Postman/Postman /usr/local/bin/postman
    if [ -d "$HOME/.local/share/applications" ] || mkdir -p "$HOME/.local/share/applications"; then
      cat >"$HOME/.local/share/applications/postman.desktop" <<'EOF'
[Desktop Entry]
Name=Postman
Exec=/opt/Postman/Postman
Icon=/opt/Postman/app/resources/app/assets/icon.png
Type=Application
Categories=Development;
EOF
    fi
    log_success "Postman installed to /opt/Postman"
  fi
fi
exit 0
