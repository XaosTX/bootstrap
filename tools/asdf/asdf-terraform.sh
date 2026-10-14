#!/bin/bash
# HashiCorp terraform, latest
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add terraform https://github.com/asdf-community/asdf-hashicorp.git
asdf_install_global terraform
