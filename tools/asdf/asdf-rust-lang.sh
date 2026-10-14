#!/bin/bash
# Rust via rustup. --no-modify-path: the dotfiles put ~/.cargo/bin on PATH, so rustup
# must not append to .zshrc, .profile or .bashrc.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
