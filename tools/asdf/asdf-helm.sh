#!/bin/bash
# Helm, latest (stern has its own item: asdf-k8s.sh)
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add helm
asdf_install_global helm
