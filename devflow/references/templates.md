# Templates

Texts other people read. Write them in the team language (`language.team`, default English); keep the structure, adapt the wording. Never mention AI assistance. Keep them factual: what was found/changed, where, how to verify.

Placeholders: `{ref}` ticket reference as the tracker writes it (`AB#123`, `PROJ-123`, `#123`), `{id}` bare id, `{title}`, `{branch}`, `{pr_url}`, `{pr_number}`, `{tester}`, `{base}` default branch.

## Branch name — `branch.pattern`

Setup infers the pattern from the repo's existing branch names and asks to confirm. Fallback: `{kind}/{id}-{description-kebab}`.
- `{kind}`: e.g. `bugfix` for bugs/defects, `feature` for enhancements/new work (map from the ticket type; ask if unclear).
- `{Description}` / `{description-kebab}`: 2–5 words from the title, ASCII only, no articles. "Login button not visible on small screens" → `LoginButtonSmallScreens` / `login-button-small-screens`.

Examples of patterns teams use: `{kind}/DevOps{id}_{Description}`, `{kind}/{id}-{description-kebab}`, `{user}/{id}-{description-kebab}`.

## Commit — `commit.format`

Default: `{PREFIX}: {ref} {Imperative summary}` (subject ≤ 72 chars), optional body (why, not what).
Prefixes (`commit.prefixes`): `FIX` bug fix · `ENH` enhancement · `OPT` optimisation without behaviour change · `INT` internal/tooling/build/config · `TEST` tests only · `DOC` docs/comments · `CHORE` maintenance · `BREAK` breaking change · `WIP` temporary (squash before merge). One prefix per commit.

## triage (ticket comment)

```
{Likely cause in one or two sentences, naming the code/data involved (file:line or setting).}

{What is still needed to confirm or fix it, if anything — data, access, a decision.}

Estimate: {n}h — {one-line rationale}.
```

## pr (description)

```
## Summary
{ref}

{The problem in user terms: what was wrong / what was asked.}

## Change
`{main file(s)}`
- {change 1, with the reason}
- {change 2}

{Optional section for compatibility: saved data, migrations, behaviour of existing users/jobs.}

## Testing
- Builds ({build description}).
- {Manual steps that reproduce the scenario and what you saw.}
```

Add `Replaces #{old}` under Summary when an earlier PR for the same ticket was closed.

## ship / handoff (ticket comment)

```
{One line: what was done.} Branch: {branch}. PR: <a href="{pr_url}">{pr_url}</a>{ (replaces #N)}.
How to test: {shortest path to reproduce the original scenario}.
```

## notification (chat message to the tester)

```
Hi {tester first name}, {ref} "{short title}" is ready for testing.
PR: {pr_url}
Ticket: {ticket_url}
To check: {the one scenario that matters most}.
```
