#!/bin/sh
# groups/fzf.sh — fzf with key bindings and completion, without editing rc files (dotfiles load ~/.fzf.zsh)
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

pkg_install fzf

if command -v brew >/dev/null 2>&1 && [ -x "$(brew --prefix)/opt/fzf/install" ]; then
  run "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc
fi
