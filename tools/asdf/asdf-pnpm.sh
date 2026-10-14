#!/bin/bash
# pnpm, latest
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add pnpm
asdf_install_global pnpm
