#!/bin/sh
# groups/vi.sh — ITEMS: vim nvim (both offered — pick one or both; design §3.3)
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

ITEMS="${ITEMS:-vim}"

has_item vim  && pkg_install vim
has_item nvim && pkg_install neovim
exit 0
