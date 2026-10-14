#!/bin/sh
# tools/npm/harden.sh — npm supply-chain hardening (design: docs/npm-hardening.md)
#
# Applies a package cooldown so newly published (possibly trojanised) versions
# are never resolved. Written after the 2026-08 "ChainDrop"/Shai-Hulud npm worm.
#
# Idempotent. Safe to re-run. Honours DRY_RUN=1.
# Cross-platform: macOS and Debian/Ubuntu (differs only in the backup layer).
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"

# *** UNIT IS DAYS on npm 12.x. NOT minutes. ***
# 10080 ("7 x 1440") is read as 10080 DAYS = year 1998 -> every install fails
# with ENOVERSIONS. Values in the low thousands are worse: they silently
# resolve decade-old versions with known CVEs. Verified on npm 12.0.2.
COOLDOWN_DAYS=7
MIN_NPM_MAJOR=12

if ! command -v npm >/dev/null 2>&1; then
  log_arrow "npm not found — install node first (asdf nodejs), then re-run"
  exit 0
fi

# --- npm must be new enough to understand the key -------------------------
npm_major=$(npm -v 2>/dev/null | cut -d. -f1)
if [ "${npm_major:-0}" -lt "$MIN_NPM_MAJOR" ]; then
  log_arrow "npm $(npm -v) < $MIN_NPM_MAJOR — cooldown would be SILENTLY IGNORED; upgrading"
  run npm install -g "npm@^$MIN_NPM_MAJOR"
  command -v asdf >/dev/null 2>&1 && run asdf reshim nodejs 2>/dev/null || true
fi
log_success "npm $(npm -v 2>/dev/null)"

# --- user-level config (persists across node upgrades) --------------------
# ~/.npmrc is a symlink into the dotfiles repo, which already holds these
# settings. `npm config set --location=user` would write through the link and
# dirty that repo, so only touch it when it is a plain file.
if [ -L "$HOME/.npmrc" ]; then
  log_arrow "~/.npmrc is linked from dotfiles — user settings come from there"
else
for kv in "min-release-age=$COOLDOWN_DAYS" "engine-strict=true" \
          "audit=true" "audit-level=moderate" "save-exact=true" "fund=false"; do
  k=${kv%%=*}; v=${kv#*=}
  run npm config set "$k" "$v" --location=user
done
log_success "user npmrc hardened (min-release-age=${COOLDOWN_DAYS}d)"
fi

# --- backup layer ----------------------------------------------------------
# macOS/asdf: the global npmrc is per node version and is lost on upgrade.
# Debian:     /etc/npmrc is system-wide and survives node upgrades.
if [ "$(uname)" = Darwin ]; then
  gcfg=$(npm config get globalconfig 2>/dev/null)
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] write cooldown to $gcfg"
  else
    mkdir -p "$(dirname "$gcfg")" 2>/dev/null || true
    printf '# bootstrap tools/npm/harden.sh — UNIT IS DAYS, not minutes.\nmin-release-age=%s\nmin-release-age-exclude=\naudit=true\naudit-level=moderate\n' \
      "$COOLDOWN_DAYS" > "$gcfg" && log_success "global npmrc: $gcfg"
    log_arrow "asdf note: this file is per-node-version — re-run after a node upgrade"
  fi
else
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] write cooldown to /etc/npmrc (sudo)"
  elif [ -w /etc ] || command -v sudo >/dev/null 2>&1; then
    printf 'min-release-age=%s\nmin-release-age-exclude=\naudit=true\naudit-level=moderate\n' \
      "$COOLDOWN_DAYS" | sudo tee /etc/npmrc >/dev/null && log_success "/etc/npmrc (system-wide)"
  else
    log_arrow "cannot write /etc/npmrc (no sudo) — user npmrc still applies"
  fi
fi

# --- hardened package.json scaffold ---------------------------------------
if [ "${DRY_RUN:-0}" != 1 ] && [ ! -e "$HOME/.npm-init.js" ]; then
  cat > "$HOME/.npm-init.js" <<'EOF'
// scaffolds a hardened package.json on `npm init` (npm init-module config)
const path = require('path');
module.exports = {
  name: path.basename(process.cwd()),
  version: '1.0.0',
  private: true,
  // with engine-strict=true this makes an old npm REFUSE (EBADENGINE) rather
  // than silently skipping min-release-age
  engines: { node: '>=20', npm: '>=12' },
  scripts: { audit: 'npm audit --audit-level=moderate' },
  overrides: {}
};
EOF
  log_success "~/.npm-init.js scaffold installed"
fi

# --- verify ----------------------------------------------------------------
eff=$(npm config get min-release-age 2>/dev/null)
if [ "$eff" = "$COOLDOWN_DAYS" ]; then
  log_success "verified: min-release-age=$eff days"
else
  log_error "min-release-age=$eff (expected $COOLDOWN_DAYS)"
fi
exit 0
