#!/usr/bin/env bash
# xaostx bootstrap: gets the dotfiles repo, runs its setup, then this machine's install steps.
#
# Usage: bootstrap.sh [bootstrap options] [dotfiles options]
#   --dotfiles-dir DIR    the dotfiles checkout (default: $HOME/g/dotfiles)
#   --dotfiles-repo URL   repo to clone when DIR is missing (default: github.com/XaosTX/dotfiles)
#   --no-clone            use DIR as it is; do not clone or pull
#   --skip-dotfiles       run only the install steps
#   --install             also run steps/common and steps/<this OS>
#   --optional            also run steps/optional (asks per step when interactive; --yes runs them all). Implies --install.
#   anything else         passed to the dotfiles install.sh (--yes, --dry-run, --choose, --profiles, --home ...)

BOOT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export BOOT_ROOT
DOT_DIR="${DOTFILES_DIR:-$HOME/g/dotfiles}"
DOT_REPO="https://github.com/XaosTX/dotfiles.git"
DO_CLONE=1; SKIP_DOTFILES=; INSTALL=; OPTIONAL=; DRY=; ASSUME_YES=; PASS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dotfiles-dir) DOT_DIR="$2"; shift;;
    --dotfiles-repo) DOT_REPO="$2"; shift;;
    --no-clone) DO_CLONE=;;
    --skip-dotfiles) SKIP_DOTFILES=1;;
    --install) INSTALL=1;;
    --optional) INSTALL=1; OPTIONAL=1;;
    --dry-run) DRY=1; PASS+=("$1");;
    --yes|-y) ASSUME_YES=1; PASS+=("$1");;
    --choose|--profiles|--home) PASS+=("$1" "$2"); shift;;
    *) PASS+=("$1");;
  esac
  shift
done

df_os() {
  case "$(uname -s)" in
    Darwin) echo darwin;;
    Linux) echo linux;;
    *) echo other;;
  esac
}

# 1. the dotfiles repo
if [ -z "$SKIP_DOTFILES" ] && [ -n "$DO_CLONE" ]; then
  if [ -d "$DOT_DIR/.git" ]; then
    git -C "$DOT_DIR" pull --ff-only origin main || { echo "could not update $DOT_DIR" >&2; exit 2; }
  elif [ -e "$DOT_DIR" ]; then
    echo "$DOT_DIR exists but is not a git checkout" >&2; exit 2
  else
    git clone "$DOT_REPO" "$DOT_DIR" || exit 2
  fi
fi
if [ ! -f "$DOT_DIR/install.sh" ]; then echo "no dotfiles checkout at $DOT_DIR" >&2; exit 2; fi
export DF_ROOT="$DOT_DIR" DOTFILES="$DOT_DIR"

# 2. the dotfiles setup. Warnings from it stop the run, as they do there.
if [ -z "$SKIP_DOTFILES" ]; then
  "$DOT_DIR/install.sh" "${PASS[@]}" || { echo "dotfiles setup did not finish cleanly; install steps not run" >&2; exit 1; }
fi

# 3. install steps (not in the dotfiles repo)
if [ -z "$INSTALL" ]; then exit 0; fi
source "$DOT_DIR/lib/common.sh"
install_type=1
FAILED=0

run_steps() {  # run_steps DIR [ask|all]: DIR/common/*.sh then DIR/<this OS>/*.sh
  local dir="$1" mode="${2:-all}" osel f base ans
  osel="$(df_os)"
  for f in "$dir"/common/*.sh "$dir/$osel"/*.sh; do
    [ -f "$f" ] || continue
    base="${f#$BOOT_ROOT/steps/}"
    if [ "$mode" = ask ] && [ -z "$DRY" ]; then
      read -r -p "  Run optional step $base? [y/N]: " ans
      case "$ans" in y|Y|yes|YES) ;; *) e_arrow "skipped $base"; continue;; esac
    fi
    if [ -n "$DRY" ]; then e_arrow "would run $base"; continue; fi
    e_header "$base"
    if ! ( install_type=1; DOTFILES="$DOT_DIR"; DF_ROOT="$DOT_DIR"; source "$DOT_DIR/lib/common.sh"; source "$f" ); then
      e_error "$base failed"; FAILED=$((FAILED + 1))
    fi
  done
}

run_steps "$BOOT_ROOT/steps" all
if [ -n "$OPTIONAL" ]; then
  if [ -t 0 ] && [ -t 1 ] && [ -z "$ASSUME_YES" ]; then mode=ask; else mode=all; fi
  run_steps "$BOOT_ROOT/steps/optional" "$mode"
fi

[ "$FAILED" -gt 0 ] && { e_error "$FAILED install step(s) failed"; exit 1; }
e_success "done"
exit 0
