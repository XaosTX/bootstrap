#!/bin/bash
# helm and stern, latest
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add helm
asdf_install_global helm
asdf_add stern
asdf_install_global stern
