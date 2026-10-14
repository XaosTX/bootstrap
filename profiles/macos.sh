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

  # Corporate TLS proxies (Zscaler and similar) re-sign HTTPS with a root from the keychain.
  # Build one bundle of keychain + system roots and point the tools in this run at it, before
  # the Homebrew installer and brew bundle fetch anything. The dotfiles reuse the same file.
  profile_ca_bundle

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

# CA bundle: every certificate in the keychains plus the system roots, at a fixed path the
# dotfiles read (shell/os/darwin/proxy.zsh). Rebuilt on each run, so it follows keychain changes.
PROFILE_CA_BUNDLE="$HOME/.config/certs/macos-ca-bundle.pem"

profile_ca_bundle() {
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] write $PROFILE_CA_BUNDLE from the keychains"
    return 0
  fi
  mkdir -p "$(dirname "$PROFILE_CA_BUNDLE")"
  if { security find-certificate -a -p
       security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain
     } > "$PROFILE_CA_BUNDLE.tmp" 2>/dev/null && [ -s "$PROFILE_CA_BUNDLE.tmp" ]; then
    mv "$PROFILE_CA_BUNDLE.tmp" "$PROFILE_CA_BUNDLE"
    log_success "CA bundle: $PROFILE_CA_BUNDLE ($(grep -c 'BEGIN CERTIFICATE' "$PROFILE_CA_BUNDLE") certs)"
  else
    rm -f "$PROFILE_CA_BUNDLE.tmp"
    log_arrow "could not read the keychains — continuing without a CA bundle"
    return 0
  fi
  # Used for the rest of this run; child processes inherit them
  export CURL_CA_BUNDLE="$PROFILE_CA_BUNDLE" SSL_CERT_FILE="$PROFILE_CA_BUNDLE"
  export NODE_EXTRA_CA_CERTS="$PROFILE_CA_BUNDLE" REQUESTS_CA_BUNDLE="$PROFILE_CA_BUNDLE"
  export AWS_CA_BUNDLE="$PROFILE_CA_BUNDLE"
}

