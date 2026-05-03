# MatchFantasy Memory

## Latest Snapshot

- Updated: 2026-03-28
- Latest version note: `v0.2.0`
- Baseline commit: `e90f075`
- Shared workflow: `docs/collaboration/WORKFLOW_GUARDRAIL.md`
- External reference audit: `docs/reference/2026-03-28-sigil-descent-implementation-audit.md`
- Presentation queue spec: `docs/superpowers/specs/2026-03-28-battle-presentation-queue.md`

## Product Summary

- Flutter + Flame prototype for portrait match-3 + monster wave combat with roguelike progression
- Entry flow: main menu -> class -> relic -> map -> node route -> combat/reward/shop/event/rest -> run end
- Persistence: `MetaState` for meta unlocks/currency/layout, `RunState` for active run save/load
- Roadmap status: phases 1-3 complete, phase 4-A battle presentation separation implemented, later Sigil Descent adoption slices still pending

## Content Snapshot

- Classes: 5
- Relics: 19
- Cards: 15
- Events: 8
- Combat waves per node: 3
- Routes: 11

## Validation Snapshot

- `flutter analyze --no-fatal-infos`: pass on 2026-03-28
- `flutter test`: pass on 2026-03-28
- Test files: `31`

## Known Issues / Risks

- Some Korean strings appear mojibake in multiple Dart source and data files. Compile state is okay, but text quality and maintenance trust are reduced.
- Documentation and code were not previously version-locked; `v0.1.0` is the first formal baseline.
- The `sigil_descent` audit identifies reward metadata, shop weighting, and battle snapshot persistence as the next high-value upgrades after the new presentation queue baseline.

## Working Rules

- Read this file first, then `docs/collaboration/WORKFLOW_GUARDRAIL.md`.
- Update `docs/versions/` for every meaningful change.
- Sync `docs/project/current-state.md` whenever architecture or verification status changes.
- Keep external reference audits and adoption plans versioned when they change implementation direction.
