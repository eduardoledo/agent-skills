# Agent-specific hints

devflow is written for any agent that reads `SKILL.md` skills. Use the closest match below; when your agent isn't listed or lacks a capability, use the fallback.

| Capability | Claude Code (CLI / desktop) | Other agents (Codex, Gemini CLI, Cursor, Copilot…) | Fallback |
|---|---|---|---|
| Ask the user | `AskUserQuestion` tool: up to 4 questions, 2–4 options each, recommended option first with "(Recommended)" | Use the agent's structured question / confirmation UI if it has one | Plain text with numbered options and your recommendation; wait for the reply |
| Run an interactive login (`az login`, `gh auth login`) | Desktop app: open a terminal tab (`run_in_terminal` / terminal tools) so the user completes it; CLI: ask the user to run it with `!` prefix in the prompt | Ask the user to run it in their terminal | Print the exact command and wait for "done" |
| Long or broad code searches | Spawn an `Explore` / general-purpose sub-agent | Agent's sub-agent/task feature if any | Search directly with grep/ripgrep |
| Show a diff / file to the user | Desktop app: show the diff pane / open the file | Agent's file viewer | Print paths as clickable references |
| Track the PR / CI after creation | Desktop app PR tools (bind PR, read status) | — | `gh pr checks <n>` when the user asks for status |
| Background work | `run_in_background` on shell tools | Agent's background jobs if any | Run in the foreground |

Notes

- Shells differ: on Windows, PowerShell 5.1 and Git Bash behave differently (quoting of `$`, JSON parsing). The tracker adapters show robust forms; prefer letting the CLI format output (`--query … -o tsv/table`) over parsing JSON in the shell.
- A freshly installed CLI may not be on the agent session's PATH until the agent restarts; call it by full path meanwhile (see `setup.md`).
