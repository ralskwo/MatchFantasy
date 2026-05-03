# MatchFantasy Agent Guardrail

These repository instructions are the local top-priority guardrail for Codex in `MatchFantasy`. Direct user instructions still win. Claude must follow the mirrored rules in `CLAUDE.md`.

## Required Startup Read

- `MEMORY.md`
- `docs/collaboration/WORKFLOW_GUARDRAIL.md`
- The latest version note linked from `docs/versions/CHANGELOG.md`

## Required Working Rules

1. Treat documentation as part of the deliverable, not as follow-up work.
2. If a task changes code, behavior, balance, plan status, validation status, or process rules, update the version log in `docs/versions/`.
3. Keep `MEMORY.md` and `docs/project/current-state.md` aligned with the repository's actual state.
4. Record validation truthfully. Include `flutter analyze`, `flutter test`, or an explicit reason they were not run.
5. When process rules change, update both `AGENTS.md` and `CLAUDE.md` in the same task.
6. Prefer appending new version notes over silently overwriting history.
7. If the docs and code disagree, fix the docs before declaring the task complete.

## Superpowers

- After Codex restart, use installed `superpowers` skills when they apply.
- `using-superpowers` should run first when available.
- This repository guardrail overrides generic skill habits if they conflict.
