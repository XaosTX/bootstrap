#!/bin/sh
# groups/asdf.sh — asdf version manager (git clone, pinned v0.14.0), then the tool items below.
# ITEMS: node terraform helm stern consul vault azure gcloud pnpm java rust
# Each item runs its tools/asdf/asdf-*.sh script. Shell setup comes from the dotfiles.
set -e
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$HOME/g/bootstrap}"
. "$BOOTSTRAP_DIR/lib/log.sh"
. "$BOOTSTRAP_DIR/lib/pkg.sh"

ASDF_DIR="$HOME/.asdf"

if command -v asdf >/dev/null 2>&1 || [ -d "$ASDF_DIR" ]; then
  log_success "asdf already installed"
else
  run git clone https://github.com/asdf-vm/asdf.git "$ASDF_DIR" --branch v0.14.0
  log_success "asdf cloned to $ASDF_DIR"
fi

# Older runs appended asdf.sh to ~/.zshrc, which breaks zsh, so warn about any leftover lines.
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if grep -q 'asdf/asdf.sh\|asdf/completions/asdf.bash' "$rc" 2>/dev/null; then
    log_error "$rc sources asdf.sh from an older run — delete those lines (the dotfiles set PATH for asdf)"
  fi
done

for item in $ITEMS; do
  case "$item" in
    node)      script=asdf-node.sh ;;
    terraform) script=asdf-terraform.sh ;;
    helm)      script=asdf-helm.sh ;;
    stern)     script=asdf-k8s.sh ;;
    consul)    script=asdf-consul.sh ;;
    vault)     script=asdf-vault.sh ;;
    azure)     script=asdf-azure-sdk.sh ;;
    gcloud)    script=asdf-google-sdk.sh ;;
    pnpm)      script=asdf-pnpm.sh ;;
    java)      script=asdf-java.sh ;;
    rust)      script=asdf-rust-lang.sh ;;
    *)         log_error "unknown asdf item: $item"; continue ;;
  esac
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] tools/asdf/$script"
  else
    bash "$BOOTSTRAP_DIR/tools/asdf/$script" || log_error "asdf item $item failed"
  fi
done
