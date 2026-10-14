#!/bin/sh
# groups/vim-plugins.sh — install vim plugins once the dotfiles are linked (ported from the 2018 steps)
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"

if ! command -v vim >/dev/null 2>&1; then
  log_arrow "vim is not installed — pick vi (vim) first; skipping plugins"
  exit 0
fi

# UTF-8 locale: the vimrc uses non-ASCII listchars (Linux only; macOS has no C.UTF-8).
# </dev/null: no keypress prompts. A plugin-manager-less vimrc just reports an error here.
if [ "$(uname)" = Darwin ]; then
  run vim +PlugInstall +qall </dev/null || log_arrow "vim plugin install reported errors (no vim-plug in this variant?)"
else
  run env LANG=C.UTF-8 LC_ALL=C.UTF-8 vim +PlugInstall +qall </dev/null || log_arrow "vim plugin install reported errors (no vim-plug in this variant?)"
fi
