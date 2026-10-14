#!/bin/sh
# groups/macos-apps.sh — open App Store pages for apps you want (adapted from codeangler's bootstrap). macOS only.
# ITEMS: divvy rdp wireguard flycut focus
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

if [ "$(uname)" != Darwin ]; then
  log_arrow "macos-apps: macOS only — skipping"
  exit 0
fi

has_item divvy     && run open "https://apps.apple.com/us/app/divvy-window-manager/id413857545?mt=12"
has_item rdp       && run open "https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12"
has_item wireguard && run open "https://apps.apple.com/us/app/wireguard/id1451685025?mt=12"
has_item flycut    && run open "https://apps.apple.com/us/app/flycut-clipboard-manager/id442160987?mt=12"
has_item focus     && run open "https://apps.apple.com/us/app/be-focused-focus-timer/id973134470?mt=12"
exit 0
