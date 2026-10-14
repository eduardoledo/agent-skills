# Tracker adapter: Azure DevOps

Status: **implemented** (verified against a real organisation: Task work items, custom Actual Time field).

Requires the `az` CLI with the `azure-devops` extension and an `az login` session (see `../setup.md`). Values come from config: `tracker.organization` (e.g. `https://dev.azure.com/MyOrg`), `tracker.project`, optional `tracker.states` / `tracker.fields` overrides.

Always pass `--detect false` to `az boards` commands: auto-detection fails when the git remote is GitHub and prints a warning.

Ticket references in commits/PRs: `AB#<id>`.

## State mapping (defaults; override in `tracker.states`)

| Generic | Azure DevOps (Task) |
|---|---|
| new | `New` |
| triaged | `Triaged` |
| in_progress | `In Progress` |
| testing | `Testing` |
| later | `Client UAT`, `Ready for Release`, `Done`, `Removed`, `Rejected`, `Closed` |

Check the real list once per organisation (setup does this):

```
az rest --method get --resource 499b84ac-1321-427f-aa17-267ca6975798 --uri "<org>/<project>/_apis/wit/workitemtypes/Task/states" --url-parameters "api-version=7.1" --query "value[].name" -o tsv
```

## Fields

| Purpose | Reference name |
|---|---|
| Remaining hours | `Microsoft.VSTS.Scheduling.RemainingWork` |
| Actual hours | `tracker.fields.actual_hours` (default `Custom.ActualTime`; organisations name it differently — find it in setup by listing the type's fields and matching "Actual") |
| Priority | `Microsoft.VSTS.Common.Priority` |
| Parent | `System.Parent` |

Transition rules seen in practice (keep in `tracker.transition_requirements` and extend when a rule error appears):

- `→ testing` requires remaining = 0 **and** actual hours set. Without actual hours the update fails with `TF401320: Rule Error for field Actual Time … Required, InvalidEmpty` and nothing is changed. Ask for the hours before attempting.
- `→ triaged` should carry a comment and remaining hours (team practice, not enforced).

## Operations

`list_assigned_open`

```
az boards query --detect false --wiql "SELECT [System.Id],[System.WorkItemType],[System.State],[Microsoft.VSTS.Common.Priority],[Microsoft.VSTS.Scheduling.RemainingWork],[System.IterationPath],[System.ChangedDate],[System.ChangedBy],[System.Title],[System.Parent] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.State] NOT IN ('Closed','Done','Removed','Rejected') ORDER BY [Microsoft.VSTS.Common.Priority], [System.ChangedDate] DESC" -o json
```

The WIQL must SELECT every field you want back — fields not selected come back empty.

`list_handed_over` — tickets the user handed to testing that are now assigned to someone else. Query recent work items in the testing state changed in the last ~30 days, then keep those whose revision history shows the user as the one who set `testing` (or that carry the user's handoff comment):

```
... WHERE [System.State] = 'Testing' AND [System.AssignedTo] <> @Me AND [System.ChangedDate] >= @Today - 30
az rest --method get --resource 499b84ac-1321-427f-aa17-267ca6975798 --uri "<org>/<project>/_apis/wit/workItems/<id>/updates" --url-parameters "api-version=7.1"
```

If that's too slow, fall back to the ids the user handed over that are recorded in memory/notes.

`get_ticket`

```
az boards work-item show --detect false --id <id> --expand all -o json
```

Description is HTML in `System.Description` (bugs also use `Microsoft.VSTS.TCM.ReproSteps`); strip tags for reading. Relations hold parent/children and attachments (`AttachedFile`). Comments (newest first):

```
az rest --method get --resource 499b84ac-1321-427f-aa17-267ca6975798 --uri "<org>/<project>/_apis/wit/workItems/<id>/comments" --url-parameters "api-version=7.1-preview.4" "$top=10" "order=desc"
```

Images embedded in comments/description are attachment URLs; download with a bearer token and look at them:

```
token=$(az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv)
curl -sL -H "Authorization: Bearer $token" "<attachment url>&api-version=7.1" -o <scratch>/<name>.png
```

`add_comment` — via `--discussion` on update (HTML allowed: `<a href>`, `<code>`, `<br>`):

```
az boards work-item update --detect false --id <id> --discussion "<html>"
```

`transition` / `set_hours` / `assign` — one update call so rules are evaluated together:

```
az boards work-item update --detect false --id <id> --state "Testing" --assigned-to "<email>" --fields "Microsoft.VSTS.Scheduling.RemainingWork=0" "Custom.ActualTime=4" --discussion "<html>" --query "{state:fields.\"System.State\",assigned:fields.\"System.AssignedTo\".displayName}" -o table
```

`assign` needs the person's unique name (email). Resolve a display name by looking at who held the ticket before (`.../updates`, `fields.System.AssignedTo.newValue.uniqueName`) or `az devops user list --query "members[?contains(user.displayName,'<name>')].user.mailAddress"`. Save resolved people to config (`people:`) so you don't resolve them again.

`ticket_url`: `<org>/<project>/_workitems/edit/<id>`

## Linking PRs

`AB#<id>` in PR title/body links automatically only if the Azure Boards ↔ GitHub connection is valid. Check once in setup:

```
az rest --method get --resource 499b84ac-1321-427f-aa17-267ca6975798 --uri "<org>/<project>/_apis/githubconnections" --url-parameters "api-version=7.1-preview" --query "value[].{name:name,valid:isConnectionValid}" -o table
```

If invalid or absent (`tracker.github_link_works: false`), always add the PR URL in the ship/handoff comment. Don't add Hyperlink relations unless the user asks.

## Shell pitfalls

- **PowerShell 5.1:** `$top` in a URL is expanded as a variable — pass query parameters through `--url-parameters` (escape as `` `$top `` if needed). `ConvertFrom-Json` on a CLI array may yield one object containing the array — wrap it: `$items = (& az ... | ConvertFrom-Json)` before `foreach`. Field names with dots need quoting: `$f.'System.State'`.
- **Git Bash:** quote JMESPath field names with escaped double quotes inside `--query`.
- `az` installed during the session may not be on PATH: Windows default `C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd`.
- The Azure DevOps MCP server (`@azure-devops/mcp`) defaults to interactive browser auth and can time out on start; this adapter deliberately uses the CLI.
