# MatchFantasy Workflow Guardrail

## Purpose

Maintain shared working memory for the developer, Codex, and Claude. Every meaningful change must leave behind:

- A current snapshot
- A versioned record
- Truthful validation status

## Source of Truth

- `AGENTS.md` / `CLAUDE.md`: agent-local operating rules
- `MEMORY.md`: fast-start snapshot
- `docs/project/current-state.md`: stable project baseline
- `docs/versions/CHANGELOG.md`: version index
- `docs/versions/*.md`: detailed per-version ledger
- Existing `docs/plans/` and `docs/superpowers/`: feature specs and implementation plans

## Required Workflow

1. Read `MEMORY.md`, this file, and the latest version note before starting substantial work.
2. Decide whether the task creates a new version entry or updates the active in-progress one.
3. Make the code or documentation change.
4. Update affected docs in the same task.
5. Run validation relevant to the change.
6. Record results, open issues, and follow-ups in the version note.
7. Refresh `MEMORY.md` and `docs/project/current-state.md` if the repository baseline changed.

## When a New Version Note Is Required

Create or bump a version note when any of the following changes:

- Gameplay behavior or balance
- Content counts such as class, relic, card, event, route, screen, or system totals
- Architecture or persistence behavior
- Roadmap or progress state
- Validation status or known issues
- Process rules for Codex or Claude collaboration

## Versioning Policy

- `major`: breaking architecture shift, save format reset, or large product-direction change
- `minor`: new feature batch, new content set, or meaningful behavior expansion
- `patch`: bug fix, tuning, doc or process update, or validation-only change
- The formal baseline starts at `v0.1.0` on 2026-03-28

## Version Note Required Fields

- Version and date
- Related request or goal
- Scope summary
- Changed files or affected areas
- Validation results
- Known issues or risks
- Next candidate work

## Collaboration Contract

- Codex and Claude both update the same repository docs; no private chat state should be required to continue work.
- If one agent changes workflow rules, it must update both `AGENTS.md` and `CLAUDE.md`.
- If a session ends mid-task, the latest version note and `MEMORY.md` must make resumption possible without chat history.

## Non-Negotiables

- Do not mark work complete without recording actual validation status.
- Do not silently overwrite historical notes; append a new version note or clearly revise the active one.
- Do not let README, state docs, and current code drift for more than one task.
