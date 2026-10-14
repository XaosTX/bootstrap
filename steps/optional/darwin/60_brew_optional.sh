# Optional Homebrew groups from brew/optional/. Asks for each one (default no).
# Without a terminal, nothing is installed: run it interactively, or use `brew bundle --file` directly.
if [ ! -t 0 ] || [ ! -t 1 ]; then e_arrow "optional Homebrew groups need an interactive run; skipped"; return 0; fi
for f in "$BOOT_ROOT"/brew/optional/*.Brewfile; do
  name=$(basename "$f" .Brewfile)
  read -r -p "  Install the $name group (brew/optional/$name.Brewfile)? [y/N]: " ans
  case "$ans" in y|Y|yes|YES) brew bundle --file="$f";; *) e_arrow "skipped $name";; esac
done
