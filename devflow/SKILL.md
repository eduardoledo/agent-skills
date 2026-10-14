---
name: devflow
description: Runs the developer's ticket-to-PR admin workflow across an issue tracker (Azure DevOps today; Jira and GitHub Issues prepared), GitHub and Teams/Slack. Lists and triages tickets, finds or creates the ticket branch, ships (build, commit, push, PR, reviewer, CI watch) and hands off to testing (state, hours, tester, notification draft). Use it whenever the user wants to review/check their tickets, work items or tasks, triage a ticket, start or pick up a ticket, prepare/open a PR for a ticket, move a ticket to Testing or hand it to a tester, or asks things like "revisar mis tickets", "empezar el 3535", "preparar PR", "pasar a testing", "what's next on my board" — even if they don't say "devflow". Also use it for "/devflow setup" or when configuring this workflow for a new repo.
---

# devflow

Automates the administrative work around code changes: tickets, branches, PRs, CI and hand-off. It does **not** implement the change itself — when a phase needs code written or a bug diagnosed, do that as normal work and come back to the flow.

The user is usually a developer working in several repos. Talk to them in their language (from config, default: the language they write in). Text that other people read (ticket comments, PR titles/descriptions, notifications) uses the configured *team language* (default English) and the templates in `references/templates.md`.

## Principles

- **One confirmation per phase.** Gather everything first, then show the full plan of the phase (every command or write, every text that will be posted) and ask once. Never write to a shared system (tracker, GitHub, chat) before that approval. A non-answer ("no preference", dismissed question) is not approval: ask again, or stop.
- **`--dry-run`** (or the user saying "dry run", "simula", "sin escribir"): do all reads, build the plan, show it, write nothing.
- **Never mention AI assistance** (Claude, Codex, "generated with…", Co-Authored-By trailers) in commits, PRs, ticket comments or messages unless the user explicitly asks for it in that request.
- **Never discard local changes** (reset, clean, checkout over modified files, stash drop) without the user explicitly choosing to discard them in that moment; offer stash as the safe default.
- **Prefer what exists.** Before creating a branch or PR, look for one already made for the ticket (a teammate may have started it).
- **Report honestly.** If a build, a tracker update or a check fails, say so with the error; don't paper over it.

## Asking the user

Ask through your agent's interactive question tool when it has one, with 2–4 concrete options and the recommended one first (marked "Recommended"). Otherwise ask in plain text with numbered options and your recommendation. See `references/agents.md` for agent-specific tools (questions, opening a terminal for logins, notifications).

## Configuration

`config.yml` sits next to this file (resolve symlinks/junctions: it lives in the real skill folder). Structure: `config.example.yml`.

- If `config.yml` is missing → run **setup** first (`references/setup.md`), then continue with what the user asked.
- If the current repo (git top-level / origin remote) has no entry under `repos:` → run the **per-repo mini setup** from `references/setup.md`.
- Resolve values as: repo entry → `defaults` → ask. When a default is missing, ask and offer to save it. When the user picks something other than the suggested default, offer "save as new default" (globally or for this repo).
- `config.yml` contains secrets (webhook URLs, tokens). When showing config, mask every value under `secrets:` and any key ending in `token`, `webhook`, `password` or `key` as `****`. Never copy it into a repo, PR, comment or message.
- `state.yml` (same folder, also gitignored) holds what devflow remembers between runs: `last_tickets_view` (timestamp of the last `tickets` run, used to highlight what changed since) and `handed_over` (ticket ids the user handed off, as a fallback for `list_handed_over`). Create it on first need; never put secrets in it.

## Connector check (every run)

Before doing what the user asked, check that every connector selected in config works — tracker, code host (`gh`), notifier — using the checks in `references/setup.md` § Connector check. It is cheap (a few status commands) and catches expired logins and half-finished setups.

