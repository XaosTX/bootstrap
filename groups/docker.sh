#!/bin/sh
# groups/docker.sh — Docker CE via official apt repo + docker group membership
# get.docker.com misdetects Mint as Debian, so we add the repo manually.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

if command -v docker >/dev/null 2>&1; then
  log_success "Docker already installed: $(docker --version)"
else
  case "$PKG_MGR" in
    apt)
      # Clean up stale get.docker.com artifacts (it misdetects Mint as Debian).
      # Safe: we only reach here when docker is NOT installed.
      # shellcheck disable=SC2086
      $SUDO rm -f /etc/apt/sources.list.d/docker.list \
                   /etc/apt/keyrings/docker.asc 2>/dev/null || true

      # Resolve the upstream distro Docker actually publishes for.
      # Mint → ubuntu; straight Ubuntu/Debian use themselves.
      # shellcheck disable=SC1091
      docker_codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
      # shellcheck disable=SC1091
      docker_distro=$(. /etc/os-release && echo "${ID}")
      case "$docker_distro" in
        linuxmint|pop) docker_distro=ubuntu ;;
        ubuntu|debian) ;;                        # already correct
        *)             docker_distro=debian ;;   # safe fallback
      esac
      docker_arch=$(dpkg --print-architecture)

      apt_add_repo docker \
        "https://download.docker.com/linux/$docker_distro/gpg" \
        "deb [arch=$docker_arch signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$docker_distro $docker_codename stable"

      pkg_install docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
      ;;
    dnf)
      # Fedora / RHEL family — use the convenience script
      run sh -c 'curl -fsSL https://get.docker.com | sh'
      ;;
    pacman)
      pkg_install docker docker-compose
      # shellcheck disable=SC2086
      run $SUDO systemctl enable --now docker.service
      ;;
    brew)
      # Docker Desktop (cask) — the engine runs in its VM
      run brew install --cask docker
      ;;
    *)
      log_error "docker: no installer for PKG_MGR=$PKG_MGR"
      exit 1
      ;;
  esac

  # Ensure docker group exists and add current user
  if ! getent group docker >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    run $SUDO groupadd docker
  fi
  # shellcheck disable=SC2086
  run $SUDO usermod -aG docker "$(id -un)"
  log_success "Docker installed — re-login required for group membership"
fi
