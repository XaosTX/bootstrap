#!/bin/sh
# groups/git-tools.sh — ITEMS: gh glab lazygit
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

ITEMS="${ITEMS:-gh}"

deb_arch() { dpkg --print-architecture 2>/dev/null || echo amd64; }

if has_item gh; then
  if command -v gh >/dev/null 2>&1; then
    log_success "gh already installed"
  elif [ "$PKG_MGR" = apt ]; then
    apt_add_repo github-cli \
      "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
      "deb [arch=$(deb_arch) signed-by=/etc/apt/keyrings/github-cli.gpg] https://cli.github.com/packages stable main"
    pkg_install gh
  else
    pkg_install gh
  fi
fi

if has_item glab; then
  if command -v glab >/dev/null 2>&1; then
    log_success "glab already installed"
  elif [ "$PKG_MGR" = apt ]; then
    # not in Debian/Ubuntu apt — pull the latest .deb from GitLab releases
    pkg_install jq
    case "$(deb_arch)" in
      arm64) glab_pat='linux.*(arm64|aarch64).*\.deb$' ;;
      *)     glab_pat='linux.*(amd64|x86_64).*\.deb$' ;;
    esac
    glab_url=$(curl -fsSL "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases/permalink/latest" \
      | jq -r '.assets.links[].direct_asset_url' | grep -Ei "$glab_pat" | head -1 || true)
    if [ -n "$glab_url" ]; then
      if [ "${DRY_RUN:-0}" = 1 ]; then
        log_arrow "[dry-run] install $glab_url"
      else
        glab_tmp=$(mktemp /tmp/glab-XXXXXX.deb)
        curl -fsSL "$glab_url" -o "$glab_tmp"
        # shellcheck disable=SC2086
        $SUDO apt-get install -y "$glab_tmp"
        rm -f "$glab_tmp"
        log_success "glab installed"
      fi
    else
      log_error "Could not find a glab .deb for $(deb_arch)"
    fi
  else
    pkg_install glab
  fi
fi

if has_item lazygit; then
  if command -v lazygit >/dev/null 2>&1; then
    log_success "lazygit already installed"
  else
    # not in Ubuntu 22.04/Debian 12 apt — install the release binary to ~/.local/bin
    case "$(uname -m)" in
      aarch64|arm64) lg_arch=arm64 ;;
      *)             lg_arch=x86_64 ;;
    esac
    if [ "${DRY_RUN:-0}" = 1 ]; then
      log_arrow "[dry-run] install lazygit (latest, Linux_$lg_arch) to ~/.local/bin"
    else
      pkg_install jq
      lg_ver=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r .tag_name)
      lg_tmp=$(mktemp -d)
      curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${lg_ver}/lazygit_${lg_ver#v}_Linux_${lg_arch}.tar.gz" \
        | tar xz -C "$lg_tmp" lazygit
      mkdir -p "$HOME/.local/bin"
      install -m 755 "$lg_tmp/lazygit" "$HOME/.local/bin/lazygit"
      rm -rf "$lg_tmp"
      log_success "lazygit $lg_ver installed to ~/.local/bin"
    fi
  fi
fi
exit 0
