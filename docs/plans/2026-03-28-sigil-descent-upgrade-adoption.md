# MatchFantasy Adoption Plan from Sigil Descent

- Date: `2026-03-28`
- Source audit: `docs/reference/2026-03-28-sigil-descent-implementation-audit.md`
- Scope: identify `sigil_descent` features that are missing, portable, or worth adapting into `MatchFantasy`
- Current status: first implementation slice completed in `v0.2.0` with battle presentation planner/driver, combo banner playback, curved projectile travel, and restored green tests

## Goal

Use `sigil_descent` as a reference implementation to upgrade `MatchFantasy` without copying incompatible architecture blindly. The target is not a rewrite. The target is to port the parts that improve battle readability, reward flow, persistence depth, and content scalability while preserving the current Flame-based runtime.

## Immediate Constraints

- `MatchFantasy` already has two failing tests. The baseline is not clean enough for risky board-system expansion yet.
- `MatchFantasy` uses Flame plus router-driven screens. `sigil_descent` uses Riverpod plus a single app controller. That flow architecture should be adapted, not copied.
- Some text assets and docs in both projects show encoding quality issues. Text migration should happen only after normalization.

## Missing or Underdeveloped in MatchFantasy

Compared with the audited reference, `MatchFantasy` is still missing or weaker in these areas:

- battle presentation queue separation
- explicit projectile-volley and ordered-impact choreography
- rich special-special combo matrix
- `burst` and `colorClear` style specials
- reward rarity metadata, pricing metadata, and weighted shop generation
- active-skill replacement UX as a first-class flow
- effect explanation metadata and in-context info dialogs
- fixed viewport shell for desktop portrait consistency
- battle snapshot persistence that can resume an active combat exactly
- map edge highlighting and lane-based map layout service

## Porting Strategy

### Direct-Port Candidates

These can be copied conceptually with limited adaptation:

- planner/driver split for battle presentation
- projectile path geometry and staggered impact timing
- reward rarity metadata model
- shop-offer model with sale flag
- effect explanation metadata schema
- battle snapshot schema shape

### Adaptation Candidates

These should be reimplemented against `MatchFantasy` boundaries:

- battle screen composition, because `MatchFantasy` renders through Flame
- active skill rail, because HUD publication already exists in `MatchFantasy`
- run-map layout service, because node data and route rules differ
- local JSON save structure, because `MatchFantasy` already uses `SharedPreferences`
- scene-shell framing, because current UI and theme language differ

### Do Not Port Directly

These are not good direct-copy targets:

- the single `AppController` state machine
- removal of router-based screen flow
- replacement of Flame battle rendering with all-widget battle screens
- `sigil_descent` damage numbers or balance values

## Recommended Delivery Order

### Phase 0: Stabilize MatchFantasy Before Porting

Status in `v0.2.0`:

- completed for the current baseline

Required before deeper adoption:

- fix `test/board_engine_test.dart` failure around 4-match line special persistence
- fix `test/combat_resolver_test.dart` failure around line blast bonus damage
- normalize corrupted Korean strings in source and docs that will be touched by the migration
- document the exact ownership boundary between Flame battle state and Flutter overlay state

Exit gate:

- `flutter analyze --no-fatal-infos`
- `flutter test`

### Phase 1: Presentation-Core Refactor

Status in `v0.2.0`:

- initial slice implemented
- presentation event model, planner, driver, combo banner playback, and curved projectile path are now in place

Target:

- add a pure-Dart presentation-event layer similar to `BattlePresentationPlanner`
- add a presentation driver that plays queued events without embedding animation timing into board resolution
- move projectile creation, combo banners, collapse/refill cues, and hit timing into presentation events

Expected benefits:

- resolves the known roadmap gap around battle-presentation separation
- makes board and combat behavior more testable
- creates a stable seam for richer VFX without board-logic regressions

Files likely affected:

