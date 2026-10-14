#!/bin/bash
# stern (Kubernetes log tailing), latest
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add stern
asdf_install_global stern
