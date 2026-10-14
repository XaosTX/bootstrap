# Core packages from brew/Brewfile (apps and tools the dotfiles expect).
e_header "Installing core Homebrew packages"
brew bundle --file="$BOOT_ROOT/brew/Brewfile"
