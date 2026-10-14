#!/bin/sh
# groups/llm.sh — AI agents + agent skills registry (design §3.6)
# Cross-platform (macOS/Linux/WSL): skills write to ~/.claude/, no pkg-mgr fork.
# ITEMS: claude gemini caveman   (handoff pending — source not pinned yet)
# Order matters: agents install first so skills can detect and wire them.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

ITEMS="${ITEMS:-claude caveman}"

# agent installers drop binaries in ~/.local/bin — make them visible to this run
PATH="$HOME/.local/bin:$PATH"

if has_item claude; then
  if command -v claude >/dev/null 2>&1; then
    log_success "claude (Claude Code) already installed"
  else
    # native installer → ~/.local/bin, no node required
    run sh -c 'curl -fsSL https://claude.ai/install.sh | bash'
    log_success "Claude Code installed — run 'claude' to sign in"
  fi
fi

if has_item gemini; then
  if command -v gemini >/dev/null 2>&1; then
    log_success "gemini CLI already installed"
  elif command -v npm >/dev/null 2>&1; then
    # one of the curated global-npm CLIs (design §7.2 allowlist)
    run npm install -g @google/gemini-cli
    log_success "gemini CLI installed"
  else
    log_arrow "gemini CLI needs node/npm (asdf nodejs plugin) — skipping"
  fi
fi

# Prereq gate: skills layer onto agents, so at least one agent must exist
agents=""
for a in claude cursor codex gemini; do
  command -v "$a" >/dev/null 2>&1 && agents="$agents$a "
done

if has_item caveman; then
  if [ -z "$agents" ]; then
    log_arrow "No AI coding agent detected (claude/cursor/codex/gemini) — skipping caveman"
  else
    # upstream installer now requires node ≥18 even via the curl one-liner
    if ! command -v node >/dev/null 2>&1; then
      if [ "${DRY_RUN:-0}" = 1 ]; then
        log_arrow "[dry-run] would prompt to install node (latest LTS via asdf) for caveman"
      elif [ -r /dev/tty ]; then
        printf ' \033[1;34m➜\033[0m  caveman needs node >=18 — install latest LTS via asdf now? [Y/n] ' >/dev/tty
        read -r node_reply </dev/tty
        case "$node_reply" in
          [nN]*) log_arrow "Skipping node install — install it yourself, then re-run this group" ;;
          *)
            if command -v asdf >/dev/null 2>&1 || [ -d "$HOME/.asdf" ]; then
              # shellcheck disable=SC1090
              . "$HOME/.asdf/asdf.sh" 2>/dev/null || true
              run sh "$BOOTSTRAP_DIR/tools/asdf/asdf-node.sh"
              # shellcheck disable=SC1090
              . "$HOME/.asdf/asdf.sh" 2>/dev/null || true
            else
              log_arrow "asdf not installed — select the asdf group first, then re-run llm"
            fi
            ;;
        esac
      else
        log_arrow "No TTY — can't prompt; install node >=18 (asdf nodejs plugin) and re-run this group"
      fi
    fi

    if ! command -v node >/dev/null 2>&1; then
      log_arrow "caveman needs node ≥18 — install it (asdf nodejs plugin), then re-run this group"
    else
      log_arrow "Agents detected: $agents"
      # installer is idempotent; --force would reinstall, --uninstall removes
      if [ "${DRY_RUN:-0}" = 1 ]; then
        log_arrow "[dry-run] caveman installer (curl | bash)"
      else
        sh -c "curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash"
        log_success "caveman skill installed — activate with /caveman"
      fi
    fi
  fi
fi

log_arrow "handoff skill: installer source still TBD (docs/design.md §3.6) — not installed"
exit 0
