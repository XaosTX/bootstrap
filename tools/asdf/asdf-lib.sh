#!/bin/bash
# tools/asdf/asdf-lib.sh — helpers for the plugin scripts. Sourced, not run.
# Works on the pinned asdf v0.14 (git clone, `asdf global`) and on asdf 0.16+ (`asdf set -u`).

# Make `asdf` callable in this shell: the plugin scripts run in their own process.
asdf_setup() {
  if ! command -v asdf >/dev/null 2>&1; then
    ASDF_DIR="${ASDF_DIR:-$HOME/.asdf}"
    # shellcheck disable=SC1091
    [ -f "$ASDF_DIR/asdf.sh" ] && . "$ASDF_DIR/asdf.sh"
  fi
  if ! command -v asdf >/dev/null 2>&1; then
    echo "asdf is not installed — run the asdf group first" >&2
    exit 1
  fi
}

# asdf_add <plugin> [url]: add the plugin unless it is already there
asdf_add() {
  asdf plugin list 2>/dev/null | grep -qx "$1" || asdf plugin add "$@"
}

# asdf_install_global <plugin> [version-prefix]: newest matching version, installed and set as the default
asdf_install_global() {
  aig_plugin=$1
  aig_prefix=${2:-}
  if [ -n "$aig_prefix" ]; then
    aig_ver=$(asdf latest "$aig_plugin" "$aig_prefix") || aig_ver=""
  else
    aig_ver=$(asdf latest "$aig_plugin") || aig_ver=""
  fi
  if [ -z "$aig_ver" ]; then
    echo "no version found for $aig_plugin ${aig_prefix}" >&2
    return 1
  fi
  asdf install "$aig_plugin" "$aig_ver"
  asdf_set_default "$aig_plugin" "$aig_ver"
  echo "✔ $aig_plugin $aig_ver"
}

# asdf_set_default <plugin> <version>: make it the default. Picks the command the installed asdf has,
# and keeps its usage text off the terminal.
asdf_set_default() {
  if asdf set --help >/dev/null 2>&1; then
    asdf set -u "$1" "$2" >/dev/null
  else
    asdf global "$1" "$2" >/dev/null
  fi
}
