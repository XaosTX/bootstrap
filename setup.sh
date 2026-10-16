#!/bin/sh
# setup.sh — THE entrypoint: detect OS → prepare → dirs → repos → menu → dispatch
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/XaosTX/bootstrap/main/setup.sh | sh
#   ./setup.sh [--quick|--min] [--headless] [--all] [--yes] [--dry-run] [--help]
#
#   --quick, --min   preset: base-cli shell nettools vi ("CLI QoL only")
#   --headless       hide GUI groups (servers, VMs, SSH-only boxes)
#   --all            preselect every group for this OS
#   --yes, -y        accept the preselection without showing the menu
#   --dry-run        print planned actions, install nothing
#   --help, -h       this text

set -e

BOOTSTRAP_REPO_URL="https://github.com/XaosTX/bootstrap.git"
DOTFILES_REPO_URL="https://github.com/XaosTX/dotfiles.git"
DOTFILES_DIR="$HOME/g/dotfiles"

# ──────────────────────────────────────────────
#  Resolve BOOTSTRAP_DIR — or bootstrap ourselves when piped from curl
# ──────────────────────────────────────────────
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) || SCRIPT_DIR=""
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/lib/pkg.sh" ]; then
  BOOTSTRAP_DIR=$SCRIPT_DIR
else
  # Piped from curl: no repo on disk yet. Get git, clone, re-exec the local copy.
  BOOTSTRAP_DIR="$HOME/g/bootstrap"
  if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    SUDO=""
    [ "$(id -u)" -ne 0 ] && SUDO=sudo
    if   [ "$(uname)" = Darwin ]; then
      echo "git comes with the Xcode command line tools. Finish the install dialog, then re-run."
      xcode-select --install || true
      exit 1
    elif command -v apt-get >/dev/null 2>&1; then $SUDO apt-get update -y && $SUDO apt-get install -y git
    elif command -v dnf     >/dev/null 2>&1; then $SUDO dnf install -y git
    elif command -v apk     >/dev/null 2>&1; then $SUDO apk add git
    elif command -v pacman  >/dev/null 2>&1; then $SUDO pacman -Sy --noconfirm git
    else echo "No known package manager found to install git" >&2; exit 1
    fi
  fi
  mkdir -p "$(dirname "$BOOTSTRAP_DIR")"
  if [ -d "$BOOTSTRAP_DIR/.git" ]; then
    git -C "$BOOTSTRAP_DIR" pull --ff-only || true
  else
    git clone "$BOOTSTRAP_REPO_URL" "$BOOTSTRAP_DIR"
  fi
  exec sh "$BOOTSTRAP_DIR/setup.sh" "$@"
fi

# ──────────────────────────────────────────────
#  Flags
# ──────────────────────────────────────────────
PRESET=""
HEADLESS=0
ASSUME_YES=0
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --quick|--min) PRESET=quick ;;
    --headless)    HEADLESS=1; [ -z "$PRESET" ] && PRESET=quick ;;
    --all)         PRESET=all ;;
    --yes|-y)      ASSUME_YES=1 ;;
    --dry-run)     DRY_RUN=1 ;;
    -h|--help)     sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown flag: $1 (try --help)" >&2; exit 1 ;;
  esac
  shift
done
export BOOTSTRAP_DIR DRY_RUN HEADLESS ASSUME_YES DOTFILES_DIR DOTFILES_REPO_URL

# ──────────────────────────────────────────────
#  Libs + profile (the OS decides which profile and which groups)
# ──────────────────────────────────────────────
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/os.sh"
. "$BOOTSTRAP_DIR/lib/dirs.sh"
. "$BOOTSTRAP_DIR/lib/menu.sh"

PROFILE=$(detect_distro)
if [ "$PROFILE" = unknown ]; then
  log_error "Could not detect a supported OS"
  exit 1
fi
PKG_MGR=$(detect_pkg_mgr "$PROFILE")
export PROFILE PKG_MGR

if [ ! -f "$BOOTSTRAP_DIR/profiles/$PROFILE.sh" ]; then
  log_error "No profile for '$PROFILE' yet — see docs/design.md for the roadmap"
  exit 1
fi
# shellcheck disable=SC1090
. "$BOOTSTRAP_DIR/profiles/$PROFILE.sh"
export PROFILE_HAS_SNAP="${PROFILE_HAS_SNAP:-0}"

