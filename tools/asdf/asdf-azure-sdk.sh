#!/bin/bash
# Azure CLI, latest
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add azure-cli https://github.com/EcoMind/asdf-azure-cli
asdf_install_global azure-cli
# Extras: az extensions are added by hand
