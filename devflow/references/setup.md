# Setup

Two modes:

- **Full setup** — `/devflow setup`, or automatically when `config.yml` doesn't exist.
- **Per-repo mini setup** — automatically the first time devflow runs in a repo that has no entry under `repos:` (key = `owner/name` of the `origin` remote).

Principles: detect everything that can be detected and show it pre-filled for confirmation; ask only what can't be detected; never assume fixed directories (find repos from the current repo, its sibling folders and the code host); group questions (≤ 4 per round in agents with a question tool). Write `config.yml` only after showing the final file (secrets masked) and getting a yes.

## 1. Prerequisites

Check only what the chosen options need:

| Need | Check | Required when |
|---|---|---|
| `git` | `git --version` | always |
| `gh` | `gh --version`, `gh auth status` | always (PRs, CI) |
| `az` + extension `azure-devops` | `az version`, `az extension show --name azure-devops` | tracker = azure-devops |
| `curl` | `curl --version` | tracker = jira (future) |

If something is missing, offer to install it with the first available package manager below. Show the exact command and wait for confirmation of each install. If no manager is available, offer the official installer / script.

| OS | Detect (in order) | GitHub CLI | Azure CLI |
|---|---|---|---|
| Windows | `winget` → `scoop` → `choco` | `winget install -e --id GitHub.cli` · `scoop install gh` · `choco install gh` | `winget install -e --id Microsoft.AzureCLI` · `scoop install azure-cli` · `choco install azure-cli` |
| macOS | `brew` | `brew install gh` | `brew install azure-cli` |
| Debian/Ubuntu | `apt` | GitHub's apt repo (`cli.github.com/packages`), then `sudo apt install gh` | Microsoft's script `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| Fedora/RHEL | `dnf` | `sudo dnf install gh` | Microsoft's repo, then `sudo dnf install azure-cli` |
| openSUSE | `zypper` | `sudo zypper install gh` | Microsoft's repo, then `sudo zypper install azure-cli` |
| Arch & derivatives | `pacman` → `yay` / `paru` (AUR) | `sudo pacman -S github-cli` | `sudo pacman -S azure-cli` if in the official repos, else `yay -S azure-cli` / `paru -S azure-cli` |
| Any (fallback) | — | release binaries from github.com/cli/cli | `pipx install azure-cli` |

Package names drift; if the install fails with "package not found", search the manager (`winget search`, `pacman -Ss`, `yay -Ss`) and propose the match.

Then: `az extension add --name azure-devops` (Azure DevOps only).

**PATH after install:** the agent's session usually keeps the old PATH. Call the new CLI by its full path for the rest of the session and tell the user a restart of the agent picks it up. Typical paths: Windows `C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd`, `C:\Program Files\GitHub CLI\gh.exe`; Linux/macOS `/usr/bin`, `/usr/local/bin`, `/opt/homebrew/bin`. Confirm with `where`/`which` or by checking those paths.

**Logins** open a browser and must be completed by the user (see `agents.md` for how to hand them a terminal):

- `gh auth login` (or `gh auth login -h github.com` to add another account; `gh auth switch` to change the active one). Make sure the active `gh` account is the one that can access the repos in question.
- **Several GitHub accounts** (e.g. work + personal): answering "Authenticate Git with your GitHub credentials? Y" during a second `gh auth login` can make git's credential manager store that account for all of github.com, so `git fetch` on the other account's private repos fails with "Repository not found". Fix by letting git follow the active gh account: `gh auth setup-git` (writes `credential.https://github.com.helper` to the global git config — ask first). Then `gh auth switch` changes both.
- `az login` (add `--allow-no-subscriptions` if the account has no Azure subscriptions).

Verify afterwards: `gh auth status`, `az account show --query user.name -o tsv`, `az devops configure --list`.

## Connector check

Run at the start of every devflow run (see SKILL.md). One line per selected connector; stop at the first failing check of each connector.

