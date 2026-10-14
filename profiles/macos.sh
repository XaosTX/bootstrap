#!/bin/sh
# profiles/macos.sh — Homebrew everywhere; Xcode CLT + brew must exist before any package step
# shellcheck disable=SC2034  # consumed by setup.sh after sourcing
PKG_MGR=brew
PROFILE_HAS_SNAP=0

# Runs from setup.sh before the package index is touched.
profile_prepare() {
  # Xcode command line tools: git, make and the compilers Homebrew needs
  if ! xcode-select -p >/dev/null 2>&1; then
    log_error "Xcode command line tools are missing — starting the install dialog"
    run xcode-select --install || true
    log_error "Finish the Apple install dialog, then re-run setup.sh"
    [ "${DRY_RUN:-0}" = 1 ] || exit 1
  else
    log_success "Xcode command line tools present"
  fi

  # Some tools look for full Xcode even though they don't need it
  # https://github.com/joyent/node/issues/3681
  if [ ! -d "$(xcode-select -p 2>/dev/null)" ]; then
    run $SUDO xcode-select -switch /usr/bin
  fi

  # Homebrew: official installer if missing; Apple Silicon /opt/homebrew, Intel /usr/local
  if ! command -v brew >/dev/null 2>&1; then
    if [ "${DRY_RUN:-0}" = 1 ]; then
      log_arrow "[dry-run] install Homebrew"
    else
      log_header "Installing Homebrew"
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  fi
  for p in /opt/homebrew /usr/local; do
    if [ -x "$p/bin/brew" ]; then
      eval "$("$p/bin/brew" shellenv)"
      break
    fi
  done
  if command -v brew >/dev/null 2>&1; then
    log_success "Homebrew $(brew --version 2>/dev/null | head -1)"
  elif [ "${DRY_RUN:-0}" != 1 ]; then
    log_error "Homebrew failed to install"
    exit 1
  fi
}
