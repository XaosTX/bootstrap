#!/bin/bash
# Google Cloud SDK (gcloud), latest
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add gcloud https://github.com/jthegedus/asdf-gcloud
asdf_install_global gcloud
# Extras: gcloud components install (by hand)
