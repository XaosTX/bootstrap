#!/bin/sh
# groups/fonts.sh — Nerd Fonts. ITEMS: jetbrains sauce inconsolata
#   jetbrains    JetBrainsMono Nerd Font (latest release)
#   sauce        SauceCode Pro Nerd Font Medium (pinned)
#   inconsolata  Inconsolata Nerd Font Regular (pinned)
# macOS: ~/Library/Fonts. Linux: ~/.local/share/fonts, then fc-cache.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

NERD_TAG=v3.5.1
NERD_BASE="https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_TAG"
if [ "$(uname)" = Darwin ]; then
  FONT_DIR="$HOME/Library/Fonts"
else
  FONT_DIR="$HOME/.local/share/fonts"
fi

# install_font <label> <marker-file> <zip-url> <pattern>
install_font() {
  if [ -e "$FONT_DIR/$2" ]; then
    log_success "$1 already installed"
    return 0
  fi
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] $1 -> $FONT_DIR"
    return 0
  fi
  f_tmp=$(mktemp -d)
  curl -fsSL -o "$f_tmp/font.zip" "$3"
  mkdir -p "$FONT_DIR"
  unzip -oqj "$f_tmp/font.zip" "$4" -d "$FONT_DIR"
  rm -rf "$f_tmp"
  log_success "$1 installed"
}

if has_item jetbrains || has_item sauce || has_item inconsolata; then
  pkg_install unzip
  [ "$(uname)" = Darwin ] || pkg_install fontconfig
fi
has_item jetbrains   && install_font "JetBrainsMono Nerd Font" "JetBrainsMonoNerdFont-Regular.ttf" \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" "JetBrainsMonoNerdFont-*.ttf"
has_item sauce       && install_font "SauceCode Pro Nerd Font" "SauceCodeProNerdFont-Medium.ttf" \
  "$NERD_BASE/SourceCodePro.zip" "SauceCodeProNerdFont-Medium.ttf"
has_item inconsolata && install_font "Inconsolata Nerd Font" "InconsolataNerdFont-Regular.ttf" \
  "$NERD_BASE/Inconsolata.zip" "InconsolataNerdFont-Regular.ttf"

if [ "$(uname)" != Darwin ] && [ "${DRY_RUN:-0}" != 1 ] && command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f "$FONT_DIR"
fi