| Connector | Checks (all must pass) | Typical fix |
|---|---|---|
| `github` (always) | `gh auth status` exits 0 · active account can see the current repo: `gh repo view <owner/name> --json name` | `gh auth login` / `gh auth switch` (user runs it) |
| `azure-devops` | `az version` · `az extension show --name azure-devops` · `az account show` · `tracker.organization` and `tracker.project` set · a cheap read works: `az boards query --detect false --wiql "SELECT [System.Id] FROM WorkItems WHERE [System.Id] = 1" --org <org> --project <project>` | install / `az extension add` / `az login` / fill org+project |
| `jira` | adapter not implemented → report as `pending: not implemented` (doesn't block other connectors) | — |
| `github-issues` | adapter not implemented → `pending: not implemented` | — |
| `teams` / `slack`, mode `draft` | nothing to check (always OK) | — |
| `teams` / `slack`, other modes | the mode is implemented (today: no → fall back to draft, report `pending`) · its secret is non-empty | set the secret, or switch mode to `draft` |

Report pending connectors in one short block and offer to fix them now, one question per connector with options *Configure now* / *Skip this time* / *Switch to an alternative* (e.g. notifier mode `draft`). Mark *Configure now* as recommended, except when configuring wouldn't help yet (the selected mode or adapter isn't implemented) — then recommend the working alternative. Show whatever still works (e.g. the PR block when only the tracker is down) after the user answers, not before. Fixing a connector reuses the matching part of § Prerequisites or § Full setup. A skipped connector stays `pending` and is asked about again next run — there is no "don't ask again" except changing the selection itself (e.g. choosing notifier `none`).

In `--fixtures` mode read `<dir>/connectors.json` — `{ "<connector>": { "ok": true|false, "reason": "..." } }` — instead of running the checks.

## 2. Full setup questions

Detect first, then ask in rounds:

1. **Tracker** — Azure DevOps / Jira / GitHub Issues (Jira and GitHub Issues are skeletons: say so). For Azure DevOps detect organisation and project from `az devops configure --list` or from ticket references (`AB#`) in recent commits; confirm. Then:
   - Fetch the task type's states and fields (see `trackers/azure-devops.md`) and confirm the state mapping and the actual-hours field.
   - Check the Boards ↔ GitHub connection (sets `tracker.github_link_works`).
2. **Notifier** — Teams / Slack / none; mode `draft` (others not implemented yet).
3. **Conventions** — infer from the current repo's history and show examples:
   - Commit format and prefixes (`git log --format=%s -50`).
   - Branch pattern (`git branch -r`).
   - Team language (language of recent PR titles/bodies: `gh pr list --state all --limit 10 --json title,body`).
4. **People** — default reviewer and tester. Suggest frequent reviewers of the user's recent PRs (`gh pr list --author @me --state all --json reviewRequests,reviews`) and recent assignees of tickets the user handed over. Leave empty if the user prefers to be asked each time.
5. **Language** — language to talk to the user (default: the one they write in) and team language for posted texts (default English).
6. **Working time** — timezone (detect from the system), work days and hours, used only to suggest actual hours; and whether hand-off requires an approved PR (default no).

Finish with the connector check: every connector selected above must pass before setup reports "done"; anything left is recorded as `pending` and asked about on the next runs.

Then run the per-repo mini setup for the current repo.

## 3. Per-repo mini setup

1. **Build/test commands** — detect from the repo: `package.json` scripts, `*.sln` / `*.csproj` (dotnet), `*.dproj` (Delphi: MSBuild with RAD Studio's `rsvars.bat`), `pom.xml`, `build.gradle`, `Makefile`, `Cargo.toml`, `pyproject.toml`, CI workflow files (`.github/workflows/*.yml` show the canonical build). Propose the command; ask for notes (e.g. "use a full build").
2. **Data repos per client** (optional) — if the app loads external data/config repos, list candidates:
   - Sibling folders of the repo that are git repos (`../*/.git`).
   - Repos in the same GitHub owner whose names suggest data/config (`gh repo list <owner> --limit 200 --json name`, e.g. `data-*`, `*-config`).

   Ask which client/environment maps to which repo and branch; offer to clone a missing one next to the current repo.
   - Clone problems with Git LFS: if `smudge filter lfs failed … Object does not exist on the server` appears, check out with `GIT_LFS_SKIP_SMUDGE=1` and then `git lfs pull`; report the objects that stay as pointers.
3. **Test environment step** (optional) — what has to change to run the app against a client's data, e.g. a settings/profile file pointing to the data folder. Record the file, the key and the value template. devflow shows the change and asks before applying; it never discards local changes in data repos without explicit consent.
4. **Overrides** — reviewer/tester/branch pattern different from the defaults for this repo.

## 4. Writing config.yml

Show the whole file with secrets masked, ask, then write it next to `SKILL.md` (real folder, not the link). It holds secrets, so:

- It is listed in the skill repo's `.gitignore` — check that before writing, and add it if missing.
- Never print secret values back; mask as `****`.
- If the skill folder is ever packaged or shared, `config.yml` must be left out.
