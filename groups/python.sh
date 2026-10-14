#!/bin/sh
# groups/python.sh — system python3 + pip + uv (design §4.1/§7.1: uv owns Python)
# ITEMS may add: via-asdf (opt-in for one-manager purists)
# Policy: deps live in a uv venv, never global pip (design §7.2).
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

pkg_install python3 pip

if command -v uv >/dev/null 2>&1; then
  log_success "uv already installed"
else
  # uv isn't packaged in Debian/Ubuntu apt — official installer drops it in ~/.local/bin
  run sh -c 'curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh'
  log_arrow "uv installed to ~/.local/bin (PATH comes from the dotfiles) — pin interpreters with 'uv python install 3.x.y'"
fi

if has_item via-asdf; then
  if command -v asdf >/dev/null 2>&1 || [ -d "$HOME/.asdf" ]; then
    run sh -c '. "$HOME/.asdf/asdf.sh" 2>/dev/null; asdf plugin add python 2>/dev/null || true'
    log_arrow "asdf python plugin added — 'asdf install python <version>' to build one"
  else
    log_arrow "via-asdf selected but asdf not installed — select the asdf group first"
  fi
fi
exit 0
