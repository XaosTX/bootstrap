#!/bin/bash
asdf plugin-add azure-cli https://github.com/EcoMind/asdf-azure-cli
asdf install azure-cli latest
asdf global azure-cli latest

# Extras
# gcloud components install