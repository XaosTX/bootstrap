# nodejs (latest LTS) + npm supply-chain hardening
#
# Pinned to asdf v0.14.0 (bash release — see groups/asdf.sh), which has no
# `asdf <plugin> <command>` dispatch for plugin-defined subcommands, so the
# LTS resolver is invoked directly from the plugin's own command script.
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git 2>/dev/null || true
ASDF_DIR="${ASDF_DIR:-$HOME/.asdf}"
NODE_LTS_VERSION=$(bash "$ASDF_DIR/plugins/nodejs/lib/commands/command-resolve" lts --latest-available)
asdf install nodejs "$NODE_LTS_VERSION"

# `asdf global` was removed in asdf 0.16+ in favour of `asdf set -u`.
# Support both so this works on 0.14 (pinned) and 0.20+ (installed by hand).
if asdf global nodejs "$NODE_LTS_VERSION" 2>/dev/null; then
  :
else
  asdf set -u nodejs "$NODE_LTS_VERSION" 2>/dev/null \
    || printf 'nodejs %s\n' "$NODE_LTS_VERSION" > "$HOME/.tool-versions"
fi

# --- supply-chain hardening ------------------------------------------------
# See docs/npm-hardening.md. Applied here because a fresh node install ships
# an npm that predates the cooldown key, and because asdf's per-version global
# npmrc does NOT carry across node versions.
sh "$(dirname "$0")/../npm/harden.sh" || true
