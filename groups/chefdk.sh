#!/bin/sh
# groups/chefdk.sh — Chef DK + knife-ec2/knife-solo (Ubuntu). OFF by default.
# Chef DK is end-of-life, and the install pipes a remote script into sudo bash. Only pick it on purpose.
# ITEMS: chefdk
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

if [ "$(uname)" = Darwin ] || ! grep -qi '^ID=ubuntu' /etc/os-release 2>/dev/null; then
  log_arrow "chefdk: Ubuntu only — skipping"
  exit 0
fi

if ! command -v chef >/dev/null 2>&1; then
  run sh -c 'curl -fsSL https://omnitruck.chef.io/install.sh | sudo bash -s -- -c current -P chefdk'
fi
if command -v chef >/dev/null 2>&1; then
  run chef gem install knife-ec2 knife-solo
fi
