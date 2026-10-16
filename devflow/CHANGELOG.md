# Changelog

All notable changes to devflow. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/) and are tagged `devflow-v<version>`.

## [Unreleased]

### Added
- Teams notifier mode `graph`: sends the hand-off notification as you through Microsoft Graph, as an Adaptive Card in a DM to the tester or a channel post that @mentions them (`notifier.graph.target`, per-repo `notifier_target`). Uses the Graph PowerShell SDK (`Microsoft.Graph.Authentication` only) and `scripts/teams-graph.ps1`. Needs delegated permissions that many tenants only allow with admin consent; devflow detects it and offers the request text for IT. Falls back to the draft when sending fails. New config keys: `notifier.graph.*`, `repos.<repo>.notifier_target`, `people.<x>.teams_id`.
- Setup prerequisites and connector check for mode `graph`.

## [1.3.0] - 2026-10-16

### Added
- `setup <section> [<section>...]` to reconfigure only part of the setup: `prereqs`, `tracker`, `notifier`, `conventions`, `people`, `language`, `work`, `updates`, `repo`, `connectors`. Current values are offered as the answers, dependent settings come along (a new tracker type re-asks states and fields), several sections give one diff and one confirmation, and affected connectors are re-checked.
- `setup repo <owner/name>` to edit another repo's entry.
- `help setup` lists the sections with their current values.

### Changed
- `setup` with an existing configuration shows a menu of sections instead of starting over.
- `help` points to `setup connectors` when a connector is pending.

## [1.2.0] - 2026-10-16

### Added
- `help` and `help <subcommand>`: read-only overview of the commands and flags, plus the current context (repo, stored connector status, defaults, last `tickets` run, version). Ends with the command to run when setup is missing. Also triggered by `-h`, `--help`, "ayuda devflow" and unknown subcommands (which suggest the closest one).
- `setup repo`: runs only the per-repo mini setup; edits the existing entry when the repo is already configured.
- `update` and `update --check`, plus a periodic check at the end of a run (`updates.check_every`: daily, weekly or never). Shows the new changelog entries with an explanation of what changes for you, handles local changes (stash / rebase, always confirmed) and proposes config migrations.
- `CHANGELOG.md` and release tags `devflow-v*`.

### Changed
- The connector check and the automatic setup no longer run for `help`.

## [1.1.0] - 2026-10-14

### Added
- Fill the repository's own PR template when present.
- Per-day `work_hours` for actual-time estimates.
- Generic `ini-key` / `json-key` test environment step with per-client `match` / `value`.

### Changed
- Setup documents the multi-account `gh` / git credential pitfall.

## [1.0.0] - 2026-10-14

### Added
- Ticket-to-PR workflow: `tickets`, `triage`, `start`, `ship`, `handoff`, `status`, `setup`.
- Tracker adapters: Azure DevOps (implemented), Jira and GitHub Issues (skeletons).
- GitHub PR and CI flow with CI triage, Teams/Slack notification drafts.
- Setup with prerequisite and connector checks; dry-run evals with fictional fixtures.

[Unreleased]: https://github.com/eduardoledo/agent-skills/compare/devflow-v1.3.0...HEAD
[1.3.0]: https://github.com/eduardoledo/agent-skills/compare/devflow-v1.2.0...devflow-v1.3.0
[1.2.0]: https://github.com/eduardoledo/agent-skills/compare/devflow-v1.1.0...devflow-v1.2.0
[1.1.0]: https://github.com/eduardoledo/agent-skills/compare/devflow-v1.0.0...devflow-v1.1.0
[1.0.0]: https://github.com/eduardoledo/agent-skills/releases/tag/devflow-v1.0.0
