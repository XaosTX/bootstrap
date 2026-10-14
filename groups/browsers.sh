#!/bin/sh
# groups/browsers.sh — ITEMS: chrome brave firefox
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

ITEMS="${ITEMS:-brave firefox}"

if has_item chrome; then
  if command -v google-chrome >/dev/null 2>&1; then
    log_success "Chrome already installed"
  elif [ "$PKG_MGR" = apt ]; then
    apt_add_repo google-chrome \
      "https://dl.google.com/linux/linux_signing_key.pub" \
      "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main"
    pkg_install google-chrome-stable
  else
    log_error "Chrome install not wired for $PKG_MGR yet"
  fi
fi

if has_item brave; then
  if command -v brave-browser >/dev/null 2>&1; then
    log_success "Brave already installed"
  elif [ "$PKG_MGR" = apt ]; then
    apt_add_repo brave-browser \
      "https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" \
      "deb [signed-by=/etc/apt/keyrings/brave-browser.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"
    pkg_install brave-browser
  else
    log_error "Brave install not wired for $PKG_MGR yet"
  fi
fi

if has_item firefox; then
  if command -v firefox >/dev/null 2>&1 || command -v firefox-esr >/dev/null 2>&1; then
    log_success "Firefox already installed"
  elif [ "${PROFILE:-}" = debian ]; then
    pkg_install firefox-esr
  else
    # Note: on Ubuntu the apt 'firefox' package is a snap shim — acceptable there
    pkg_install firefox
  fi
fi
exit 0
