#!/bin/sh
# groups/vim-plugins.sh — run :PlugInstall, for the dotfiles plug variant only.
# The submodule variant ships its plugins inside the repo, so there is nothing to install.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"

if ! command -v vim >/dev/null 2>&1; then
  log_arrow "vim is not installed — pick vi (vim) first; skipping plugins"
  exit 0
fi

# Only the plug variant calls plug#begin in its vimrc
if [ ! -f "$HOME/.vimrc" ] || ! grep -q 'plug#begin' "$HOME/.vimrc" 2>/dev/null; then
  log_arrow "vimrc does not use vim-plug (submodule variant) — nothing to install"
  exit 0
fi

# UTF-8 locale: the vimrc uses non-ASCII listchars (Linux only; macOS has no C.UTF-8).
# </dev/null: no keypress prompts.
if [ "$(uname)" = Darwin ]; then
  run vim +PlugInstall +qall </dev/null
else
  run env LANG=C.UTF-8 LC_ALL=C.UTF-8 vim +PlugInstall +qall </dev/null
fi
