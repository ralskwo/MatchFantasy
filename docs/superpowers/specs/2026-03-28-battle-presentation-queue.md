# Battle Presentation Queue

- Date: `2026-03-28`
- Scope: `MatchFantasy` battle presentation sequencing
- Status: implemented in `v0.2.0`

## Goal

Separate battle-result calculation from visual playback so projectile volleys, combo banners, board feedback, and combat cue timing are no longer triggered ad hoc from `MatchFantasyGame._applyBoardResult()`.

## Implemented Pieces

### Presentation Model

- `lib/game/models/battle_presentation_event.dart`
- sealed presentation event types for:
  - board animation
  - board feedback
  - combat cue playback
  - projectile volley playback
  - combo banner playback
  - synergy banner payload

### Planner

- `lib/game/systems/battle_presentation_planner.dart`
- translates a `BoardMoveResult` plus `CombatSummary.cues` into an ordered event list
- adds delayed combo-banner playback when combo count is `>= 3`
- emits projectile volleys with staggered durations and arc bias data for elemental burst cues

### Driver

- `lib/game/systems/battle_presentation_driver.dart`
- keeps a timed queue of presentation events
- dispatches zero-delay events immediately
- dispatches delayed events once their timer expires

### Projectile Geometry

- `lib/game/systems/projectile_path_geometry.dart`
- ports a cubic projectile path helper inspired by `sigil_descent`
- supports:
  - per-volley arc height
  - side bias
  - curved travel between board and battlefield

### Game Integration

- `lib/game/match_fantasy_game.dart`
- `MatchFantasyGame` now:
  - builds a presentation plan after `CombatResolver.resolveClear()`
  - enqueues that plan into `BattlePresentationDriver`
  - dispatches queued events into existing Flame-side effect lists
  - renders a new in-battle combo banner layer
  - uses curved projectile travel instead of the previous flat parabolic-only handling

### Combat Fix Included

- `lib/game/systems/combat_resolver.dart`
- line blast and other match-bonus front-hit damage no longer incorrectly applies elemental affinity
- this fixes the failing resolver expectation in `test/combat_resolver_test.dart`

## Validation

- `flutter analyze --no-fatal-infos`
- `flutter test`

Both passed on `2026-03-28`.
