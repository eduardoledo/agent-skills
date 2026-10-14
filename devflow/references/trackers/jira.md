# Tracker adapter: Jira

Status: **not implemented** — skeleton only.

If `tracker.type` is `jira`, stop before the first tracker operation and tell the user: "The Jira adapter isn't implemented yet; it needs a real Jira project to be built and verified against." Offer to implement it with them if they have a Jira site and an API token available.

Planned approach (to fill in and verify when implementing):

- Transport: Jira Cloud REST API v3 with `curl`, basic auth `email:api_token` (token in `config.yml` → `secrets.jira_api_token`), base URL in `tracker.site` (e.g. `https://mycompany.atlassian.net`). Alternatively Atlassian's official CLI (`acli`) if installed.
- Ticket references: the issue key (`PROJ-123`), which Jira's GitHub integration links when it appears in branch names, commit messages and PR titles.
- `list_assigned_open`: JQL `assignee = currentUser() AND statusCategory != Done ORDER BY priority, updated DESC` via `/rest/api/3/search/jql`.
- `transition`: `GET /rest/api/3/issue/{key}/transitions` to find the transition id for the target status, then `POST` it; required fields come back in the transition screen metadata.
- Hours: `timetracking.remainingEstimate` and worklogs (`POST /issue/{key}/worklog`) for actual time.
- State mapping: per project workflow — record it in `tracker.states` during setup.

Operations to implement: `list_assigned_open`, `list_handed_over`, `get_ticket`, `add_comment`, `transition`, `set_hours`, `assign`, `ticket_url`.
