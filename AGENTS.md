# Working on this repo

Personal skills in the Agent Skills format. Each skill lives in its own folder (`<skill>/SKILL.md`, `references/`, `evals/`).

## Changelog and releases

- Every change to a skill adds an entry under `## [Unreleased]` in `<skill>/CHANGELOG.md` (Added / Changed / Fixed / Removed), written for the people who use the skill: what they will notice, not how it was done.
- Releasing: move the Unreleased entries to `## [x.y.z] - YYYY-MM-DD` (semver: new behaviour = minor, fixes = patch, breaking config or commands = major), update the compare links at the bottom, commit, and tag `<skill>-v<x.y.z>` on that commit. Push the commit and the tag. Installed copies only offer tagged releases as updates.
- A change that adds, renames or removes keys in `config.example.yml` says so in the changelog entry, so the update's config migration can explain it.

## Rules

- Never commit `config.yml`, `state.yml` or anything with real company data, people, URLs or secrets. Fixtures are fictional (Contoso, Alice, Bob). Search the diff for real names before pushing.
- Commit subjects: `PREFIX: summary` (ENH, FIX, DOC, TEST, CHORE, …). No AI attribution in commits or PRs.
- When changing a skill's behaviour, update or add its evals (`<skill>/evals/evals.json` + fixtures).
