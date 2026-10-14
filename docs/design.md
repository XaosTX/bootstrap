# Bootstrap — Design Goals & Architecture

> One command to bring a fresh machine up to a known-good state, on any of the
> systems I actually use. Detect the OS, create the directories I like, then walk
> me through installing the tools I want.

This document is the **big-picture endstate**. Work happens one distro at a time
(see [`TODO.md`](../TODO.md)), but the architecture below is chosen so that adding
a distro is "write a thin profile," never "refactor everything."

---

## 1. Goals

1. **Single entrypoint.** One run command, no need to know the distro first.
   ```sh
   curl -fsSL https://raw.githubusercontent.com/XaosTX/bootstrap/main/setup.sh | sh
   ```
2. **Detect, don't ask, for the OS.** The script figures out the distro and its
   package manager automatically.
3. **Directories first.** Create the personal layout (`~/Work`, `~/Work/Scratchpad`,
   `~/Life`) idempotently.
4. **Repos, not dirs.** `~/g/bootstrap` and `~/g/dotfiles` are **git clones**, not
   `mkdir`'d directories — clone-or-pull, never create empty:
   - `~/g/bootstrap` → this repo (the one being run)
   - `~/g/dotfiles` → `https://github.com/XaosTX/dotfiles.git`
5. **Walk through install options.** An interactive menu of *tool groups* the user
   toggles on/off. Remembers the last selection.
6. **Idempotent & re-runnable.** Safe to run repeatedly; already-installed things
   are detected and skipped.
7. **Incremental delivery without refactor.** Ship Ubuntu first; each new distro
   is additive.

