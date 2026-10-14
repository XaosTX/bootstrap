#!/bin/sh
# groups/macos-defaults.sh — Dock settings (adapted from codeangler's bootstrap). macOS only.
# ITEMS: dock dock-clear-apps
#   dock             left side, 40px tiles, fast autohide
#   dock-clear-apps  empties the pinned apps list (every Dock icon goes). OFF by default.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"

if [ "$(uname)" != Darwin ]; then
  log_arrow "macos-defaults: macOS only — skipping"
  exit 0
fi

if has_item dock-clear-apps; then
  run defaults write com.apple.dock persistent-apps -array
fi
if has_item dock; then
  run defaults write com.apple.dock orientation left
  run defaults write com.apple.dock tilesize -integer 40
  run defaults write com.apple.dock autohide-time-modifier -float 1
fi
run killall Dock 2>/dev/null || true
