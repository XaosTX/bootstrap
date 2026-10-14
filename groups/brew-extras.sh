#!/bin/sh
# groups/brew-extras.sh — optional Brewfiles (tools/brew/<item>/Brewfile). macOS only.
# ITEMS: browsers networking archiving-media llm virtualization visualization-graphs-diagrams python-dev security vscode-fonts gits
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

for item in $ITEMS; do
  file="$BOOTSTRAP_DIR/tools/brew/$item/Brewfile"
  if [ -f "$file" ]; then
    brew_bundle "$file"
  else
    log_error "no Brewfile for '$item' at $file"
  fi
done