### Non-goals (for now)
- Full config management (that's what the separate `dotfiles` repo + `stow` do).
- Windows / WSL support.
- Declarative convergence à la Ansible/Nix — this stays a readable POSIX-sh script.

---

## 2. Target systems

| Profile      | Base    | Package manager | Status        |
| ------------ | ------- | --------------- | ------------- |
| `ubuntu`     | Debian  | `apt`           | ✅ mostly done |
| `debian`     | Debian  | `apt`           | planned       |
| `mint`       | Ubuntu  | `apt`           | planned       |
| `fedora`     | RHEL    | `dnf`           | planned       |
| `rhel`       | RHEL    | `dnf`           | planned       |
| `alpine`     | Alpine  | `apk`           | planned       |
| `arch`       | Arch    | `pacman`        | planned       |
| `omarchy`    | Arch    | `pacman` + AUR  | planned       |
| `macos`      | Darwin  | `brew`          | ✅ existing (`setup-macos.sh`) |

**Omarchy** is treated as its own profile (not just "Arch"): it inherits the Arch
`pacman`/AUR package logic but layers Omarchy's Hyprland desktop conventions on
top. Keeping it separate means Omarchy-specific choices never leak into vanilla
Arch.

---

## 3. Architecture

The core idea: **three layers** separated so distro differences live in exactly
one place.

```
                      setup.sh  (entrypoint)
                          │
        ┌─────────────────┼──────────────────┐
        │                 │                  │
     lib/ (shared)   profiles/ (per-distro)  groups/ (per-tool)
   log, os, menu,    ubuntu, fedora,         base-cli, docker,
   dirs, pkg          alpine, omarchy…        asdf, desktop, fonts…
```

### 3.1 Proposed layout

```
bootstrap/
  setup.sh                 # THE entrypoint: detect → dirs → menu → dispatch
  lib/
    log.sh                 # log_header/success/error/arrow  (lift from init.sh)
    os.sh                  # detect_distro() → profile name; detect_pkg_mgr()
    dirs.sh                # create_dirs() (Work, Scratchpad, Life) + ensure_repo() clone-or-pull
    menu.sh                # prompt_menu()  (lift from init.sh)
    pkg.sh                 # pkg_update / pkg_install / pkg_has  — dispatch by mgr
  profiles/
    ubuntu.sh  debian.sh  mint.sh  fedora.sh  alpine.sh  arch.sh  omarchy.sh
    macos.sh               # (bridges to existing macos/ + setup-macos.sh logic)
  groups/                  # cross-distro tool groups; use pkg.sh, never raw apt
    base-cli.sh  docker.sh  asdf.sh  editors.sh  fonts.sh  browsers.sh  desktop.sh
  tools/   …               # existing (asdf plugins, brew Brewfiles, ssh, docker)
  macos/   …               # existing
  docs/    …               # this file, manual-steps, research-notes
```

Existing `setup-ubuntu.sh` / `setup-macos.sh` stay working during the transition;
they get **decomposed into** `profiles/` + `groups/` rather than deleted on day one.

### 3.2 The package-manager abstraction (the key to no-refactor)

`groups/*` never call `apt`/`dnf`/`pacman` directly. They call `pkg.sh`:

```sh
pkg_update                 # refresh index (apt update / dnf check-update / apk update / pacman -Sy)
pkg_install <generic-name> # install, mapped to the right package + command
pkg_has <bin>              # is this command already present?
```

`pkg.sh` dispatches on `$PKG_MGR` (set by `lib/os.sh`). A small **translation
table** handles the handful of names that differ across distros:

| generic          | apt               | dnf                | apk           | pacman          |
| ---------------- | ----------------- | ------------------ | ------------- | --------------- |
| `build-essential`| build-essential   | @development-tools | build-base    | base-devel      |
| `bat`            | bat (`batcat`)    | bat                | bat           | bat             |
| `ripgrep`        | ripgrep           | ripgrep            | ripgrep       | ripgrep         |
| `fd`             | fd-find (`fdfind`)| fd-find            | fd            | fd              |

Most tools have identical names — the table only lists the exceptions. Adding a
distro = add one column, write one thin `profiles/<name>.sh`.

### 3.3 Tool groups (the menu)

Groups are the unit the user toggles. Some groups expand into **item-level
sub-options** (each an independent `[ ]/[x]` checkbox) so a subgroup can be dialed
in without babysitting — e.g. pick Brave + Firefox but not Chrome in one pass.

`cli?` = part of the headless/quick preset (§3.4). `gui?` = hidden under `--headless`.

| Group        | cli? | gui? | Items (each toggleable)                                   |
| ------------ | :--: | :--: | -------------------------------------------------------- |
| **base-cli** |  ✅  |      | git, curl, wget, jq, ripgrep, fd, bat, tree, unzip, gnupg, stow, tmux |
| **shell**    |  ✅  |      | zsh, **tab-completion**, sensible defaults (shell QoL, *not* full dotfiles) |
| **nettools** |  ✅  |      | nmap, ncat, ipcalc, dig/dnsutils (incl. nslookup), traceroute, `[ ] tailscale` |
| **vi**       |  ✅  |      | `[ ] vim`  `[ ] nvim`  (both offered — pick one or both)  |
| **python**   |  opt |      | python3, pip, uv · `[ ] via-asdf` (see §3.6 open question) |
| **asdf**     |  opt |      | asdf + plugins (node, terraform, rust, java, helm, …) — existing `tools/asdf/` |
| **docker**   |  opt |      | `get.docker.com` + group membership (existing `tools/get-docker.sh`) |
| **git-tools**|  opt |      | `[ ] glab` (GitLab CLI), gh, lazygit                      |
| **llm**      |  opt |      | agents: `[ ] claude` `[ ] gemini` · **skills** (caveman, handoff, …), personas/standards, mcp (see §3.6) |
| **dotfiles** |  opt |      | clone + `stow` the personal `dotfiles` repo (the "my own stuff") |
| **ssh**      |  opt |      | generate keys (existing `tools/ssh/generate-ssh-keys.sh`) |
| **homelab**  |  opt |      | LAN/NAS: `[ ] mdns` `[ ] discovery` `[ ] nas-smb` `[ ] nas-nfs` — Synology automounts (see §3.7) |
| **editors**  |      |  ✅  | VS Code + extensions                                     |
| **fonts**    |      |  ✅  | Nerd Fonts                                               |
| **browsers** |      |  ✅  | `[ ] chrome`  `[ ] brave`  `[ ] firefox`                 |
| **desktop**  |      |  ✅  | Postman, KeepassXC, Wireshark (each toggleable)          |

`--headless` hides every `gui?` group. Server VMs get the CLI stack and nothing X11.

**`editors` must enable the `code` CLI** so `code .` works from the terminal after
install — and verify it (`command -v code`), don't assume:
- **Linux** (apt/deb, dnf/rpm): the package already puts `code` on `PATH` — verify only.
- **macOS**: the bundled binary lives at
  `/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code`; the GUI
  "Shell Command: Install 'code' command in PATH" is a **manual step** (currently in
  `docs/manual-steps.md`). Automate it: symlink that binary into `~/.local/bin` (or
  `/usr/local/bin`) so `code .` works headlessly, no GUI action needed.
- Same pattern generalizes to other editors' CLIs if added (e.g. `cursor`).

### 3.4 Presets (bundles)

A preset is a named starting selection so common cases skip the menu (or start it
pre-checked). Chosen by flag; the menu still opens unless `--yes` is given.

| Preset / flag        | Groups pre-selected                                  | For… |
| -------------------- | ---------------------------------------------------- | ---- |
| `--quick` / `--min`  | base-cli, shell, nettools, vi                        | "just enough CLI QoL, none of my own stuff" — fresh VMs, someone else's box, containers |
| `--headless`         | quick + python/asdf/docker offered, **all GUI hidden** | servers, GCP VMs, SSH-only |
| *(default, no flag)* | last-remembered selection (or quick on first run)    | my daily driver |
| `--all`              | every group applicable to the detected profile       | full workstation, unattended |

`--quick` is deliberately *personal-config-free*: it does **not** pull `dotfiles`
or `llm` — it's the "make any shell bearable in 30 seconds" path.

### 3.5 Control flow of `setup.sh`

```
main:
  parse flags         # --quick/--min, --headless, --all, --yes, --dry-run, --help
  PROFILE  = detect_distro()          # lib/os.sh
  PKG_MGR  = detect_pkg_mgr(PROFILE)  # lib/os.sh
  source lib/*.sh, profiles/$PROFILE.sh
  create_dirs()                       # lib/dirs.sh — Work, Scratchpad, Life
  pkg_update
  ensure git
  ensure_repo ~/g/bootstrap  <this repo>                              # clone-or-pull
  ensure_repo ~/g/dotfiles   https://github.com/XaosTX/dotfiles.git
  PRESELECT = preset_for(flags) or last_selection    # §3.4
  SELECTED  = prompt_menu(GROUPS, PRESELECT)         # skipped if --yes
  for g in SELECTED: run groups/$g.sh   # groups expand their own item-level [x] picks
  print manual-steps pointer + done banner
```

### 3.6 LLM group — skills registry

The `llm` group installs LLM tooling and **agent skills** — self-contained
installers that layer behavior onto whatever AI coding agents are present (Claude
Code, Cursor, Codex, …). Each skill is an item-level `[x]` checkbox (§4).

**Cross-platform — including macOS.** This group is *not* Linux-only. The skill
installers (caveman's `curl … | bash`, etc.) run on macOS/Linux/WSL alike and write
to `~/.claude/`, so the `macos` profile uses the **same `groups/llm.sh`** as every
Linux profile — no brew-specific fork. This is a concrete reason the macOS path
must adopt the groups model (see §6).

Skills are external one-liner installers, so the group's job is to run each
selected skill's own installer **idempotently and after the agents exist** —
ordering matters: install/verify the agent(s) first, then skills, so the skill
can auto-detect and wire them.

| Skill                | Install                                                                 | Notes |
| -------------------- | ---------------------------------------------------------------------- | ----- |
| **caveman**          | `curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh \| bash` | Terse "caveman mode" across agents. Auto-detects agents, writes hooks + statusline to `~/.claude/` (respects `$CLAUDE_CONFIG_DIR`). Flags: `--dry-run`, `--force` (reinstall), `--uninstall`. Activate with `/caveman`. |
| handoff              | TBD                                                                    | from wishlist — pin source before implementing |
| *(more)*             | —                                                                      | registry grows here |

Design implications for the `llm` group:
- **Pass through our flags:** when `setup.sh` runs `--dry-run`, the group calls
  each skill installer's own dry-run (caveman supports `curl … | bash -s -- --dry-run`);
  on re-run it uses `--force`/idempotent paths so repeats are safe (§ idempotency).
- **Prereq gate:** skip a skill (with a `log_arrow` note) if no supported agent is
  detected, rather than installing into a void.
- **Uninstall path:** the group should know each skill's uninstall (caveman:
  `--uninstall`) so selections can be *removed*, not just added.
- **Node:** caveman's git-clone method needs `node`; the curl one-liner does not —
  prefer the one-liner to avoid a hidden Node dependency on minimal boxes.

### 3.7 Homelab group — LAN & NAS mounts

The one group whose correct answer is **per-machine, not per-distro**: share names,
NAS address and credentials differ on every box. So the group ships behavior, and
the machine supplies data via `~/.config/bootstrap/homelab.conf` (template:
`groups/homelab.conf.example`, never committed with real values).

Items:

| Item        | Does                                                                 |
| ----------- | -------------------------------------------------------------------- |
| `mdns`      | avahi + nss-mdns so `nas.local` resolves with no DNS entry     |
| `discovery` | `avahi-utils`, `arp-scan` — find what's actually on the LAN           |
| `nas-smb`   | `cifs-utils`, prompts once for the password, writes fstab automounts  |
| `nas-nfs`   | `nfs-common` + fstab automounts (DSM must export the share first)     |

Decisions:

- **Automount, never `auto`.** Every entry gets `nofail,_netdev,x-systemd.automount`
  plus an idle timeout. A laptop off the home LAN — or a NAS that's powered down —
  must not stall boot or hang `df`. Shares mount on first access and unmount when idle.
- **Marked fstab block.** Entries live between `# >>> bootstrap homelab >>>` and
  `# <<< …`, so re-runs replace rather than duplicate, and hand-written entries
  outside the block are never touched. `/etc/fstab` is backed up to
  `/etc/fstab.bootstrap.bak`, and the candidate file must pass
  `findmnt --verify` before it is installed — a bad fstab strands a box at boot.
- **Credentials out of the repo and out of `argv`.** The SMB password is read from
  `/dev/tty` with echo off and written via heredoc (not a command argument, so it
  never shows in `ps`) to `/etc/samba/credentials/<host>`, root-owned `0600`.
- **NAS paths ≠ local paths.** `/volume1/music` is the DSM-side path and never
  exists locally; share `music` mounts at `/mnt/nas/music`. The config accepts
  either spelling and strips the `/volume1/` prefix.
- **SMB and NFS get separate roots** (`/mnt/nas`, `/mnt/nfs`) so both can be
  enabled for the same share without fighting over a mountpoint.

---

## 4. Interaction model

**Decision: checkbox multi-select, two tiers, batch-toggle** — no one-at-a-time
babysitting. Set everything, then confirm once. Evolves `prompt_menu` from
`init.sh` (same batch-number-toggle mechanic) to a `[ ]/[x]` render.

**Tier 1 — groups.** Pre-checked from the active preset (§3.4):

```
Bootstrap — pick groups (numbers toggle, ENTER to confirm):
 [x] 1) base-cli
 [x] 2) shell
 [x] 3) nettools
 [x] 4) vi
 [ ] 5) python
 [ ] 6) docker
 [ ] 7) browsers        (gui)
 [ ] 8) dotfiles
> 5 6            ← toggles python + docker on in one keystroke-set
```

**Tier 2 — items** (only for groups that have sub-options; only for checked
groups). Same batch-toggle, so a subgroup is dialed in without prompting per item:

```
browsers — pick which (ENTER to confirm):
 [ ] 1) chrome
 [x] 2) brave
 [x] 3) firefox
```

Key properties:
- **Batch toggle**: type any set of numbers separated by spaces; ENTER on empty
  input confirms. Nothing forces you through options you don't care about.
- **Remembered**: the full selection (groups *and* item checks) is cached to
  `.selected` and becomes next run's pre-check.
- **Non-interactive escapes**: `--yes` accepts the preset as-is (no menu);
  `--all` checks everything; `--quick`/`--headless` change what starts checked.

*Open to override:* the whole menu lives in `lib/menu.sh` — swapping render or
mechanic touches nothing else in the architecture.

---

## 4.1 Open design question: does `asdf` own Python on \*nix?

Raised during design; **decide before the `python` group is written.**

On macOS the workflow is asdf-managed everywhere. On Linux there's a real choice:

| Option | Python source | Pros | Cons |
| ------ | ------------- | ---- | ---- |
| **A. System + uv** *(leaning)* | distro `python3` + `pip`, plus `uv` for envs/versions | always present, zero indirection, `uv` handles pinning fast | system python version is whatever the distro ships |
| **B. asdf-python** | asdf plugin builds Python | exact pinned versions, mirrors macOS | build deps + compile time on every box; overkill for a "quick" machine |
| **C. Both, layered** | system python3 as floor; asdf optional for dev pinning | quick boxes stay light, dev boxes get pinning | two code paths in the `python` group |

**Resolved (see §7.1): `uv` is the Python standard on both OSes.**
- **`--quick`/minimal boxes**: system `python3` for anything trivial, `uv` for the
  rest — no asdf. Fast, light.
- **dev boxes**: `uv python install 3.x.y` provides pinned interpreters (prebuilt,
  cross-platform); `[ ] via-asdf` remains only as an opt-in for one-manager purists.
- **Always**: dependencies live in a **venv** (`uv`), never global (§7.2).

So the `python` group installs `uv` (via the native pkg manager) and lets `uv` own
interpreter versions; asdf-python is a fallback, not the default.

---

## 5. Conventions carried over

- **POSIX `sh`** where practical (bash only when a group genuinely needs it), so
  Alpine/BusyBox works.
- **Logging helpers** (`log_header` / `log_success` / `log_error` / `log_arrow`)
  from `init.sh` — lifted verbatim into `lib/log.sh`.
- **Directory scheme**: `~/Work`, `~/Work/Scratchpad`, `~/Life` are created;
  `~/g/bootstrap` (this repo) and `~/g/dotfiles`
  (`https://github.com/XaosTX/dotfiles.git`) are **cloned/pulled**, not made
  (from `setup-ubuntu.sh` / `setup-macos.sh`).
- **Idempotency guard**: every install checks `pkg_has` / `command -v` first.
- **`shellcheck` clean** — run in CI before merge.

---

## 6. Known gaps to resolve during implementation

- `setup-ubuntu.sh` references `ubuntu/vscode-extensions.sh`, `ubuntu/fonts.sh`,
  `ubuntu/browsers.sh`, but **no `ubuntu/` directory exists** — these calls fail
  today. They become `groups/editors.sh`, `groups/fonts.sh`, `groups/browsers.sh`.
- `setup-debian.sh` / `setup-alpine.sh` are stubs (`rm $HOME/setup-macos.sh`) —
  replaced by real `profiles/`.
- `README.md` still documents the old per-OS curl command — update to the single
  `setup.sh` entrypoint once it lands.
- **macOS must adopt the groups model.** `setup-macos.sh` is brew-Brewfile-driven
  and has no `llm` group. Since `groups/llm.sh` (caveman & co.) is cross-platform
  (§3.6), the `macos` profile needs to call the shared groups — at minimum `llm` —
  instead of only running Brewfiles. Migrate incrementally: keep Brewfiles for
  package installs, but route `llm`/skills through `groups/llm.sh`.

---

## 7. Language toolchains & environment standards

> Cross-platform rules for Node/npm and Python/pip. These are *standards*, not just
> installs — they should also be encoded in the `llm` personas/standards (§3.6) so
> the agent follows them too. **`~/g/dotfiles` may already own parts of this** (shell
> enforcement, git identity) — verify against it before adding; bootstrap should
> *align*, never duplicate.

### 7.1 Version managers: asdf for most runtimes, uv for Python; no nvm; brew ≠ runtime manager

| Layer                         | macOS            | Linux                    |
| ----------------------------- | ---------------- | ------------------------ |
| **Python interpreter versions** | **`uv`**       | **`uv`**                 |
| **Other runtimes** (node, ruby, java…) | **asdf**  | **asdf**                 |
| Runtime pinning               | `.python-version` (uv) / `.tool-versions` (asdf) | same |
| System/CLI packages           | `brew`           | apt/dnf/apk/pacman       |
| asdf itself installed via     | `brew`           | git-clone (`tools/asdf/init.sh`) |

- **Python is managed by `uv` on both OSes.** `uv python install 3.12.4` installs a
  specific, **prebuilt standalone** Python — same command, same result on Linux and
  macOS, no compiling. Multiple versions coexist; projects pin via `.python-version`.
  uv also does venvs (`uv venv`) and global CLIs (`uv tool install`), so it's the
  single Python tool end-to-end. See §7.1.1 for why not brew/asdf for Python.
- **Other runtimes go through asdf on both OSes** — one manager, identical workflow
  Mac↔Linux. Already the repo's direction (`tools/asdf/`).
- **No `nvm`.** asdf's `nodejs` plugin is the single Node manager; a second manager
  on the same `PATH` is a footgun. `nvm` is an explicit opt-out only, never default.
- **`brew` is a package manager (apt/dnf peer), not a runtime manager.** It installs
  `uv`, asdf + system CLIs; it does **not** install the dev Python/Node — those stay
  in uv/asdf so Mac and Linux match.

#### 7.1.1 Why `uv` for Python (not the system, brew, or asdf interpreter)

The macOS Python mess comes from mixing system Python + brew Python + `pip --user` +
global `pip`. Avoid it by routing everything through one manager. Candidates:

| Manager | Multi-version? | Verdict |
| ------- | -------------- | ------- |
| System `python3` | no | **never** — never install into it; it's for the OS |
| `brew python@X` | major.minor only, brew picks patch | **not for dev** — `brew upgrade` moves the interpreter, **breaking venvs** that hardcode its path; fine only for brew apps that vendor their own Python (leave those alone) |
| `asdf` (`python-build`) | any exact version | works, cross-lang consistency, but **compiles from source** (build deps + minutes/version) |
| **`uv`** | any exact version, **prebuilt** | **chosen** — seconds not minutes, no build deps, + venvs + global tools in one tool |

Mental model:

| Concern | Tool |
| ------- | ---- |
| System Python | ignore; never install into it |
| brew | bootstraps `uv`/asdf; brew apps vendor their own Python — leave them |
| Dev interpreter versions | **`uv python install 3.x.y`** |
| Project deps | **`uv venv` + `uv pip`** (never global — §7.2) |
| Global Python CLIs | **`uv tool install`** (or `pipx`) |

*Fallback:* if strict one-manager-for-all-languages consistency is preferred over
best-in-class, `asdf` python is acceptable — it only costs compile time; the
no-global-venv rule (§7.2) is unchanged either way.

### 7.2 Non-global installs (venvs by default) — machine *and* LLM policy

**Default: nothing installs into a global/system interpreter.** Prefer isolated
environments; allow a small, curated set of global tools only "as needed."

- **Python** — never `pip install` into the asdf/system interpreter. Every project
  uses a **venv** (`uv` preferred: `uv venv` / `uv pip`). `~/g/dotfiles` zsh already
  **enforces this** (refuses to run python outside a venv) — bootstrap must *honor*
  that guard, not work around it. The `python` group installs the interpreter + `uv`;
  it does not `pip install` libraries globally.
- **Node** — prefer project-local deps + `npx`. Global `npm i -g` is reserved for a
  short **allowlist** of genuine CLIs (define the list explicitly; keep it tiny).
- **Encode for the agent too** — this policy belongs in the `llm` standards/personas
  so the agent defaults to venvs/`npx` and doesn't casually install globally.

### 7.3 Ownership boundary with `~/g/dotfiles`

| Concern | Owner | Bootstrap's role |
| ------- | ----- | ---------------- |
| zsh "python must run in a venv" guard | **dotfiles** | rely on it; don't defeat it |
| Conditional git identity (`includeIf`) | **dotfiles** | provision so its assumptions hold |
| Shell aliases / completion config | **dotfiles** (`stow`) | clone + stow only |
| `~/Work`, `~/Life`, runtimes, SSH keys, identities | **bootstrap** | create/install |

### 7.4 Conditional git identity (Work vs Life)

Convention: git in `~/Work` uses one `user.name`/`user.email`; git in `~/Life` uses
another. Implemented with git's native `includeIf`:

```gitconfig
[includeIf "gitdir:~/Work/"]  path = ~/.gitconfig-work
[includeIf "gitdir:~/Life/"]  path = ~/.gitconfig-life
```

- **dotfiles owns the `includeIf` rules and the per-zone gitconfig fragments.**
- **Bootstrap owns provisioning:** it already creates `~/Work` and `~/Life`; its
  SSH-key / identity step must **generate the two identities to match** what
  dotfiles' `includeIf` expects — "at generation they match." i.e. key comments,
  `user.email` per zone, and the `gitdir:` paths must all line up.
- Verify the exact paths/emails against `~/g/dotfiles` before wiring the ssh/identity
  group — this may already exist there.

---

## 8. Endstate acceptance

The design is "done" when:
1. `curl … setup.sh | bash` works on a fresh box of **every** table-listed distro.
2. Adding the *next* distro touched only: one `profiles/*.sh`, one `pkg.sh` column,
   and zero changes to `groups/*`.
3. Re-running on a configured box is a no-op that reports "already installed."
