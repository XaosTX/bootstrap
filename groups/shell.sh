#!/bin/sh
# groups/shell.sh — zsh + tab completion + default shell (light QoL; full config is dotfiles' job)
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

pkg_install zsh bash-completion

case "${SHELL:-}" in
  *zsh)
    log_success "zsh is already the default shell" ;;
  *)
    if command -v zsh >/dev/null 2>&1; then
      # chsh prompts for a password when run as the user; under `curl | sh`
      # stdin isn't a TTY and the prompt fails silently. Root chsh skips the
      # prompt, so prefer sudo; otherwise attach the real TTY for the prompt.
      if [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
        run $SUDO chsh -s "$(command -v zsh)" "$(id -un)"
        log_success "Default shell set to zsh — re-login to take effect"
      elif [ -r /dev/tty ]; then
        if run chsh -s "$(command -v zsh)" </dev/tty; then
          log_success "Default shell set to zsh — re-login to take effect"
        else
          log_error "chsh failed — run manually: chsh -s $(command -v zsh)"
        fi
      else
        log_error "No sudo and no TTY — run manually: chsh -s $(command -v zsh)"
      fi
    fi ;;
esac
