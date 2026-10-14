# bootstrap

Sets up a machine: gets the dotfiles, runs their setup, then runs this machine's install steps.

    ./bootstrap.sh --dry-run --yes                      # the dotfiles plan, and the steps that would run
    ./bootstrap.sh --yes --install                      # dotfiles (no prompts) and the install steps
    ./bootstrap.sh --install --optional                 # install steps, then the optional steps (asked one by one)

## What it does

1. Clones `XaosTX/dotfiles` to `~/g/dotfiles`, or pulls it if it's already there.
2. Runs the dotfiles `bootstrap.sh` with the same flags you gave. Any warning there stops the run.
3. Runs the install steps for this OS, if `--install` is given:
   - `steps/common/` on every OS (fonts).
   - `steps/darwin/` on macOS (Xcode tools, Homebrew, casks, recipes, fzf, iTerm2, node, ruby, vim plugins, misc).
   - `steps/linux/` on Linux (apt packages and `dist-upgrade`, vim plugins).
4. With `--optional`, runs `steps/optional/` (oh-my-zsh, prezto, Chef DK, Eclipse). Asks for each one unless `--yes` is given.

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
| anything else | Passed to the dotfiles `bootstrap.sh` (`--yes`, `--dry-run`, `--choose`, `--profiles`, `--home`). |

## Status

The steps came from codeangler's 2018 dotfiles. They are not yet reviewed or updated. codeangler's current bootstrap repo (Brewfiles, `macos/` scripts, asdf) is not in here yet. Review each step before running `--install` on a Mac.
