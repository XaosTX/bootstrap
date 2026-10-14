#!/bin/sh
# lib/os.sh — distro + package-manager detection

# Prints the profile name: ubuntu|debian|mint|fedora|rhel|alpine|arch|omarchy|macos|unknown
detect_distro() {
  if [ "$(uname)" = Darwin ]; then echo macos; return; fi
  if [ -e /etc/alpine-release ]; then echo alpine; return; fi
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    dist_id=$(. /etc/os-release && echo "$ID")
    case "$dist_id" in
      linuxmint) echo mint; return ;;
      ubuntu)    echo ubuntu; return ;;
      debian)    echo debian; return ;;
      fedora)    echo fedora; return ;;
      rhel|centos|rocky|almalinux) echo rhel; return ;;
      arch)
        if [ -d "$HOME/.local/share/omarchy" ]; then echo omarchy; else echo arch; fi
        return ;;
    esac
    # Unrecognized derivative — fall back to its parent family
    # shellcheck disable=SC1091
    dist_like=$(. /etc/os-release && echo "${ID_LIKE:-}")
    case " $dist_like " in
      *ubuntu*)          echo ubuntu; return ;;
      *debian*)          echo debian; return ;;
      *rhel*|*fedora*)   echo rhel; return ;;
      *arch*)            echo arch; return ;;
    esac
  fi
  echo unknown
}

# Prints the package manager for a profile name
detect_pkg_mgr() {
  case "$1" in
    ubuntu|debian|mint) echo apt ;;
    fedora|rhel)        echo dnf ;;
    alpine)             echo apk ;;
    arch|omarchy)       echo pacman ;;
    macos)              echo brew ;;
    *)
      for m in apt-get dnf apk pacman brew; do
        if command -v "$m" >/dev/null 2>&1; then
          [ "$m" = apt-get ] && m=apt
          echo "$m"
          return
        fi
      done
      echo unknown ;;
  esac
}
