#!/bin/sh
# groups/asdf.sh — asdf version manager + plugin menu (wires existing tools/asdf/)
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

ASDF_DIR="$HOME/.asdf"

if command -v asdf >/dev/null 2>&1 || [ -d "$ASDF_DIR" ]; then
  log_success "asdf already installed"
else
  run git clone https://github.com/asdf-vm/asdf.git "$ASDF_DIR" --branch v0.14.0
  log_success "asdf cloned to $ASDF_DIR"
fi

# Wire asdf into future zsh + bash logins
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if ! grep -q 'asdf.sh' "$rc" 2>/dev/null; then
    if [ "${DRY_RUN:-0}" = 1 ]; then
      log_arrow "[dry-run] source asdf in $rc"
    else
      # shellcheck disable=SC2016  # $HOME must stay literal in the rc file
      printf '\n. "$HOME/.asdf/asdf.sh"\n. "$HOME/.asdf/completions/asdf.bash"\n' >>"$rc"
      log_success "asdf sourced in $rc"
    fi
  fi
done

# Plugin picker (interactive) — needs a TTY, e.g. not under bare curl|sh
if [ "${DRY_RUN:-0}" = 1 ]; then
  log_arrow "[dry-run] tools/asdf/init.sh plugin menu"
elif [ -r /dev/tty ]; then
  bash "$BOOTSTRAP_DIR/tools/asdf/init.sh" "$BOOTSTRAP_DIR" </dev/tty
else
  log_arrow "No TTY — skipping plugin menu; run tools/asdf/init.sh later"
fi
