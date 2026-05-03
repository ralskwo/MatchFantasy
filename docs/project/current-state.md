# MatchFantasy Current State

- Updated: 2026-03-28
- Current version: `v0.2.0`
- Baseline commit: `e90f075`

## Overview

MatchFantasy is a Flutter + Flame prototype that combines a grid-based match-3 board with real-time monster wave pressure and a light roguelike run structure. The game is currently optimized around portrait layout, with Windows used as the main development target and mobile support intended next.

## Runtime Architecture

- `lib/main.dart`: locks portrait orientation, loads `MetaState` and `RunState`, injects providers
- `lib/app/match_fantasy_app.dart`: boots the Material 3 theme and router
- `lib/roguelike/router.dart`: defines 11 routes for menu, class, relic, map, upgrade, shop, event, rest, reward, combat, and run end
- `lib/game/match_fantasy_game.dart`: handles Flame orchestration, board input, battle rendering, combat resolution hookup, and HUD publishing
- `lib/game/models/battle_presentation_event.dart`: typed presentation events for board animation, combat cues, volleys, and combo banners
- `lib/game/systems/board_engine.dart`: resolves swaps, cascades, special gem generation, hints, and board mutation helpers
- `lib/game/systems/battle_presentation_planner.dart`: builds ordered visual playback plans from board results and combat cues
- `lib/game/systems/battle_presentation_driver.dart`: replays presentation events with timed dispatch
- `lib/game/systems/combat_resolver.dart`: resolves burst damage, special bonus damage, mana, score, and cues
- `lib/game/systems/projectile_path_geometry.dart`: computes curved projectile travel between board and battlefield
- `lib/game/systems/wave_controller.dart`: runs wave pacing, monster spawn and movement, difficulty scaling, and boss behavior
- `lib/roguelike/state/run_state.dart`: stores active run state, map progress, save/load, and act progression
- `lib/roguelike/state/meta_state.dart`: stores currency, unlocks, achievements, and layout preference

## Implemented Product Surface

- Core combat: elemental charges, meteor ability, consumable items, combo multiplier, floating combat feedback, queued projectile playback, combo banners, and special-tile VFX
- Board systems: 6x6 default board, 7x7 expansion via relic, line/nova/cross specials, tap and drag swap input
- Enemy systems: grunt, runner, brute, and boss types, wave events, elemental weakness/resistance, and boss patterns
- Roguelike loop: class select, starting relic choice, node-based map, reward/shop/event/rest/combat/boss flow, and run end summary
- Progression: relics, passive cards, active cards with recharge thresholds, act advancement, and temporary shop discount event outcome
- Persistence: active run save in `SharedPreferences`, persistent meta unlock/currency/layout in `SharedPreferences`

## Content Snapshot

- Classes: 5
- Relics: 19
- Cards: 15
- Events: 8
- Layout modes: 3 (`portrait`, `landscapeA`, `landscapeB`)
- Tests in suite: 31

## Documentation Snapshot

- Roadmap: `docs/plans/2026-03-28-improvement-roadmap.md`
- Sigil Descent adoption plan: `docs/plans/2026-03-28-sigil-descent-upgrade-adoption.md`
- Prior feature plans: `docs/plans/2026-03-15-*.md`
- Superpowers specs and plans: `docs/superpowers/...`
- Shared collaboration guardrail introduced in `v0.1.0`
- External reference audit added in `v0.1.1`: `docs/reference/2026-03-28-sigil-descent-implementation-audit.md`
- Battle presentation queue spec added in `v0.2.0`: `docs/superpowers/specs/2026-03-28-battle-presentation-queue.md`

## Validation Snapshot

- `flutter analyze --no-fatal-infos`: pass on 2026-03-28
- `flutter test`: pass on 2026-03-28

## Known Gaps

- Some Korean UI and data strings appear with encoding corruption in source files and should be normalized.
- The newly implemented presentation queue does not yet drive every effect layer; synergy banners and burst floating-number timing are still partially legacy-driven.
- The newly documented `sigil_descent` reference confirms that richer special combos, reward metadata, and battle snapshot persistence are the most valuable next upgrades.
