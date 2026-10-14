#!/bin/sh
# groups/rosetta.sh — Rosetta 2 on Apple Silicon (adapted from codeangler's bootstrap). macOS only.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"

if [ "$(uname)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
  log_arrow "rosetta: Apple Silicon Macs only — skipping"
  exit 0
fi
run softwareupdate --install-rosetta --agree-to-license