. "$BOOTSTRAP_DIR/lib/pkg.sh"

log_header "Bootstrap — profile: $PROFILE ($PKG_MGR)"
[ "$DRY_RUN" = 1 ] && log_arrow "DRY RUN — nothing will be installed"

if [ "$(id -u)" -ne 0 ] && [ -z "$SUDO" ] && [ "$PROFILE" != macos ]; then
  log_error "Not root and no sudo available — install sudo (or run as root) first"
  exit 1
fi

# macOS: Xcode CLT + Homebrew must exist before any package step
if type profile_prepare >/dev/null 2>&1; then
  log_header "Prepare"
  profile_prepare
fi

# ──────────────────────────────────────────────
#  Dirs + repos (directories first; repos are clones, not mkdirs)
# ──────────────────────────────────────────────
log_header "Directories"
create_dirs

log_header "Package index"
pkg_update

pkg_install git curl

log_header "Repos"
ensure_repo "$BOOTSTRAP_DIR" "$BOOTSTRAP_REPO_URL"
ensure_repo "$DOTFILES_DIR" "$DOTFILES_REPO_URL"

# ──────────────────────────────────────────────
#  Categories, groups, presets, menus
# ──────────────────────────────────────────────
# Categories are the first menu. Groups inside each are alphabetical; "dotfiles" sorts first
# in setup, so it runs before anything that depends on its links. The OS picks the categories.
CATEGORIES="setup editors cli languages infra ai apps"
case "$PROFILE" in macos) CATEGORIES="setup editors cli languages infra ai mac" ;; esac

category_groups() {
  case "$1" in
    setup)     echo "dotfiles fonts fzf shell zsh-framework" ;;
    editors)   echo "eclipse editors vi vim-plugins" ;;
    cli)       echo "base-cli git-tools nettools ssh ssh-dropbox" ;;
    languages) echo "asdf npm python" ;;
    infra)     echo "chefdk docker homelab" ;;
    ai)        echo "llm" ;;
    apps)      echo "browsers desktop" ;;
    mac)       echo "brew-core brew-extras iterm2 macos-apps macos-defaults rosetta" ;;
  esac
}

# A group that needs another one; the other one is added to the selection with a note.
group_requires() {
  case "$1" in
    npm)         echo "asdf" ;;
    vim-plugins) echo "vi" ;;
    brew-extras) echo "brew-core" ;;
    *)           echo "" ;;
  esac
}

GUI_GROUPS="editors fonts browsers desktop brew-extras iterm2 macos-apps macos-defaults"

# drop_words <words> <excluded>: keep the words of $1 that are not in $2
# (a function, not an inline case: bash 3.2, the macOS /bin/sh, mis-parses case inside $(...))
drop_words() {
  dw_out=""
  for dw_x in $1; do
    dw_skip=0
    for dw_y in $2; do [ "$dw_x" = "$dw_y" ] && dw_skip=1; done
    [ "$dw_skip" = 0 ] && dw_out="$dw_out$dw_x "
  done
  echo "$dw_out"
}

AVAILABLE_GROUPS=""
for c in $CATEGORIES; do AVAILABLE_GROUPS="$AVAILABLE_GROUPS$(category_groups "$c") "; done
# the OS list: groups that belong to another OS only are dropped
case "$PROFILE" in
  macos) OS_ONLY_OUT="eclipse editors browsers desktop homelab chefdk" ;;
  *)     OS_ONLY_OUT="brew-core brew-extras iterm2 macos-apps macos-defaults rosetta" ;;
esac
AVAILABLE_GROUPS=$(drop_words "$AVAILABLE_GROUPS" "$OS_ONLY_OUT")
if [ "$HEADLESS" = 1 ]; then
  AVAILABLE_GROUPS=$(drop_words "$AVAILABLE_GROUPS" "$GUI_GROUPS")
fi
QUICK_GROUPS="base-cli shell nettools vi"