- All OK → continue silently.
- Something missing or failing → tell the user which connector and why (e.g. "`az` not logged in", "Slack webhook mode selected but `secrets.slack_webhook` is empty"), and offer to configure it now (setup § Prerequisites / that connector's section). If they configure it, re-check and continue.
- If they skip it, continue only with what still works (e.g. a notifier problem doesn't block `tickets`; a tracker problem does block `triage`/`handoff`) and say what was skipped. Don't mark it as done: the check runs — and asks again — on every run until all selected connectors are properly configured. Record the outcome in `config.yml` → `connectors.<name>.status` (`ok` / `pending` + `reason`), only after the user approves writing config.
- In `--fixtures` mode the check reads `<dir>/connectors.json` instead of running commands (missing file = all OK).

## Tracker and notifier adapters

All tracker work goes through the adapter named by `tracker.type`: read `references/trackers/<type>.md` (`azure-devops`, `jira`, `github-issues`). The flow below uses generic operations; the adapter says how to perform each one:

`list_assigned_open`, `list_handed_over` (tickets the user moved to testing that now sit with someone else), `get_ticket` (fields, state, parent, comments, attachments), `add_comment`, `transition` (state + required fields), `set_hours` (remaining / actual), `assign`, `ticket_url`.

If the adapter file says it is **not implemented**, stop and tell the user which operation is missing; do not improvise against an untested API.

Notifications go through `references/notifiers/<notifier.type>.md` (`teams`, `slack`). Today both only draft the message for the user to send.

Code hosting is always GitHub via `gh`.

## Generic ticket states

| Generic | Meaning |
|---|---|
| `new` | Assigned, not reviewed |
| `triaged` | Reviewed, commented, estimate set |
| `in_progress` | Work started |
| `testing` | Done, with a tester |
| `later` | Anything after testing (UAT, released, done, closed) |

The adapter maps these to real state names and lists the fields each transition needs.

## Deciding what to do

Subcommands: `tickets`, `triage`, `start`, `ship`, `handoff`, `status`, `setup`. With no subcommand:

- **No ticket given** → run `tickets`, then propose the most urgent open ticket (highest priority, then most recently changed) and its next phase.
- **A ticket given** → `get_ticket` and pick by state:

| State | Phase |
|---|---|
| `new` | `triage` |
| `triaged` | `start` |
| `in_progress`, no PR for the ticket branch | `ship` (if the branch has no commits yet, say so: work is still to be done) |
| `in_progress`, open PR | `handoff` |
| `testing` / `later` | `status` only |

Say which phase you picked and why before showing its plan.

## Phases

### tickets

Show three blocks, compact tables:

1. **Assigned to me (open)** — id, type, state, priority, remaining hours, iteration, last change (who/when), title. Highlight what changed since `state.last_tickets_view` (if there is no previous view, highlight changes made by someone else in the last 24 h): new comments, reassignments back to the user, state moved backwards. Fetch the revision history only for highlighted tickets, to say *what* changed. After showing the overview, update `last_tickets_view` (a local file, no confirmation needed; skipped in `--fixtures` mode).
2. **Handed over** — tickets the user moved to testing that are now with someone else: state, assignee, last change.
3. **My open PRs** — number, ticket, review decision/requested reviewers, CI summary. For failing checks apply **CI triage** (below) so inherited failures aren't presented as the user's.

Then propose the next action (as a question).

### triage

1. `get_ticket`: description/repro, comments, attachments (download images and look at them), parent.
2. Diagnose: locate the relevant code/data, form the most likely cause(s). Use sub-agents for broad searches if available. If data needed to confirm isn't available, say what is missing and where it might be (see the repo's `data_repos`).
3. Propose remaining hours with a one-line rationale.
4. Plan: comment (template *triage*), `transition → triaged`, `set_hours remaining`. Ask once, then apply.

### start

1. Find existing work: local and remote branches and PRs whose name or title contains the ticket id (`git fetch --prune`; `git branch -a`; `gh pr list --state all --search <id>`). If found, show author, commits ahead/behind the default branch and the diff summary, and propose using it.
2. Otherwise propose a branch name from `branch.pattern` (`references/templates.md` explains the placeholders): `bugfix` for bugs, `feature` for enhancements, short PascalCase description from the title.
3. Working tree: if dirty, show what's there and offer stash (default) / commit / abort. Update the base branch (`git fetch`; branch from `origin/<default>`).
4. Optional per-repo **test environment** step (`repos.<repo>.test_env`): e.g. make sure the client's data repo is cloned and on the right branch, and point the app's settings at it. Show exactly what changes; never discard local changes in the data repo without explicit consent.
5. Plan: branch create/checkout, `transition → in_progress`, optional test-env changes. Ask once, apply.

### ship

1. Preconditions: on the ticket branch, it has changes or commits not in the base branch. Read the uncommitted diff (`git diff`, `git diff --staged`) and the branch's commits so the commit message and PR text describe the actual change; if a change looks unrelated to the ticket (debug code, local config), ask whether it belongs.
2. **Build/test gate:** run `repos.<repo>.build` (and `test` if set). If it fails, stop and report; no commit/PR. Respect notes in config (e.g. "use full build; incremental leaves stale artefacts").
3. Commit message: `commit.format` (e.g. `PREFIX: <ticket-ref> <imperative summary>`), prefix chosen from `commit.prefixes` by the change type, optional body explaining why. Stage only the files that belong to the change — never stray/untracked artefacts. Don't rewrite teammates' commits that are already pushed (even if they break the format); mention it, and suggest a squash merge if the team uses it.
4. PR: title like the commit subject; body from template *pr*; base = default branch. If an earlier PR for this ticket was closed (e.g. a reviewer asked for changes), say so and mention it in the body ("Replaces #N").
5. Reviewer: suggest the default. **Everyone who authored a non-merge commit on the branch counts as an author** (including the user and teammates who started the branch). If the suggested reviewer is an author, warn and suggest an alternative: people in `people:` and recent reviewers of the user's PRs, excluding all authors. Allow others. Offer "save as default" if a different one is picked.
6. Plan (commit + push + PR + reviewer + ticket comment with the PR link if the tracker can't link GitHub PRs automatically). The PR URL doesn't exist yet: show `{pr_url}` in the planned comment and say it will be filled with the URL `gh pr create` returns — that is part of the approved plan, not a new write needing another confirmation. Ask once, apply.
7. After creating the PR, check CI once (CI triage). Don't poll in a loop; tell the user how to check again (`/devflow status`).

### handoff

1. Preconditions: PR open (or merged) for the ticket. If its review is still pending or changes were requested, say so; hand off anyway unless `handoff.require_approved_pr` is true (then stop and explain).
2. **Actual hours** — never use raw clock time (nights and weekends aren't work). Build candidates from evidence, best first:
   1. The user's own numbers in the tracker: original estimate (the tracker's original-estimate field if set, else the first remaining value recorded at triage) minus the latest remaining hours they set, plus time logged elsewhere if the tracker has it.
   2. Working time while `in_progress`: from entering `in_progress` (tracker history) — or the branch's first commit if earlier — to now, counting only `work_hours` on `work_days` in `timezone` (config; defaults Mon–Fri 09:00–17:30 in the system timezone).
   Offer the best candidate as recommended, the other as an alternative, and "another value". Show how each was computed in one line. If there's no evidence at all, ask without a suggestion.
3. Tester: suggest the default for the repo; if the default tester is one of the branch's authors, warn (someone else should test); if they are also the PR's reviewer, mention it (allowed, but the user may prefer two people); allow others; offer to save.
4. Plan: comment (template *handoff*: what changed, branch, PR, how to test), `transition → testing` with remaining 0 and actual hours (and any other field the adapter lists as required), `assign` tester, notification draft (notifier) addressed to the tester. Ask once, apply.
5. Show the notification draft ready to paste and remind the user to send it.

### status

Ticket state/assignee, branch, PR (review, mergeability), CI triage. No writes.

## CI triage

For each failing check on a PR: compare with the base branch. If the PR's test report says the failures are unchanged versus base (e.g. "2 ❌ ±0") or the same check/tests fail on the latest base commit, label them **inherited** and name the tests; otherwise label them **new** and show the failing tests/log excerpt. Only new failures block a hand-off recommendation.

## Dry run and fixtures

`--dry-run` stops before every write and prints the plan in this shape:

```
Phase: <phase> — <ticket ref> (<why this phase>)
Connectors: <ok | pending: …>
Reads done: <short list>
Planned writes:
  1. <system>: <command or action>
     <exact text to be posted, if any>
  2. ...
Questions for the user: <defaults used / choices needed>
```

For read-only phases (`tickets`, `status`) a single line is enough — `Connectors: … · Planned writes: none` — placed after the overview.

`--fixtures <dir>` (used by the evals): do not call `az`, `gh`, builds or git remotes. Read the recorded responses from `<dir>` instead (file names are explained in `evals/fixtures/README.md`), treat `<dir>/config.fixture.yml` as the configuration, `<dir>/context.json` as who/where/when you are, and imply `--dry-run`. A missing fixture file means that call returns nothing.
