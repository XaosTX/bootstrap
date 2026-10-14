# bootstrap

Sets up a machine: gets the dotfiles, runs their setup, then runs this machine's install steps.

    ./bootstrap.sh --dry-run --yes                      # the dotfiles plan, and the steps that would run
    ./bootstrap.sh --yes --install                      # dotfiles (no prompts) and the install steps
    ./bootstrap.sh --install --optional                 # install steps, then the optional steps (asked one by one)

## What it does

1. Clones `XaosTX/dotfiles` to `~/g/dotfiles`, or pulls it if it's already there.
2. Runs the dotfiles `install.sh` with the same flags you gave. Any warning there stops the run.
3. Runs the install steps for this OS, if `--install` is given:
   - `steps/common/`: fonts; asdf and the latest LTS Node.js (via `asdf/plugins.txt`); npm 12 with the cooldown settings.
   - `steps/darwin/`: Xcode tools, Homebrew, the core packages in `brew/Brewfile`, fzf, iTerm2 preferences, vim plugins.
   - `steps/linux/`: apt packages and `dist-upgrade`, vim plugins.
4. With `--optional`, runs `steps/optional/`:
   - Shared: oh-my-zsh and prezto.
   - macOS: the optional Brewfile groups (`brew/optional/`, asked one by one), Dock settings, powerline.
   - Linux: Chef DK (disabled until fixed), Eclipse with eclim (old releases).
   Asks for each one unless `--yes` is given.

`steps/deferred/` holds the Dropbox key step. Nothing runs it.

## Flags

| Flag | Meaning |
|---|---|
| `--dotfiles-dir DIR` | The dotfiles checkout (default `~/g/dotfiles`). |
| `--dotfiles-repo URL` | Repo to clone when the checkout is missing. |
| `--no-clone` | Use the checkout as it is; do not clone or pull. |
| `--skip-dotfiles` | Run only the install steps. |
| `--install` | Run the install steps for this OS. |
| `--optional` | Also run the optional steps. Implies `--install`. |
| anything else | Passed to the dotfiles `install.sh` (`--yes`, `--dry-run`, `--choose`, `--profiles`, `--home`). |

## Status

The macOS packages come from codeangler's current bootstrap (Brewfiles, Dock settings), with employer taps removed. The asdf and npm steps are new. Still to port from codeangler's bootstrap: the other asdf plugins (`tools/asdf/`), the ssh group, Docker, git tools beyond gh, glab and lazygit, and the App Store step. Review each step before running `--install` on a Mac.
