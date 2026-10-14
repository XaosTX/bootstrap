#!/bin/bash

# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add to your shell config
echo 'source "$HOME/.cargo/env"' >> ~/.zshrc  # or ~/.bash_profile if using bash
source ~/.zshrc  # or restart your terminal

# Verify installation
rustc --version
cargo --version