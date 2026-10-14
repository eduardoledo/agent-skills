# agent-skills

Personal skills for AI coding agents, in the open [Agent Skills](https://agentskills.io) format (`SKILL.md` + references). They are written to work with any agent that loads skills, with hints for the popular ones (Claude Code, Codex, Gemini CLI, Cursor, Copilot).

| Skill | What it does |
|---|---|
| [`devflow`](devflow/SKILL.md) | Ticket-to-PR admin workflow: tracker (Azure DevOps; Jira and GitHub Issues prepared), GitHub branches/PRs/CI, hand-off to testing and Teams/Slack notification drafts. |

## Install

Clone once, then link each skill into the folder your agent reads.

```bash
git clone https://github.com/eduardoledo/agent-skills.git ~/agent-skills
```

Claude Code (`~/.claude/skills/`):

```bash
# macOS / Linux
mkdir -p ~/.claude/skills && ln -s ~/agent-skills/devflow ~/.claude/skills/devflow
```

```powershell
# Windows (junction, no admin rights needed)
New-Item -ItemType Junction -Path "$HOME\.claude\skills\devflow" -Target "$HOME\agent-skills\devflow"
```

Other agents: link the skill folder into that agent's skills directory (check its docs, e.g. `~/.codex/skills/`, `~/.agents/skills/`).

## Configuration

Each skill that needs configuration ships a `config.example.yml`. The real `config.yml` is created by the skill's setup (e.g. `/devflow setup`), lives next to the skill's `SKILL.md`, may contain secrets and is **gitignored** — never commit it.

## Evals

`<skill>/evals/` holds test prompts and recorded fixtures (fictional data) to check a skill's behaviour in `--dry-run` without touching real services.

## License

[MIT](LICENSE)
