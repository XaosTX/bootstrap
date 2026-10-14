#!/bin/sh
# lib/dirs.sh — personal directory layout + clone-or-pull repos
# Work repos live under ~/ws, personal and life repos under ~/g.

# ~/ws and ~/g — created idempotently
create_dirs() {
  for d in "$HOME/ws" "$HOME/g"; do
    if [ -d "$d" ]; then
      log_success "$d already exists"
    else
      run mkdir -p "$d"
      log_success "Created $d"
    fi
  done
}

# ensure_repo <path> <url> — clone if missing, pull if present; never mkdir
ensure_repo() {
  er_path=$1
  er_url=$2
  if [ -d "$er_path/.git" ]; then
    if run git -C "$er_path" pull --ff-only; then
      log_success "$er_path updated"
    else
      log_error "$er_path could not fast-forward (dirty or diverged) — leaving as-is"
    fi
  elif [ -e "$er_path" ]; then
    log_error "$er_path exists but is not a git repo — skipping"
  else
    run git clone "$er_url" "$er_path"
    log_success "$er_path cloned"
  fi
}
