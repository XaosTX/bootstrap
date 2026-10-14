# Bootstrap Branch Merge -- 2026-07-23

## What happened

Two divergent bootstrap branches needed reconciling:

- **`feat/linux-setup`** -- modular refactor with `lib/`, `groups/`, `profiles/`, cross-platform `setup.sh`
- **`feat/mbp-2607231229`** -- MBP-specific tooling, skill renames, devin-kit

## Resolution

Created `feat/merged-setup` off `feat/linux-setup` (better architecture base), then applied MBP additions selectively.

### Included from MBP

- Skill renames: `handoff` -> `my-handoff`, `resume` -> `my-resume` (avoids Devin CLI built-in conflict)
- Path fix: `~/Work/llm-handoffs/` -> `~/Life/llm-chat/llm-handoffs/` (was a mismatch between handoff and resume)
- asdf plugins: `asdf-azure-sdk.sh`, `asdf-k8s.sh`, `asdf-pnpm.sh`
- brew additions: glean-cli merged into `llm/Brewfile`, security, python-dev entries
- `macos/.vscode/settings.json`
- `tools/ssh/rust-lang.sh`

### Excluded from MBP

- `devin-kit/` -- dropped; superseded by `~/llm-skills/` single-source-of-truth plan

### Consolidated

- `tools/brew/llms/` (mbp) merged into `tools/brew/llm/` (linux) -- single Brewfile

## Branch state

```
master (d77ee85)
  |
  +-- feat/linux-setup (e5ea101) -- 2 commits
  |
  +-- feat/merged-setup (a7cfdbe) -- 3 commits (linux + mbp merge)
  |
  +-- feat/mbp-2607231229 (2c11085) -- 1 commit (can be deleted)
```

## Next steps

- Push `feat/merged-setup`, open MR to master
- Delete `feat/mbp-2607231229` and `feat/linux-setup` after merge
- Continue `~/llm-skills/` consolidation (see `llm-handoffs/20260723-1231-llm-skills-consolidation.md`)
