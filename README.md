# MatchFantasy

`MatchFantasy` is a Flutter + Flame prototype for a portrait match-3 combat game with a lightweight roguelike meta loop.

## Current Snapshot

- Core play: swipe or tap the board, build elemental bursts, and hold off monster waves
- Meta loop: class selection, relic selection, map traversal, reward/shop/event/rest/combat routes, and run-end summary
- Persistence: `MetaState` and `RunState` are stored with `shared_preferences`
- Main development target: Windows portrait build, with Android and iOS intended later

## Documentation

- Shared guardrail: `AGENTS.md`, `CLAUDE.md`, `MEMORY.md`
- Workflow rules: `docs/collaboration/WORKFLOW_GUARDRAIL.md`
- Current project state: `docs/project/current-state.md`
- Version log: `docs/versions/CHANGELOG.md`
- Roadmap: `docs/plans/2026-03-28-improvement-roadmap.md`
- Reference audit: `docs/reference/2026-03-28-sigil-descent-implementation-audit.md`
- Adoption plan: `docs/plans/2026-03-28-sigil-descent-upgrade-adoption.md`
- Presentation queue spec: `docs/superpowers/specs/2026-03-28-battle-presentation-queue.md`

## Development

```bash
flutter pub get
flutter run -d windows
flutter analyze --no-fatal-infos
flutter test
```

See `docs/project/current-state.md` for known issues and current validation status.
