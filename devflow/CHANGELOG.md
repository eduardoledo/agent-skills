# Changelog

All notable changes to devflow. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/) and are tagged `devflow-v<version>`.

## [Unreleased]

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

[Unreleased]: https://github.com/eduardoledo/agent-skills/compare/devflow-v1.2.0...HEAD
[1.2.0]: https://github.com/eduardoledo/agent-skills/compare/devflow-v1.1.0...devflow-v1.2.0
[1.1.0]: https://github.com/eduardoledo/agent-skills/compare/devflow-v1.0.0...devflow-v1.1.0
[1.0.0]: https://github.com/eduardoledo/agent-skills/releases/tag/devflow-v1.0.0