# Item-level sub-options (tier 2). Groups not listed install unconditionally.
# For nettools/python the items are optional add-ons; for the rest the items ARE the group.
group_items_only() {
  case "$1" in
    vi|git-tools|llm|browsers|desktop|homelab|fonts|zsh-framework|brew-extras|macos-defaults|macos-apps|ssh-dropbox|chefdk|eclipse) return 0 ;;
    *) return 1 ;;
  esac
}
group_items() {
  case "$1" in
    asdf)           echo "node terraform helm stern consul vault azure gcloud pnpm java rust" ;;
    nettools)       echo "tailscale" ;;
    vi)             echo "vim nvim" ;;
    python)         echo "via-asdf" ;;
    git-tools)      echo "gh glab lazygit" ;;
    llm)            echo "claude gemini caveman" ;;
    browsers)       echo "chrome brave firefox" ;;
    desktop)        echo "postman keepassxc wireshark" ;;
    homelab)        echo "mdns discovery nas-smb nas-nfs" ;;
    fonts)          echo "jetbrains sauce inconsolata" ;;
    zsh-framework)  echo "oh-my-zsh prezto powerline" ;;
    brew-extras)    echo "browsers networking archiving-media llm virtualization visualization-graphs-diagrams python-dev security vscode-fonts gits" ;;
    macos-defaults) echo "dock dock-clear-apps" ;;
    macos-apps)     echo "divvy rdp wireguard flycut focus" ;;
    ssh-dropbox)    echo "decrypt-keys" ;;
    chefdk)         echo "chefdk" ;;
    eclipse)        echo "eclipse eclim" ;;
    *)              echo "" ;;
  esac
}
group_default_items() {
  case "$1" in
    asdf)           echo "node terraform helm" ;;
    vi)             echo "vim" ;;
    git-tools)      echo "gh" ;;
    llm)            echo "claude caveman" ;;
    browsers)       echo "brave firefox" ;;
    desktop)        echo "keepassxc" ;;
    homelab)        echo "mdns nas-smb" ;;
    fonts)          echo "jetbrains" ;;
    brew-extras)    echo "browsers networking vscode-fonts gits" ;;
    macos-defaults) echo "dock" ;;
    *)              echo "" ;;
  esac
}

# keep only words of $1 that appear in $2
filter_to() {
  ft_out=""
  for ft_x in $1; do
    case " $2 " in *" $ft_x "*) ft_out="$ft_out$ft_x " ;; esac
  done
  echo "$ft_out"
}

CACHE_FILE="$BOOTSTRAP_DIR/.selected"
case "$PRESET" in
  quick) PRESELECT=$QUICK_GROUPS ;;
  all)   PRESELECT=$AVAILABLE_GROUPS ;;
  *)
    if [ -f "$CACHE_FILE" ]; then
      PRESELECT=$(sed -n 's/^groups=//p' "$CACHE_FILE")
    else
      PRESELECT="$QUICK_GROUPS dotfiles"
    fi ;;
esac
PRESELECT=$(filter_to "$PRESELECT" "$AVAILABLE_GROUPS")

# categories with at least one group on this machine
USABLE_CATS=""
for c in $CATEGORIES; do
  cg=$(filter_to "$(category_groups "$c")" "$AVAILABLE_GROUPS")
  [ -n "$cg" ] && USABLE_CATS="$USABLE_CATS$c "
done

if [ "$ASSUME_YES" = 1 ]; then
  SELECTED=$PRESELECT
else
  # a category is on by default when one of its groups is preselected
  cat_pre=""
  for c in $USABLE_CATS; do
    cp=$(filter_to "$(category_groups "$c")" "$PRESELECT")
    [ -n "$cp" ] && cat_pre="$cat_pre$c "
  done
  prompt_menu "Categories — pick what to set up (numbers toggle, ENTER to confirm)" "$USABLE_CATS" "$cat_pre"
  CHOSEN_CATS=$prompt_selections

  SELECTED=""
  for c in $CATEGORIES; do
    case " $CHOSEN_CATS " in *" $c "*) ;; *) continue ;; esac
    cg=$(filter_to "$(category_groups "$c")" "$AVAILABLE_GROUPS")
    cp=$(filter_to "$cg" "$PRESELECT")
    prompt_menu "$c — pick groups (numbers toggle, ENTER to confirm)" "$cg" "$cp"
    SELECTED="$SELECTED$prompt_selections "
  done
fi

# add what the selected groups need, then run them in category order
for g in $SELECTED; do
  for r in $(group_requires "$g"); do
    case " $SELECTED " in *" $r "*) ;; *)
      log_arrow "$g needs $r — adding it"
      SELECTED="$SELECTED$r "
    ;; esac
  done
done
ORDERED=""
for c in $CATEGORIES; do
  for g in $(category_groups "$c"); do
    case " $SELECTED " in *" $g "*)
      case " $ORDERED " in *" $g "*) ;; *) ORDERED="$ORDERED$g " ;; esac ;;
    esac
  done
