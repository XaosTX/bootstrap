# bootstrap

One interactive script that sets up a new machine: it detects the OS, installs
the packages and tools for it, and then runs the dotfiles install.

- **Entry point:** `setup.sh`. It finds the OS (`lib/os.sh`), loads the matching
  profile (`profiles/`), and shows a group menu. The menu offers the groups for
  that OS; numbers toggle, ENTER confirms.
- **Dotfiles:** the `dotfiles` group clones `XaosTX/dotfiles` to `~/g/dotfiles`
  and runs its `install.sh`.
- **Groups:** `groups/*.sh`, one per feature. Each group reads its items from
  `ITEMS`, which the menu fills in (tier 2).

## Run it

```sh
curl -fsSL https://raw.githubusercontent.com/XaosTX/bootstrap/main/setup.sh | sh
```

or from a clone:

```sh
git clone https://github.com/XaosTX/bootstrap.git ~/g/bootstrap
cd ~/g/bootstrap
./setup.sh                  # menu
./setup.sh --dry-run --all  # print the plan, install nothing
./setup.sh --quick --yes    # CLI basics only, no menu
```

Flags:

| Flag | Meaning |
|------|---------|
| `--quick`, `--min` | preset: `base-cli shell nettools vi` |
| `--headless` | hide GUI groups |
| `--all` | preselect every group for this OS |
| `--yes`, `-y` | accept the preselection, no menu |
| `--dry-run` | print what would run |

The last menu choices are saved in `.selected` (ignored by git).

## OS support

| OS | Profile | Package manager | Groups |
|----|---------|-----------------|--------|
| Ubuntu, Debian, Mint | `profiles/ubuntu.sh`, `debian.sh`, `mint.sh` | apt | common + `homelab editors browsers desktop chefdk eclipse` |
| macOS | `profiles/macos.sh` | Homebrew | common + `brew-core brew-extras iterm2 macos-defaults macos-apps rosetta` |

`profile_prepare` (macOS) installs the Xcode command line tools and Homebrew
before anything else. Fedora, RHEL, Alpine and Arch are detected but have no
profile yet.

## Groups

**Common** (every OS): `dotfiles`, `base-cli`, `shell`, `nettools`, `vi`,
`vim-plugins`, `fzf`, `npm`, `python`, `asdf`, `docker`, `git-tools`, `llm`,
`ssh`, `fonts`, `zsh-framework`.

**Items** are picked in the menu. Defaults are marked in `group_default_items`
in `setup.sh`; off-by-default items are risky or old:

- `chefdk`: end-of-life Chef DK, installed by piping a script into `sudo bash`.
- `eclipse`: pinned to 2016 releases.
- `dock-clear-apps`: removes every pinned Dock icon.
- `zsh-framework`: oh-my-zsh, prezto, powerline. zinit is the dotfiles default
  and needs nothing here.

## Local settings

- `groups/homelab.conf`: your NAS names and share list. Copy
  `groups/homelab.conf.example` to `~/.config/bootstrap/homelab.conf`. It is
  kept out of git.
- `.selected`: the last menu choices, kept out of git.

Passwords and tokens are never written to this repository. The homelab SMB
password is prompted once and stored root-only on the machine.

## Attribution and history

See `NOTICE.md`. The older dotfiles-only install steps and the separate
`setup-*.sh` wrappers are gone; their work is in `groups/`, `profiles/` and
`setup.sh`. `docs/design.md` describes the groups model.
