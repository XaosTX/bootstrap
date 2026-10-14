#!/bin/sh
# groups/base-cli.sh — core CLI QoL (design §3.3)
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

pkg_install git curl wget jq ripgrep fd bat tree unzip gnupg stow tmux

# Debian/Ubuntu ship bat/fd as batcat/fdfind — expose the standard names
if [ "$PKG_MGR" = apt ]; then
  mkdir -p "$HOME/.local/bin"
  if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    log_success "bat → batcat symlink at ~/.local/bin/bat"
  fi
  if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log_success "fd → fdfind symlink at ~/.local/bin/fd"
  fi
fi
