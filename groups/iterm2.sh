#!/bin/sh
# groups/iterm2.sh — load iTerm2 preferences from ~/.iterm2 (ported from the 2018 steps). macOS only.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"

if [ "$(uname)" != Darwin ]; then
  log_arrow "iterm2: macOS only — skipping"
  exit 0
fi

run defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$HOME/.iterm2"
run defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
log_success "iTerm2 reads preferences from $HOME/.iterm2"
