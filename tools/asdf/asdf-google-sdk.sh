#!/bin/bash

asdf plugin add gcloud https://github.com/jthegedus/asdf-gcloud
asdf install gcloud latest
asdf set gcloud latest --home

# Extras
# gcloud components install 