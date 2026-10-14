#!/bin/bash
# nodejs, latest LTS, then the npm supply-chain hardening (docs/npm-hardening.md)
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add nodejs https://github.com/asdf-vm/asdf-nodejs.git

# The plugin's own resolver knows which release is LTS. If it is missing, fall back to the newest.
resolver="${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/nodejs/lib/commands/command-resolve"
if [ ! -f "$resolver" ]; then
  asdf_install_global nodejs
  exit $?
fi
NODE_LTS_VERSION=$(bash "$resolver" lts --latest-available) || exit 1
if [ -z "$NODE_LTS_VERSION" ]; then
  echo "could not resolve the nodejs LTS version" >&2
  exit 1
fi
asdf install nodejs "$NODE_LTS_VERSION"
asdf_set_default nodejs "$NODE_LTS_VERSION"
echo "✔ nodejs $NODE_LTS_VERSION"

# A fresh node install ships an npm that predates the cooldown key, and asdf's
# per-version global npmrc does not carry across node versions, so harden here too.
sh "$(dirname "$0")/../npm/harden.sh" || true
