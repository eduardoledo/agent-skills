# Tracker adapter: GitHub Issues

Status: **not implemented** — skeleton only.

If `tracker.type` is `github-issues`, stop before the first tracker operation and tell the user: "The GitHub Issues adapter isn't implemented yet." Offer to implement it together using a real repo to verify against.

Planned approach (to fill in and verify when implementing):

- Transport: `gh issue …` / `gh api` (already required for PRs).
- Ticket references: `#<number>`; use `Fixes #<n>` / `Closes #<n>` in the PR body when the PR should close the issue.
- States — choose in setup:
  - **labels** (works anywhere): `status:triaged`, `status:in-progress`, `status:testing`; `new` = open without a status label; `later` = closed. Hours recorded in a comment (`Remaining: 4h`, `Actual: 3h`).
  - **GitHub Projects v2**: a single-select `Status` field and number fields for hours via `gh project item-edit`; needs the `project` scope (`gh auth refresh -s project`).
- `list_assigned_open`: `gh issue list --assignee @me --state open --json number,title,labels,updatedAt`.
- `assign`: `gh issue edit <n> --add-assignee <login>`.

Operations to implement: `list_assigned_open`, `list_handed_over`, `get_ticket`, `add_comment`, `transition`, `set_hours`, `assign`, `ticket_url`.
