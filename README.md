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

## Menus

`setup.sh` asks in three steps:

1. **Categories:** setup, editors, cli, languages, infra, ai, apps (Linux) or mac (macOS).
2. **Groups** inside each chosen category, alphabetical.
3. **Items** for the groups that have them, for example the tools to install with `asdf`.

Groups that need another one (`npm` needs `asdf`, `vim-plugins` needs `vi`, `brew-extras` needs `brew-core`) add it and say so.

## OS support

| OS | Profile | Package manager | Categories |
|----|---------|-----------------|------------|
| Ubuntu, Debian, Mint | `profiles/ubuntu.sh`, `debian.sh`, `mint.sh` | apt | setup, editors, cli, languages, infra, ai, apps |
| macOS | `profiles/macos.sh` | Homebrew | setup, editors, cli, languages, infra, ai, mac |

`profile_prepare` (macOS) installs the Xcode command line tools and Homebrew
before anything else. Fedora, RHEL, Alpine and Arch are detected but have no
profile yet.

## Groups

| Category | Groups |
|----------|--------|
| setup | `dotfiles`, `fonts`, `fzf`, `shell`, `zsh-framework` (off) |
| editors | `eclipse` (Linux, off), `editors` (Linux GUI), `vi`, `vim-plugins` |
| cli | `base-cli`, `git-tools`, `nettools`, `ssh`, `ssh-dropbox` (off) |
| languages | `asdf` (items: node, terraform, helm, stern, consul, vault, azure, gcloud, pnpm, java, rust), `npm`, `python` |
| infra | `chefdk` (Linux, off), `docker`, `homelab` (Linux) |
| ai | `llm` |
| apps | `browsers`, `desktop` (Linux GUI) |
| mac | `brew-core`, `brew-extras`, `iterm2`, `macos-apps`, `macos-defaults`, `rosetta` |

"(off)" groups have no default item and run only if you pick one. The dotfiles
group always runs first, since the rest depends on its links.

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
