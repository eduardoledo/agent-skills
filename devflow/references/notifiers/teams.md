# Notifier: Microsoft Teams

Modes (`notifier.mode`):

| Mode | Status | What it does |
|---|---|---|
| `draft` (default) | implemented | Writes the message for the user to paste into Teams. |
| `graph` | implemented, not yet released | Sends an Adaptive Card through Microsoft Graph as the signed-in user: a 1:1 chat with the recipient (`dm`) or a channel post that @mentions them (`channel`). |
| `webhook` | not implemented | Would POST to a Teams Workflows "when a webhook request is received" URL (`secrets.teams_webhook`). |

If a non-implemented mode is configured, fall back to `draft` and say so.

## draft

Produce the message from template *notification* (`../templates.md`) in the team language, addressed to the recipient by first name, short enough to read in a chat bubble: what's ready, ticket link, PR link, the one thing to check first. Show it in a code block so it copies cleanly, and end with a reminder: "Send this to <name> on Teams."

Reading Teams (e.g. to see whether the tester replied) isn't part of devflow; if the agent has a Microsoft 365 integration, the user can use it directly.

## graph

Delegated Microsoft Graph through the **Graph PowerShell SDK** (Microsoft's own app "Microsoft Graph Command Line Tools" — no app registration of ours). Everything goes through `../../scripts/teams-graph.ps1` (run it with `powershell -NoProfile -File` on Windows PowerShell 5.1 or `pwsh -NoProfile -File`); it prints JSON and exits 1 with the reason on failure.

**Scopes** (all requested in one sign-in, so switching `dm` / `channel` needs no new consent): `Chat.Create`, `ChatMessage.Send`, `User.ReadBasic.All`, `ChannelMessage.Send`, `Team.ReadBasic.All`, `Channel.ReadBasic.All`. All delegated: devflow can only do what the user could do in Teams, while they are signed in; it never reads chats.

**Prerequisites and sign-in:** `setup.md` § Graph PowerShell. Sign-in: `Connect-MgGraph -Scopes Chat.Create,ChatMessage.Send,User.ReadBasic.All,ChannelMessage.Send,Team.ReadBasic.All,Channel.ReadBasic.All -NoWelcome`, run by the user in a terminal (browser / Windows account picker). The token is cached for the user.

**Config:**

```yaml
notifier:
  type: teams
  mode: graph
  graph:
    target: dm                 # dm | channel — default dm
    team_id: null              # channel target: chosen in setup from the user's teams
    channel_id: null
    channel_name: null         # "Team / Channel", for display only
repos:
  <owner/name>:
    notifier_target: null      # dm | channel — overrides notifier.graph.target for this repo
people:
  <x>:
    teams_id: null             # Entra user id, saved after the first lookup (with the user's yes)
```

### Connector check

`teams-graph.ps1 -Action check`: module installed, `Get-MgContext` holds every scope above, `GET /me` works (catches an expired token). On failure report the reason, offer a terminal to run the `Connect-MgGraph` line (`../agents.md`), then re-check. A sign-in ending in "Need admin approval" means the tenant requires admin consent: record `pending: admin consent required` and offer the IT request below. In `--fixtures` mode read `connectors.json` (`teams`) instead.

### Setup (`setup notifier`, mode graph)

1. Prerequisites and sign-in as above; `-Action check` must pass.
2. Target: `dm` (recommended) or `channel`. For `channel`: `-Action teams`, then `-Action channels -TeamId <id>`, and let the user pick; save `team_id`, `channel_id`, `channel_name`.
3. Optional test: offer to send a test card ("devflow test — please ignore") to a person or the configured channel the user chooses; only after an explicit yes.
4. Usual § 5 flow: one diff of `config.yml`, write after a yes.

### Recipient

The tester (or whoever the notification is for): use `people.<x>.teams_id` if set; else `-Action resolve -Email <people.<x>.tracker>` and, as part of the phase plan, propose saving the id as `people.<x>.teams_id`. If it can't be resolved, ask for their Teams email and resolve that.

### The card

Adaptive Card 1.4 in the team language, built from template *notification*:

```json
{
  "type": "AdaptiveCard", "version": "1.4",
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "body": [
    { "type": "TextBlock", "text": "Ready for testing: {ref} — {short title}", "weight": "Bolder", "size": "Medium", "wrap": true },
    { "type": "TextBlock", "text": "Hi {tester first name}, this is ready for you to test.", "wrap": true },
    { "type": "FactSet", "facts": [
      { "title": "Ticket", "value": "{ref}" },
      { "title": "Branch", "value": "{branch}" },
      { "title": "PR", "value": "#{pr_number} ({review state})" }
    ] },
    { "type": "TextBlock", "text": "To check first: {the one scenario that matters most}", "wrap": true }
  ],
  "actions": [
    { "type": "Action.OpenUrl", "title": "Open ticket", "url": "{ticket_url}" },
    { "type": "Action.OpenUrl", "title": "Open PR", "url": "{pr_url}" }
  ]
}
```

`summary` (the notification preview): `{ref} ready for testing`.

The card never contains `<at>` tags: in a channel post the script puts the @mention in the message body, next to the card. The greeting in the card uses the plain first name.

### Sending (in `handoff`)

- Target: `repos.<repo>.notifier_target` → `notifier.graph.target` → `dm`. The plan shows the target (person, or `channel_name` with the @mention) and the full card; the user can switch target there.
- It is part of the phase's single confirmation and goes **last**, after the tracker writes.
- Write the payload (`target`, `userId`, `userName`, `teamId`/`channelId` for channels, `card`, `summary`) to a temp file and run `-Action send -PayloadFile <file>`; delete the file afterwards. Report the message's `webUrl` if returned.
- **On failure:** show the error and offer *Reconnect and retry* (terminal with `Connect-MgGraph`, then `check` and `send` again) / *Give me the draft*. If it still fails or the user picks the draft, show the *draft* version of the message to paste, and record `connectors.teams: pending` with the reason (with the user's yes to write config).
- In `--fixtures` / `--dry-run`: show the planned send (target, recipient id or "to be resolved", card); send nothing.

### IT request (admin consent)

When consent is required, offer this text for the user to send to their IT (team language):

```
Could you grant tenant-wide admin consent for Microsoft's first-party app
"Microsoft Graph Command Line Tools" for these DELEGATED Microsoft Graph permissions?

- Chat.Create, ChatMessage.Send – start a 1:1 chat and send a message as me
- User.ReadBasic.All – look up a colleague's basic profile to address the message
- ChannelMessage.Send, Team.ReadBasic.All, Channel.ReadBasic.All – post to a channel I'm a member of and list my teams/channels

Purpose: when I hand a ticket over to testing, a script I run posts a short card to the tester
(ticket, branch and PR links) from my own account. Delegated only: it acts as me, while I'm
signed in, and can't do anything I couldn't do in Teams. It doesn't read chats or messages.
```
