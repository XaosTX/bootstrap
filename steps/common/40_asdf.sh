# asdf: version manager. Installed by Homebrew on macOS (brew/Brewfile); cloned on Linux.
# Core plugin: nodejs (latest LTS). Other plugins are not ported yet (see asdf/README.md).
ASDF_VERSION=v0.14.0
ASDF_DIR="${ASDF_DIR:-$HOME/.asdf}"
if ! command -v asdf >/dev/null 2>&1 && [ ! -f "$ASDF_DIR/asdf.sh" ]; then
  if ! is_osx && command -v git >/dev/null 2>&1; then
    e_header "Installing asdf $ASDF_VERSION"
    git clone --depth 1 --branch "$ASDF_VERSION" https://github.com/asdf-vm/asdf.git "$ASDF_DIR"
  fi
fi
[ -f "$ASDF_DIR/asdf.sh" ] && . "$ASDF_DIR/asdf.sh"
if ! command -v asdf >/dev/null 2>&1; then e_error "asdf is not available (macOS: brew bundle first)"; return 1; fi
while read -r plugin url; do
  [ -z "$plugin" ] && continue
  asdf plugin add "$plugin" ${url:+"$url"} >/dev/null 2>&1 || true
done < "$BOOT_ROOT/asdf/plugins.txt"
e_header "Installing Node.js (latest LTS)"
asdf install nodejs lts && asdf global nodejs lts
