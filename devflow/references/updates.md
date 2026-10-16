# Updates

devflow updates itself from the git repo it was cloned from. Releases are git tags `devflow-v<semver>` (e.g. `devflow-v1.2.0`) with a matching section in `CHANGELOG.md`; untagged commits on the default branch are never offered.

## Where the skill repo is

Resolve the real skill folder (follow symlinks/junctions), then `git -C <skill dir> rev-parse --show-toplevel`. The repo may hold several skills: only tags `devflow-v*` and changes under the skill's folder count. Not a git clone, or no `origin` remote → updates aren't available (silent in the periodic check; `update` says so and suggests reinstalling from a clone, see the repo README).

## When to check

- Periodic: at the end of a run (any subcommand except `help`) when `updates.check_every` is due: `daily` = `state.last_update_check` is not today, `weekly` = 7+ days ago, `never` = no periodic check. Missing setting = `daily`.
- On demand: `update` / `update --check`, always.

## Check (read-only)

1. `git -C <repo> fetch --tags --quiet origin` — a network read, no confirmation. On failure: periodic → skip silently and don't touch `last_update_check`, so it retries next run; `update` → report the error.
2. Current version: `git -C <repo> describe --tags --match "devflow-v*" --abbrev=0`; if there's no tag, the first `## [x.y.z]` heading of the local `CHANGELOG.md`; else `unknown`.
3. Latest release: `git -C <repo> tag -l "devflow-v*" --sort=-v:refname`, first entry. Newer than current, and not already contained in `HEAD` (`git merge-base --is-ancestor <tag> HEAD` fails) → update available.
4. Save in `state.yml`: `last_update_check: <now>`, `update_available: { version: <x.y.z>, commits: <n> } | null`. `n` = `git rev-list --count HEAD..<tag> -- devflow/`.

## Summary shown to the user

In the user's language, short, for a human:

```
devflow <current> → <new> · <n> commits

<CHANGELOG sections between the two versions: Added / Changed / Fixed, as written>

What it means for you:
- <agent's explanation from the diff of SKILL.md and references/ — behaviour you'll notice, new commands, changed defaults>

Not in the changelog: <commit subjects in the range without a matching entry, or omit the line>

Action needed: <config migration, see below, or omit>
```

Read the CHANGELOG from the target tag (`git show <tag>:devflow/CHANGELOG.md`), the commits with `git log --format='%h %s' HEAD..<tag> -- devflow/`, and the diff with `git diff HEAD <tag> -- devflow/SKILL.md devflow/references devflow/config.example.yml`.

## Applying (one confirmation)

Inspect the local repo first and show the plan that applies:

| Local state | Plan |
|---|---|
| Clean, no local commits | `git merge --ff-only <tag>` |
| Uncommitted changes (`git status --porcelain`) | List the files. `git stash push -u -m "devflow-update"` → update → `git stash pop` |
| Local commits not on `origin` (`git rev-list @{u}..HEAD`, or not contained in the tag) | Explain they will be replayed on top. `git rebase <tag>` |
| Both | Stash → rebase → pop |

Ask once ("Apply now" recommended / "Not now"). "Not now" leaves `update_available` in place; it is offered again at the next due check, and `help` keeps showing it.

If any step conflicts or fails: stop, show `git status`, say exactly where things are (e.g. "rebase stopped at commit X", "your changes are still in stash@{0}") and how to continue or abort (`git rebase --abort`, `git stash pop`). Never `reset`, `checkout --` or drop the stash; never discard anything. Local `config.yml` and `state.yml` are gitignored and untouched by the update.

On success: set `update_available: null`, report the new version, then run the config migration.

## Config migration

Compare the keys of the new `config.example.yml` with `config.yml`, structurally (top-level sections and their keys; skip the example entries under `repos:` and `people:`).

- Keys in the example and missing in `config.yml` → propose adding them with the documented default (from the example's comment or the CHANGELOG); ask for values that have no sensible default.
- Keys in `config.yml` gone from the example → mention them as possibly renamed/obsolete (check the CHANGELOG); don't delete without a yes.

Show the resulting diff of `config.yml` with secrets masked and write only after a yes. Nothing to migrate → say nothing.

## Fixtures

In `--fixtures <dir>` mode, `<dir>/skill/` replaces the git calls:

| File | Stands for |
|---|---|
| `skill/version.txt` | current version (step 2) |
| `skill/tags.txt` | `git tag -l "devflow-v*" --sort=-v:refname` after fetch |
| `skill/log.txt` | `git log --format='%h %s' HEAD..<tag> -- devflow/` |
| `skill/CHANGELOG.md` | `CHANGELOG.md` at the target tag |
| `skill/diff.txt` | diff of SKILL.md, references and config.example.yml between HEAD and the tag |
| `skill/status.txt` | `git status --porcelain` of the skill repo |
| `skill/ahead.txt` | local commits not on origin, one per line (empty/missing = none) |

No `skill/` folder → no update available. Imply `--dry-run`: show the summary and the apply plan, apply nothing, don't write `state.yml`.