done
SELECTED=$(filter_to "$ORDERED" "$AVAILABLE_GROUPS")

# Tier 2: item picks for selected groups that have them
for g in $SELECTED; do
  g_items=$(group_items "$g")
  [ -z "$g_items" ] && continue
  g_key=$(echo "$g" | tr '-' '_')
  g_pre=$(sed -n "s/^items_$g=//p" "$CACHE_FILE" 2>/dev/null || true)
  [ -z "$g_pre" ] && g_pre=$(group_default_items "$g")
  g_pre=$(filter_to "$g_pre" "$g_items")
  if [ "$ASSUME_YES" = 1 ]; then
    g_sel=$g_pre
  else
    prompt_menu "$g — pick items (numbers toggle, ENTER to confirm)" "$g_items" "$g_pre"
    # shellcheck disable=SC2034  # read back via eval below
    g_sel=$prompt_selections
  fi
  eval "items_$g_key=\$g_sel"
done

# Remember the full selection for next run
if [ "$DRY_RUN" != 1 ]; then
  {
    echo "groups=$SELECTED"
    for g in $SELECTED; do
      [ -z "$(group_items "$g")" ] && continue
      g_key=$(echo "$g" | tr '-' '_')
      eval "echo \"items_$g=\$items_$g_key\""
    done
  } >"$CACHE_FILE"
fi

# Shell profiles: report any a group changed (third-party installers edit them unless told not to)
PROFILE_FILES="$HOME/.zshrc $HOME/.zprofile $HOME/.zshenv $HOME/.zlogin $HOME/.bashrc $HOME/.bash_profile $HOME/.profile"
snapshot_profiles() {
  for pf in $PROFILE_FILES; do
    [ -e "$pf" ] && cksum "$pf" 2>/dev/null | awk -v f="$pf" '{print f, $1}'
  done
}
PROFILE_BEFORE=$(snapshot_profiles)

# ──────────────────────────────────────────────
#  Dispatch
# ──────────────────────────────────────────────
[ -z "$SELECTED" ] && log_arrow "Nothing selected — nothing to do"

for g in $SELECTED; do
  log_header "━━ group: $g ━━"
  g_key=$(echo "$g" | tr '-' '_')
  eval "g_items_sel=\${items_$g_key:-}"
  if group_items_only "$g" && [ -z "$g_items_sel" ]; then
    log_arrow "no items selected — skipping"
    continue
  fi
  ITEMS="$g_items_sel" sh "$BOOTSTRAP_DIR/groups/$g.sh" || log_error "group $g reported errors"
done

PROFILE_AFTER=$(snapshot_profiles)
if [ "$PROFILE_BEFORE" != "$PROFILE_AFTER" ]; then
  log_error "shell profile files changed during this run — review them (git diff for symlinked ones):"
  for pf in $PROFILE_FILES; do
    case "$PROFILE_BEFORE" in *"$pf "*) b=$(echo "$PROFILE_BEFORE" | grep "^$pf " | cut -d' ' -f2) ;; *) b="" ;; esac
    a=$(echo "$PROFILE_AFTER" | grep "^$pf " | cut -d' ' -f2)
    [ "$a" != "$b" ] && log_arrow "$pf"
  done
fi

# End of run: the dotfiles once more, non-interactive, so configs for apps and commands
# that this run installed get linked. The start-of-run pass ran before they existed.
case " $SELECTED " in
  *" dotfiles "*)
    if [ -f "$DOTFILES_DIR/install.sh" ]; then
      log_header "Dotfiles — links for everything installed in this run"
      if [ "$DRY_RUN" = 1 ]; then
        bash "$DOTFILES_DIR/install.sh" --dry-run --yes
      else
        bash "$DOTFILES_DIR/install.sh" --yes || log_error "dotfiles (end of run) reported warnings"
      fi
    fi ;;
esac

# ──────────────────────────────────────────────
#  Done
# ──────────────────────────────────────────────
log_header "✅ Bootstrap complete ($PROFILE)"
log_arrow "Manual steps: $BOOTSTRAP_DIR/docs/mac-manual-steps.md"
log_arrow "You may need to log out and back in for shell/group changes."
log_header "Siiiick! You're ready to go! (•̀ᴗ•́)و"
