# MatchFantasy Improvement Roadmap

- Updated: `2026-03-28`
- Reference: `C:\Users\ralskwo\Desktop\Study\Privates\sigil_descent`
- Shared context: `MEMORY.md`, `docs/project/current-state.md`

## Purpose

Track the major upgrade phases for `MatchFantasy` while keeping the roadmap aligned with real repository state. `sigil_descent` is the primary reference for battle presentation, reward structure, and persistence upgrades.

## Completed Phases

### Phase 1: Immediate Combat Clarity

Status: completed

- projectile volley visuals
- element affinity system
- elemental charge progress UI

### Phase 2: Combat Depth

Status: completed

- active-skill recharge flow
- cross-clear special tile
- card deck expansion

### Phase 3: Roguelike Surface Expansion

Status: completed

- reward-node flow
- monster weakness UI
- event expansion and temporary shop discount support

### Phase 4-A: Battle Presentation Queue

Status: completed in `v0.2.0`

- battle presentation event model
- battle presentation planner
- battle presentation driver
- curved projectile path geometry
- combo banner playback
- combat-resolver line-blast fix

Spec:

- `docs/superpowers/specs/2026-03-28-battle-presentation-queue.md`

### Phase 4-B: Class Passive Completion

Status: completed

- SparkTrickster and UmbraReaper passive coverage completed

### Phase 4-C: Run Summary Screen

Status: completed

- run-end summary with kills, max combo, and collected cards

### Phase 5-A: Battle VFX Polish (Sigil Descent Style)

Status: completed in `7127d3d`

- combo burst scaling: `_ClearBurst.comboScale` at 1.3×/1.5×/1.8× for 3/4/5x cascades
- 5× cascade full board flash + graduated shake intensity
- drag ghost tile: hole on source cell, floating scaled ghost, target 22% counter-shift, easeOutBack rebound
- projectile gradient tail (`ui.Gradient.linear`) + multi-layer glow core
- `_ImpactRing` class: expanding ring anchored to front monster on elementBurst
- damage popup (`_FloatingNumber`) anchored to monster position

Spec:

- `docs/superpowers/plans/2026-04-01-battle-presentation-vfx.md`

## Active Next Steps

### Phase 5-B: Sigil Descent Adoption, Part 2

Status: next

- extend presentation queue coverage to more effect layers
- add richer special-special combo staging
- move remaining burst impact feedback off legacy direct triggers

### Phase 6: Reward and Shop Metadata

Status: next

- rarity metadata
- weighted reward picking
- weighted shop offers
- persistent shop inventory by node
- active replacement UX cleanup

### Phase 7: Battle Snapshot Persistence

Status: next

- persist in-progress battle state
- restore board, wave queue, enemy runtime state, and active charges
- version the save payload before rollout

## Current Status Table

| Item | Status | Reference |
|---|---|---|
| Phase 1 combat clarity | completed | historical |
| Phase 2 combat depth | completed | historical |
| Phase 3 roguelike surface | completed | historical |
| Phase 4-A presentation queue | completed | `v0.2.0` |
| Phase 4-B class passives | completed | historical |
| Phase 4-C run summary | completed | historical |
| Phase 5-A battle VFX polish | completed | `7127d3d` |
| Phase 5-B expanded presentation coverage | next | adoption plan |
| Phase 6 reward and shop metadata | next | adoption plan |
| Phase 7 battle snapshot persistence | next | adoption plan |

## Validation Guardrail

Every roadmap item that changes code must update:

- `docs/versions/`
- `MEMORY.md`
- `docs/project/current-state.md`

Minimum validation for implementation items:

- `flutter analyze --no-fatal-infos`
- `flutter test`
