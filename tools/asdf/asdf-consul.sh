#!/bin/bash
# consul, latest
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add consul
asdf_install_global consul
