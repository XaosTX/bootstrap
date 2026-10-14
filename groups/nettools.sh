#!/bin/sh
# groups/nettools.sh — network troubleshooting kit; ITEMS may add: tailscale
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

# dig's dnsutils package also provides nslookup
pkg_install nmap ncat ipcalc dig traceroute

if has_item tailscale; then
  if command -v tailscale >/dev/null 2>&1; then
    log_success "tailscale already installed"
  else
    run sh -c 'curl -fsSL https://tailscale.com/install.sh | sh'
    log_arrow "Run 'sudo tailscale up' to authenticate this box"
  fi
fi
