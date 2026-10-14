# Homebrew: install with the official installer if missing, then update. Packages are in brew/Brewfile.
if ! command -v brew >/dev/null 2>&1; then
  e_header "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # load brew for this session (the installer only prints the PATH setup)
  for p in /opt/homebrew /usr/local; do
    if [ -x "$p/bin/brew" ]; then eval "$("$p/bin/brew" shellenv)"; break; fi
  done
fi
if ! command -v brew >/dev/null 2>&1; then e_error "Homebrew failed to install."; return 1; fi
e_header "Updating Homebrew"
brew update
