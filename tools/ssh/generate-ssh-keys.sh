#!/bin/sh
# tools/ssh/generate-ssh-keys.sh — make and register the GitHub and GitLab SSH keys
#
#   ~/.ssh/github_rsa and ~/.ssh/gitlab_rsa   RSA 4096 (the names the dotfiles ssh config uses)
#
# Existing keys are never overwritten. Registration uses the gh / glab CLI when it is logged
# in; otherwise it calls the REST API with a token from $GH_TOKEN / $GL_TOKEN, or one you type
# in (hidden, never stored or echoed).
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"

TITLE="bootstrap-$(hostname)-$(date +%Y%m%d)"

# make_key <file-name> <comment>
make_key() {
  key="$HOME/.ssh/$1"
  if [ -f "$key" ]; then
    log_success "$key exists — keeping it"
    return 0
  fi
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  log_header "Creating $key"
  ssh-keygen -t rsa -b 4096 -C "$2" -f "$key"
}

# read_secret <prompt> <env-var-name>: value of the variable if set, else a hidden prompt
read_secret() {
  eval "rs_val=\${$2:-}"
  if [ -n "$rs_val" ]; then
    printf '%s\n' "$rs_val"
    return 0
  fi
  printf '%s: ' "$1" >&2
  stty -echo 2>/dev/null || true
  read -r rs_val </dev/tty
  stty echo 2>/dev/null || true
  printf '\n' >&2
  printf '%s\n' "$rs_val"
}

register_github() {
  pub="$HOME/.ssh/github_rsa.pub"
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh ssh-key add "$pub" --title "$TITLE" && { log_success "GitHub key added with gh"; return 0; }
    log_arrow "gh could not add it (already registered?) — trying the API"
  fi
  token=$(read_secret "GitHub token (scope: write:public_key)" GH_TOKEN)
  body=$(jq -n --arg t "$TITLE" --rawfile k "$pub" '{title:$t, key:$k}')
  if printf 'header = "Authorization: Bearer %s"\nheader = "Accept: application/vnd.github+json"\nheader = "X-GitHub-Api-Version: 2022-11-28"\n' "$token" \
      | curl -fsS -K - -X POST -H "Content-Type: application/json" -d "$body" https://api.github.com/user/keys >/dev/null; then
    log_success "GitHub key added"
  else
    log_error "GitHub key not added (token, or the key is already registered)"
  fi
}

register_gitlab() {
  pub="$HOME/.ssh/gitlab_rsa.pub"
  if command -v glab >/dev/null 2>&1 && glab auth status >/dev/null 2>&1; then
    glab ssh-key add "$pub" --title "$TITLE" && { log_success "GitLab key added with glab"; return 0; }
    log_arrow "glab could not add it (already registered?) — trying the API"
  fi
  token=$(read_secret "GitLab token (scope: api)" GL_TOKEN)
  body=$(jq -n --arg t "$TITLE" --rawfile k "$pub" '{title:$t, key:$k, usage_type:"auth"}')
  if printf 'header = "PRIVATE-TOKEN: %s"\n' "$token" \
      | curl -fsS -K - -X POST -H "Content-Type: application/json" -d "$body" https://gitlab.com/api/v4/user/keys >/dev/null; then
    log_success "GitLab key added"
  else
    log_error "GitLab key not added (token, or the key is already registered)"
  fi
}

command -v jq >/dev/null 2>&1 || { log_error "jq is needed (base-cli group installs it)"; exit 1; }

make_key github_rsa "github $(whoami)@$(hostname)"
make_key gitlab_rsa "gitlab $(whoami)@$(hostname)"

register_github
register_gitlab
