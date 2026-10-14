# Notifier: Slack

Modes (`notifier.mode`):

| Mode | Status | What it does |
|---|---|---|
| `draft` (default) | implemented | Writes the message for the user to paste into Slack. |
| `webhook` | not implemented | Would POST JSON `{"text": …}` to an Incoming Webhook (`secrets.slack_webhook`). Fixed channel. |
| `connector` | not implemented | Would use the agent's Slack integration (connector/MCP) to DM the recipient; requires it to be connected and each send confirmed. |

If a non-implemented mode is configured, fall back to `draft` and say so.

## draft

Same content as Teams (template *notification* in `../templates.md`). Mention the recipient as `@Name` so the user can turn it into a real mention, and use plain URLs (pasted text doesn't render `<url|text>`). Show it in a code block and remind: "Send this to <name> on Slack."
