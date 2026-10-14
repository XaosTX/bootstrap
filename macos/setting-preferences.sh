#!/bin/sh
# --------------------------------------
# TODO
# finder settings
# keyboard settings
# dock settings
# -------------------------------------

# Dock


defaults write com.apple.dock persistent-apps -array
# defaults write com.apple.dock static-only -bool TRUE;

defaults write com.apple.dock orientation left;

defaults write com.apple.dock tilesize -integer 40;
defaults write com.apple.dock autohide-time-modifier -float 1;
killall Dock