# Notifier: Microsoft Teams

Modes (`notifier.mode`):

| Mode | Status | What it does |
|---|---|---|
| `draft` (default) | implemented | Writes the message for the user to paste into Teams. |
| `webhook` | not implemented | Would POST to a Teams Workflows "post to a channel when a webhook request is received" URL (`secrets.teams_webhook`). Channel only, not direct messages. |
| `graph` | not implemented | Would send chat messages via Microsoft Graph (`Chat.ReadWrite` / `ChannelMessage.Send`); needs an Entra app registration approved by a tenant admin. |

If a non-implemented mode is configured, fall back to `draft` and say so.

## draft

Produce the message from template *notification* (`../templates.md`) in the team language, addressed to the recipient by first name, short enough to read in a chat bubble: what's ready, ticket link, PR link, the one thing to check first. Show it in a code block so it copies cleanly, and end with a reminder: "Send this to <name> on Teams."

Reading Teams (e.g. to see whether the tester replied) isn't part of devflow; if the agent has a Microsoft 365 integration, the user can use it directly.
