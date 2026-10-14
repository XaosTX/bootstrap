#!/bin/sh
# groups/npm.sh — npm 12+ and the release cooldown (tools/npm/harden.sh; docs/npm-hardening.md)
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"

sh "$BOOTSTRAP_DIR/tools/npm/harden.sh"
