#!/bin/sh
# tools/asdf/init.sh
#
# Works on both macOS (brew-managed asdf) and Linux (git-clone asdf).
# Mirrors the interactive menu pattern from the original.

BOOTSTRAP=$1
if [ -z "$BOOTSTRAP" ]; then
    BOOTSTRAP="$HOME/g/bootstrap"
fi

ASDF_DIR="$HOME/.asdf"

# ──────────────────────────────────────────────
#  Ensure asdf is installed + sourced
# ──────────────────────────────────────────────

if command -v asdf > /dev/null 2>&1; then
  echo "✔ asdf already available: $(asdf version)"
elif [ -d "$ASDF_DIR" ]; then
  # Linux git-clone install
  # shellcheck disable=SC1090
  . "$ASDF_DIR/asdf.sh"
  echo "✔ asdf sourced from $ASDF_DIR"
else
  echo "✖ asdf not found — run setup.sh first"
  exit 1
fi

# ──────────────────────────────────────────────
#  Interactive menu
# ──────────────────────────────────────────────

while true; do
    echo ""
    echo "asdf plugin installer:"
    echo "  1. terraform"
    echo "  2. nodejs (latest LTS)"
    echo "  3. google-cloud-sdk"
    echo "  4. rust"
    echo "  5. helm"
    echo "  6. java"
    echo "  7. Install all"
    echo "  8. Continue / exit"
    printf "Choice: "
    read -r choice
    case "$choice" in
        1)
            echo "Installing terraform"
            bash "$BOOTSTRAP/tools/asdf/asdf-terraform.sh"
            ;;
        2)
            echo "Installing nodejs (latest LTS)"
            bash "$BOOTSTRAP/tools/asdf/asdf-node.sh"
            ;;
        3)
            echo "Installing google-cloud-sdk"
            bash "$BOOTSTRAP/tools/asdf/asdf-google-sdk.sh"
            ;;
        4)
            echo "Installing rust"
            bash "$BOOTSTRAP/tools/asdf/asdf-rust-lang.sh"
            ;;
        5)
            echo "Installing helm"
            bash "$BOOTSTRAP/tools/asdf/asdf-helm.sh"
            ;;
        6)
            echo "Installing java"
            bash "$BOOTSTRAP/tools/asdf/asdf-java.sh"
            ;;
        7)
            echo "Installing all plugins"
            bash "$BOOTSTRAP/tools/asdf/asdf-terraform.sh"
            bash "$BOOTSTRAP/tools/asdf/asdf-node.sh"
            bash "$BOOTSTRAP/tools/asdf/asdf-google-sdk.sh"
            bash "$BOOTSTRAP/tools/asdf/asdf-rust-lang.sh"
            bash "$BOOTSTRAP/tools/asdf/asdf-helm.sh"
            ;;
        8)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done

