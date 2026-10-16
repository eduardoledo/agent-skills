# Fixtures

Recorded (fictional) responses used with `--fixtures <scenario dir>`. In fixture mode devflow must not call `az`, `gh` or any remote; it reads these files instead, treats `config.fixture.yml` in the scenario folder as its configuration, and runs as `--dry-run`. The current user is the `me` entry in `context.json`; "now" is `context.json.now`.

| File | Stands for |
|---|---|
| `config.fixture.yml` | devflow configuration (not `config.yml`, which is gitignored) |
| `context.json` | current user, current repo, now |
| `az_assigned_open.json` | `list_assigned_open` (az boards query output) |
| `az_handed_over.json` | `list_handed_over` |
| `az_ticket_<id>.json` | `get_ticket` (az boards work-item show --expand all) |
| `az_updates_<id>.json` | work item revision history (`.../updates`) |
| `gh_pr_list.json` | `gh pr list --author @me --state open --json number,title,headRefName,reviewRequests,reviewDecision` |
| `gh_pr_list_search_<id>.json` | `gh pr list --state all --search <id> --json ...` |
| `gh_pr_checks_<n>.json` | `gh pr checks <n> --json name,state,link` |
| `gh_pr_comments_<n>.json` | PR comments (e.g. test-result bot) |
| `git_branches.txt` | `git branch -a` |
| `git_log_<branch>.txt` (`/` in the branch name replaced by `_`) | `git log origin/main..<branch> --format='%h|%an|%ae|%aI|%s'` |
| `git_status.txt` | `git status --short` |
| `build_result.txt` | outcome of running the repo's build command |
| `git_diff.txt` | `git diff` of uncommitted changes |
| `connectors.json` | result of the connector check (`{name: {ok, reason}}`); missing = all OK |
| `state.yml` | devflow's state file (`last_tickets_view`, `last_update_check`, `update_available`, …); missing = first run |
| `skill/*` | the skill's own git repo for the update check (`version.txt`, `tags.txt`, `log.txt`, `CHANGELOG.md`, `diff.txt`, `status.txt`, `ahead.txt`; see `references/updates.md` § Fixtures); no `skill/` = no update |

`context.json` may also carry `"agent"` (e.g. `claude-code`) for agent-specific syntax such as suggested commands.
