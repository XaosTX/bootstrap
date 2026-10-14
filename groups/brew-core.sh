#!/bin/sh
# groups/brew-core.sh — core Homebrew packages and casks (tools/brew/init/Brewfile). macOS only.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

brew_bundle "$BOOTSTRAP_DIR/tools/brew/init/Brewfile"
