#!/bin/sh
# groups/zsh-framework.sh — optional zsh frameworks. zinit is the dotfiles default and needs nothing here.
# ITEMS: oh-my-zsh prezto powerline
#   oh-my-zsh  pinned clone to ~/.oh-my-zsh + powerlevel9k theme (dotfiles zsh-plugins=oh-my-zsh)
#   prezto     pinned clone to ~/.zprezto (dotfiles zsh-plugins=prezto, prompt=prezto)
#   powerline  pip powerline-status (dotfiles tmux variant codeangler)
# Pins are updated on purpose: change these lines when you want a newer commit.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"

OMZ_COMMIT=964ddf789b022b6958b27d02d7fa54f552de21e9      # ohmyzsh/ohmyzsh master, 2026-10-14
P9K_COMMIT=66d53c02476c6207f65b0d22910242abc68935e3      # Powerlevel9k/powerlevel9k master, 2026-10-14 (archived upstream)
PREZTO_COMMIT=cff2d01871425b1b80710f8ec6a475c5a53145b4   # sorin-ionescu/prezto master, 2026-10-14

if has_item oh-my-zsh; then
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_header "Installing oh-my-zsh (pinned)"
    run git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
    run git -C "$HOME/.oh-my-zsh" checkout -q "$OMZ_COMMIT"
  else
    log_success "oh-my-zsh already installed"
  fi
  P9K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel9k"
  if [ -d "$HOME/.oh-my-zsh" ] && [ ! -d "$P9K_DIR" ]; then
    log_header "Installing powerlevel9k (pinned)"
    run git clone https://github.com/Powerlevel9k/powerlevel9k.git "$P9K_DIR"
    run git -C "$P9K_DIR" checkout -q "$P9K_COMMIT"
  fi
fi

if has_item prezto; then
  if [ ! -d "$HOME/.zprezto" ]; then
    log_header "Installing prezto (pinned)"
    run git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto"
    run git -C "$HOME/.zprezto" checkout -q "$PREZTO_COMMIT"
    run git -C "$HOME/.zprezto" submodule update --init --recursive -q
  else
    log_success "prezto already installed"
  fi
fi

if has_item powerline; then
  if command -v pip3 >/dev/null 2>&1; then
    run pip3 install --user powerline-status
  else
    log_arrow "pip3 not found — powerline not installed"
  fi
fi
