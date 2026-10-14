# fzf key bindings and completion, without editing shell rc files (the dotfiles load ~/.fzf.zsh).
if command -v brew >/dev/null 2>&1 && [ -x "$(brew --prefix)/opt/fzf/install" ]; then
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc
else
  e_arrow "fzf not installed yet (brew bundle installs it)"
fi
