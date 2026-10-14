#!/bin/sh
# groups/ssh.sh — SSH keys + push to GitHub/GitLab (wires existing tools/ssh/)
# TODO(design §7.4): generate Work/Life identities to match dotfiles' includeIf
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

if [ "${DRY_RUN:-0}" = 1 ]; then
  log_arrow "[dry-run] tools/ssh/generate-ssh-keys.sh (interactive)"
elif [ -r /dev/tty ]; then
  sh "$BOOTSTRAP_DIR/tools/ssh/generate-ssh-keys.sh" </dev/tty
else
  log_arrow "No TTY — skipping interactive SSH key generation; run tools/ssh/generate-ssh-keys.sh later"
fi
