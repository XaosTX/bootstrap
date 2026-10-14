# Optional: Dock settings from codeangler's bootstrap (macos/setting-preferences.sh). Changes the Dock on this Mac.
defaults write com.apple.dock orientation left
defaults write com.apple.dock tilesize -integer 40
defaults write com.apple.dock autohide-time-modifier -float 1
killall Dock 2>/dev/null || true
