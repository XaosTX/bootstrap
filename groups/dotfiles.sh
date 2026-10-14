#!/bin/sh
# groups/dotfiles.sh — clone/pull XaosTX/dotfiles and run its install.sh (symlinks, settings, variants)
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"
. "$BOOTSTRAP_DIR/lib/dirs.sh"

DOTFILES="${DOTFILES_DIR:-$HOME/g/dotfiles}"
DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/XaosTX/dotfiles.git}"

pkg_install git
ensure_repo "$DOTFILES" "$DOTFILES_REPO_URL"

if [ ! -f "$DOTFILES/install.sh" ]; then
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] would run $DOTFILES/install.sh"
    exit 0
  fi
  log_error "$DOTFILES/install.sh is missing — nothing to run"
  exit 1
fi

# First run asks for identity and work values; --yes keeps what is already saved
if [ "${DRY_RUN:-0}" = 1 ]; then
  bash "$DOTFILES/install.sh" --dry-run --yes
elif [ "${ASSUME_YES:-0}" = 1 ] || [ ! -r /dev/tty ]; then
  bash "$DOTFILES/install.sh" --yes
else
  bash "$DOTFILES/install.sh" </dev/tty
fi
log_success "dotfiles install ran"
