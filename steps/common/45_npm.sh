# npm supply-chain hardening (docs/npm-hardening.md in the dotfiles repo).
# The cooldown lives in the dotfiles' ~/.npmrc. This step only makes sure npm 12+ is installed (older npm ignores
# min-release-age silently) and writes the same settings to npm's global config, which survives node upgrades on macOS.
if ! command -v npm >/dev/null 2>&1; then e_arrow "npm not found; run the node step first"; return 0; fi
npm_major=$(npm -v 2>/dev/null | cut -d. -f1)
if [ "${npm_major:-0}" -lt 12 ]; then
  e_header "Upgrading npm to 12"
  npm install -g "npm@^12"
fi
e_success "npm $(npm -v)"
if is_osx; then
  gcfg=$(npm config get globalconfig 2>/dev/null)
  if [ -n "$gcfg" ] && [ ! -L "$gcfg" ]; then
    mkdir -p "$(dirname "$gcfg")"
    printf '# UNIT IS DAYS (min-release-age=7 is one week).\nmin-release-age=7\nmin-release-age-exclude=\naudit=true\naudit-level=moderate\n' > "$gcfg"
    e_success "global npm config: $gcfg"
  fi
fi
