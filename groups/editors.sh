#!/bin/sh
# groups/editors.sh — VS Code + verified `code` CLI (design §3.3)
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

if command -v code >/dev/null 2>&1; then
  log_success "VS Code already installed"
elif [ "$PKG_MGR" = apt ]; then
  apt_add_repo vscode \
    "https://packages.microsoft.com/keys/microsoft.asc" \
    "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/vscode.gpg] https://packages.microsoft.com/repos/code stable main"
  pkg_install code
elif [ "$PKG_MGR" = brew ]; then
  run brew install --cask visual-studio-code
else
  log_error "VS Code install not wired for $PKG_MGR yet"
fi

# Verify the `code` CLI — don't assume (design: `code .` must work from a terminal)
if [ "${DRY_RUN:-0}" = 1 ]; then
  log_arrow "[dry-run] verify 'code' CLI on PATH"
elif command -v code >/dev/null 2>&1; then
  log_success "'code' CLI on PATH: $(command -v code)"
elif [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
  mkdir -p "$HOME/.local/bin"
  run ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" "$HOME/.local/bin/code"
  log_success "'code' CLI symlinked into ~/.local/bin"
else
  log_error "'code' CLI not on PATH after install"
fi

log_arrow "Extensions/settings: sign in and enable Settings Sync (Ctrl+Shift+P → 'Settings Sync: Turn On')"