- `lib/game/systems/board_engine.dart`
- `lib/game/systems/combat_resolver.dart`
- `lib/game/match_fantasy_game.dart`
- HUD and overlay publication code

### Phase 2: Special-Tile Expansion

Target:

- add `burst` and `colorClear` equivalents to `MatchFantasy`
- introduce explicit special-special combo rules
- preserve existing line, cross, and nova semantics where they already match product expectations

Expected benefits:

- more build expression
- better payoff for high-skill board play
- stronger synergy surface for relics and cards

Dependencies:

- Phase 1 should land first so the extra effects have a safe presentation path
- current board-engine regressions must already be fixed

### Phase 3: Reward and Shop Upgrade

Target:

- introduce reward metadata for rarity, weight, and base price
- move shop generation to weighted offers instead of flat draw behavior
- add sale flags and persistent shop offers per node
- formalize active replacement flow instead of handling it ad hoc
- add effect-info dialog metadata for reward choices

Expected benefits:

- better pacing and economy control
- cleaner active-skill management
- more readable reward decisions

Files likely affected:

- `lib/roguelike/data/cards_data.dart`
- reward and shop screens
- `RunState` persistence payload

### Phase 4: Persistence Upgrade

Target:

- persist an exact in-progress battle snapshot
- include board contents, active charges, wave queue, enemy runtime state, and pending presentation-safe data
- version the save schema before rollout

Expected benefits:

- true mid-run resume
- less state reconstruction code
- safer future battle-feature expansion

Risk:

- save migration complexity is higher than all prior phases

### Phase 5: Map and Screen-Presentation Upgrade

Target:

- extract a dedicated map-layout service
- add edge geometry and clearer node-state visuals
- evaluate a fixed portrait viewport wrapper for desktop builds
- add scene-shell treatment to non-combat nodes where it improves clarity

Expected benefits:

- stronger route readability
- more consistent portrait staging
- better cross-screen visual identity

### Phase 6: Optional Content-Layer Improvements

Target:

- add passive-effect strip patterns
- add explanation metadata and info dialogs
- expand content metadata so reward screens and deck views can explain effects consistently

Expected benefits:

- lower cognitive load
- easier future content scaling

## Technical Mapping

| Sigil Descent reference | MatchFantasy target | Port mode | Notes |
|---|---|---|---|
| `BattlePresentationPlanner` | new presentation planner in game systems | adapt | must emit Flame-friendly overlay events |
| `BattlePresentationDriver` | runtime event player in `match_fantasy_game.dart` or new system | adapt | should own timing, not resolver |
| `ProjectilePathGeometry` | projectile overlay math | direct-port concept | geometry can be reused almost as-is |
| `BoardResolver` special matrix | `board_engine.dart` | adapt | preserve current relic and special balance |
| reward rarity metadata | cards and rewards data layer | direct-port concept | lightweight and high value |
| shop offers by node | `RunState` persistence | adapt | requires save-schema change |
| `BattleSnapshot` | active run save | adapt | likely biggest persistence gain |
| `RunMapLayoutService` | map screen layout helper | adapt | node graph differs |
| `FixedViewportFrame` | desktop portrait shell | optional adapt | useful for Windows target |

## Validation Policy for Each Upgrade Phase

Every implementation phase should produce:

- one design or implementation doc update before code changes land
- one new version note under `docs/versions/`
- truthful validation results
- focused tests around the exact behavior being ported

Minimum validation set per phase:

- `flutter analyze --no-fatal-infos`
- `flutter test`

Additional phase-specific tests should cover:

- board special creation and combo resolution
- projectile event ordering
- active replacement flow
- persistence round-trip and save migration
- run-map layout state output

## Recommended First Build Slice

The first implementation slice landed in `v0.2.0`:

1. fixed the failing combat-resolver expectation
2. added a presentation-event model plus planner/driver boundary
3. moved projectile volley playback onto that boundary

The next slice should extend the same queue to special-combo staging, reward metadata, and battle snapshot persistence.
