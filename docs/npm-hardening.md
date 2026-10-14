# npm supply-chain hardening

Added 2026-08 after the "ChainDrop" / "Shai-Hulud: Here We Go Again" npm worm
(Wiz + Microsoft reports). Every fresh machine bootstrap now applies a package
cooldown by default.

Implementation: [`tools/npm/harden.sh`](../tools/npm/harden.sh), invoked from
[`tools/asdf/asdf-node.sh`](../tools/asdf/asdf-node.sh) right after node installs.

## Threat, in one paragraph

Malicious package version ships a `preinstall`/`postinstall` hook that harvests
credentials — **npm publish tokens**, GitHub PATs, cloud keys, SSH keys, CI/CD
secrets. The stolen npm token is then used to enumerate every package that
identity can publish, patch each tarball, bump the version, and republish.
One token compromises a publisher's entire catalogue, with no human involved.
Secondary persistence injects into **Claude Code hooks** and **VS Code
`tasks.json`**, so it survives `rm -rf node_modules`.

## Control: package cooldown

Malicious versions are typically yanked within hours. A 7-day quarantine means
the resolver never sees them. npm silently falls back to the newest version
older than the threshold, so builds keep working.

```ini
min-release-age=7
```

### The unit is DAYS — this is the trap

```ini
min-release-age=7        # correct
min-release-age=10080    # WRONG: 10080 DAYS = year 1998
```

`10080` is the natural "7 × 1440 minutes" conversion. It makes **every** npm
install fail with `ENOVERSIONS: No versions available`.

The silent-failure band matters more than the loud one — values in the low
thousands don't error, they resolve ancient versions with known CVEs:

| value | resolves `lodash` to |
|---|---|
| `4000` | 3.10.1 (2015) |
| `4320` | 2.4.1 (2013) |
| `5000` | 0.8.2 (2012) |
| `5760`+ | `ENOVERSIONS` |

Verified empirically on **npm 12.0.2** — isolated env, clean cache, no npmrc
influence. `harden.sh` hardcodes `COOLDOWN_DAYS=7` and the check script flags
any value > 365 as a minutes-style bug. npm rejects unit suffixes (`7d`, `168h`).

## Requires npm >= 12

npm < 12 does not know the key and **ignores it silently** — zero protection,
no warning. `harden.sh` upgrades npm before setting anything (order matters:
setting the cooldown first can block the npm upgrade itself).

Second line of defence, `engine-strict=true` plus:

```json
{ "engines": { "node": ">=20", "npm": ">=12" } }
```

An old npm now emits `EBADENGINE` and refuses, rather than skipping the gate.
Scaffolded into every new project by `~/.npm-init.js`.

## Where config lands, per platform

| | macOS | Debian / Ubuntu |
|---|---|---|
| primary | `~/.npmrc` — survives node upgrades | `~/.npmrc` |
| backup | `$(npm config get globalconfig)` — **per node version, lost on upgrade** | **`/etc/npmrc`** — system-wide, survives upgrades |

That asymmetry is the reason `harden.sh` branches on `uname`. On macOS/asdf the
backup layer must be re-applied after every node install — which is exactly why
`asdf-node.sh` calls it.

## Other settings applied

| Key | Value | Why |
|---|---|---|
| `audit` / `audit-level` | `true` / `moderate` | fail installs on known advisories |
| `save-exact` | `true` | stop a caret range pulling a trojanised patch later |
| `engine-strict` | `true` | make an old npm refuse instead of skipping |
| `fund` | `false` | noise |

## Deliberately NOT enabled

`ignore-scripts=true` blocks `preinstall`/`postinstall` — precisely the
execution vector, and the strongest single control. It breaks native builds
(playwright, esbuild, sharp, node-gyp), so it stays off. Per-install instead:

```sh
npm install --ignore-scripts <pkg>
```

Revisit if this repo ever targets CI runners, where nothing needs native builds
and the blast radius is much larger.

## Verify — never assume

```sh
bash ~/bin/npm-harden-check.sh          # or dotfiles/npm/bin/
bash ~/bin/npm-harden-check.sh --fix
```

Behavioural proof beats reading config: install a package whose newest release
is < 7 days old and confirm it resolves to an *older* version.

```sh
npm view eslint version
npm install eslint --dry-run --no-audit --no-fund | grep '^add eslint'
```

## Related

- Incident analysis: `~/Work/20260817-npm-supply-chain-audit.md`
- Agent skill (macOS + Debian): `~/llm-skills/skills/npm-harden/SKILL.md`
- Dotfiles-side docs: `~/dotfiles/docs/npm-hardening.md`
