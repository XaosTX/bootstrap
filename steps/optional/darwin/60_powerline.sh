# Optional: powerline, for the codeangler tmux option (variants/tmux/codeangler in the dotfiles repo).
if command -v pip3 >/dev/null 2>&1; then pip3 install --user powerline-status; else e_arrow "pip3 not found"; fi
