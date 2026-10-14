#!/bin/bash

# asdf plugin add gcloud https://github.com/jthegedus/asdf-gcloud
asdf plugin add pnpm
asdf install pnpm latest
asdf set pnpm latest --home

# Extras
# gcloud components install kubectl