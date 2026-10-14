#!/bin/bash
# vault, latest
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add vault
asdf_install_global vault
