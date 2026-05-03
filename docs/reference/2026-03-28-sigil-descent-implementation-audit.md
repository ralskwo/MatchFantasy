# Sigil Descent Implementation Audit

- Audited on: `2026-03-28`
- Source project: `C:\Users\ralskwo\Desktop\Study\Privates\sigil_descent`
- Project status: standalone directory, not a git repository
- Local validation status: not executed
- Validation blocker: local Dart SDK is `3.8.1`, while `sigil_descent/pubspec.yaml` requires `sdk: ^3.11.1`

## Executive Summary

`sigil_descent` is a Flutter + Riverpod match-3 combat prototype with a stronger separation between battle logic, battle presentation, run flow, rewards, and persistence than the current `MatchFantasy` baseline. Its strongest reference value is not raw feature count alone, but the way it isolates board resolution from on-screen choreography through `BattlePresentationPlanner` and `BattlePresentationDriver`.

The project is organized around a single app-level state machine, a 7x7 board, a five-element affinity cycle, a richer special-tile matrix, seeded run-map generation, weighted reward/shop offers, and a JSON save system that can resume an in-progress battle. It also has a broader automated test surface than `MatchFantasy`: `45` test files across app, battle logic, battle view, rewards, persistence, and run-map layers.

## Runtime Architecture

### App Shell and Flow

- `lib/main.dart`: boots Flutter, wraps the app in Riverpod, and enters a widget-driven shell instead of Flame.
- `lib/src/app/app.dart`: renders the current flow screen from app state.
- `lib/src/app/app_flow_state.dart`: uses a single enum for `title`, `runMap`, `battle`, `reward`, `shop`, `rest`, `event`, and `runResult`.
- `lib/src/app/app_controller.dart`: central orchestrator for new run, continue, node selection, battle swaps, active skill use, battle pressure ticks, reward/shop resolution, save checkpoints, and screen transitions.
- `lib/src/app/widgets/fixed_viewport_frame.dart`: locks presentation to a `440 x 956` portrait viewport and scales it with `FittedBox`, giving desktop builds a consistent mobile composition.
- `lib/src/app/widgets/node_scene_shell.dart`: shared scene wrapper for reward, rest, event, and shop screens with node-type-specific mood, framing, and props.

### State Ownership

`AppController` owns both product flow and most side effects. The controller keeps:

- current `AppFlowState`
- current `RunState`
- current `BattleState`
- run result state
- pending reward list
- pending active replacement choice
- persistence queue for save writes

This design removes routing complexity, but makes the controller large. The tradeoff is favorable for a compact prototype because the transition rules remain explicit in one file.

## Battle Systems

### Board Rules

- Board size: `7x7`
- Spawn elements: `wood`, `fire`, `earth`, `metal`, `water`
- Board generation: `BoardGenerator` fills a no-immediate-match board with retry logic
- Match detection: `BoardMatchFinder`
- Swap validation: `BoardSwapService`
- Full resolution: `BoardResolver`

### Tile and Special-Tile Model

The battle board supports normal attack/heal tiles and five special types:

- `rowClear`
- `columnClear`
- `crossClear`
- `burst`
- `colorClear`

Special spawning rules in `BoardResolver`:

- overlapping line groups create `crossClear` or `burst`
- 4-match horizontal lines create `rowClear`
- 4-match vertical lines create `columnClear`
- 5+ line matches create `colorClear`

### Special-Combo Rules

`BoardSwapService` allows a direct swap between two adjacent special tiles even when it does not create a conventional match. `BoardResolver` then expands that into special-combo behavior:

- `burst + burst`: clear the full board
- `colorClear + colorClear`: clear the full board
- `colorClear + other special`: convert all tiles of the color-clear element into the other special's activation
- `burst + rowClear`: trigger a three-row band of row clears
- `burst + columnClear`: trigger a three-column band of column clears
- `burst + crossClear`: trigger both a three-row band and a three-column band
- any other special pair: activate both specials normally

### Battle Resolution Model

`BattleState` separates gameplay state from presentation state:

- player HP
- current wave and remaining waves
- passive state flags such as `jadeAegisAvailable`, `stoneBarkCharges`, `mossHeartActive`, `chainRadianceActive`
- affinity modifiers `strongAffinityBonus` and `weakAffinityCompensation`
- active skill charge state
- board resolution steps
- enemy hit feedbacks
- presentation queue
- active projectile list
- pending healing
- selected tile

This is one of the most important reference patterns for `MatchFantasy`, because it makes animation sequencing observable and testable without coupling it to the resolver itself.

### Damage Model

`BattleEngine` resolves aggregate board outcomes while `DamageRouter` applies actual damage routing.

- attack tiles produce projectile damage
- heal tiles restore HP up to a max of `30`
- damage is applied to the front-most living enemy first
- when a wave is cleared and queued spawns are empty, the next wave auto-promotes
- battle status resolves to `inProgress`, `victory`, or `defeat`

### Element Affinity

`element_affinity.dart` implements a five-element cycle with multipliers:

- strong: `1.6`
- weak: `0.5`
- neutral: `1.0`

Passive effects modify affinity output:

- `cycle-fang`: increases strong match payoff
- `tempered-roots`: softens weak-element penalties, capped at neutral

## Battle Presentation and UX

### Presentation Separation

This is the clearest architectural advantage over `MatchFantasy`.

- `BattlePresentationPlanner` converts pure board resolution into a queue of presentation events.
- `BattlePresentationDriver` consumes that queue one event at a time and mutates `BattleState` only in presentation-safe ways.

The planner emits:

- `ComboBannerEvent`
- `ActiveSkillCastEvent`
- `BoardTransformEvent`
- `TileBurstEvent`
- `ProjectileVolleyEvent`
- `ProjectileImpactEvent`
- `BoardCollapseEvent`
- `BoardRefillEvent`

The driver handles:

- loading projectile volleys into the active projectile overlay
- applying projectile impact damage in arrival order
- updating board transforms independently from combat logic
- clearing presentation state cleanly when the queue ends

### Projectile Choreography

`ProjectileFlight` instances carry:

- per-projectile token
- source board position
- element
- damage
- travel duration
- arc height
- arc bias
- optional affinity use

`BattlePresentationPlanner` uses patterned durations and arc parameters so volleys do not travel in a flat uniform line. `ProjectilePathGeometry` computes cubic paths, and `EnemyField` renders actual flight rather than only impact flashes.

### Input and Pressure

`AppController` advances enemy pressure continuously through `EnemyAdvanceService`, but slows pressure while presentation is resolving. This is a strong reference for preserving real-time combat threat without making animation playback unfair.

### Battle View Composition

`BattleScreen` is built from Flutter widgets rather than Flame. Composition is:

- top HUD
- enemy field
- active skill rail
- board grid
- projectile overlay and feedback layers

Key presentation widgets:

- `board_grid.dart`: drag swaps, axis lock, invalid rebound, burst overlays, transform overlays, collapse and refill staging
- `enemy_field.dart`: enemy cards, SVG sprite display, HP bars, damage floaters, projectile target area
- `battle_projectile_overlay.dart`: explicit projectile layer between board and enemies
- `battle_hud.dart`: run and battle status
- `active_skill_rail.dart`: charge badges, use buttons, effect info access
- `passive_effect_strip.dart`: visible passive inventory during battle
- `board_tile.dart`: tile rendering including special state

## Content and Progression

### Rules and Content Pools

`demo_content.dart` defines the demo ruleset:

- board size `7`
- spawn elements: five-element cycle only
- base active slots: `3`
- max active slots: `4`

Card pool:

- `10` passive cards
- `3` active skills

Enemy pool:

- `jade-skitter`
- `mist-warden`
- `ember-drake`
- `eclipse-hydra`

### Passive and Active Effects

Important passive cards include:

- `jade-aegis`: first hit negation
- `stone-bark`: limited hit blocking
- `moss-heart`: stronger heal match conversion
- `chain-radiance`: combo-linked projectile bonus
- `cycle-fang`: stronger affinity payoff
- `tempered-roots`: weak-affinity compensation
- `chaos-prism`: higher natural special creation chance
- `storm-lens`: active-skill charge tuning

Active-skill specs in `demo_active_skill_specs.dart`:

- `tidal-pulse`: starts at `2/3` charges, recharge threshold `14`
- `sun-spear`: starts at `1/2` charges, recharge threshold `16`
- `steel-hail`: starts at `1/2` charges, recharge threshold `14`

If `storm-lens` is active:

- starting charges `+1`
- max charges `+1`
- recharge threshold `-6`, with a floor of `8`

### Explanation Metadata

The project includes user-facing explanation layers that `MatchFantasy` does not yet mirror at the same fidelity:

- `demo_effect_explanations.dart`: summary, usage rule, detail, and tips for each passive and active
- `effect_detail_dialog.dart`: effect-inspection UI entry point
- `demo_reward_metadata.dart` and `reward_rarity.dart`: rarity, weight, and base price metadata

The Korean strings in several demo content files appear mojibake-corrupted in the current local copy. Code structure remains usable, but text content should not be copied without normalization.

## Run Map and Node Flow

### Map Generation

`RunMapGenerator` builds a seeded graph with `21` nodes (`n0` through `n20`) and fixed depth layers:

- start battle
- reward
- event
- battle
- shop
- rest
- elite
- additional battles
- second shop
- late elite
- rest
- final battle
- boss

The seed changes edge branches rather than rebuilding an unrestricted roguelike graph. This gives controlled content pacing while preserving route variation.

### Map Navigation Rules

`RunMap.availableNodeIds()` unlocks nodes when at least one incoming parent is visited. A previously visited shop can be revisited when it is not the current node. `RunFlowService.moveToNode()` enforces those availability rules and extends `visitedNodeIds`.

### Map Layout and Rendering

`RunMapLayoutService` transforms raw node data into a renderable layout:

- visible depths
- node lanes per depth
- node visual state: `current`, `available`, `cleared`, `locked`
- traversed edge highlighting
- current-to-next edge highlighting

`RunMapScreen`, `run_map_node.dart`, `run_map_edge_geometry.dart`, and `run_map_edge_painter.dart` provide a more structured map presentation than the current `MatchFantasy` baseline.

## Reward and Shop Loop

### Reward Picking

`RewardOfferPicker` supports weighted offers instead of a flat reward draw.

- passives and actives are filtered against already-owned content
- reward screens usually offer three options
- shop screens offer a larger weighted pool
- mixed passive and active offers are probabilistic rather than guaranteed
- sale flags can be assigned to a subset of shop rewards

Rarity controls:

- offer weight
- base shop price
- rarity label

### Reward Application

`RewardService` cleanly separates:

- passive application
- active-slot fill
- active-slot replacement requirement

If the player has no free active slot, the service returns `requiresReplacement = true` instead of mutating state blindly. `AppController` then drives a replacement UX flow in both reward and shop contexts.

### Shop Behavior

`ShopOffer` stores:

- reward payload
- half-price sale flag

`demo_shop_pricing.dart` derives final price from reward metadata and applies a half-price sale when flagged. Shop offers are persisted by node ID so that revisiting the same shop is stable.

## Persistence

### Save Repository

`LocalJsonSaveRepository` stores JSON under:

- `.sigil_descent/run_save.json`
- `.sigil_descent/unlock_save.json`

This is directory-local persistence, not `shared_preferences`.

### Run Save Schema

`RunSave` stores:

- map seed
- current node ID
- player HP
- gold
- shop discount state
- visited node IDs
- persisted shop offers by node ID
- current app flow
- pending reward list
- pending active reward
- optional battle snapshot
- passive cards
- active skills
- unlocked content IDs

### Battle Snapshot Schema

`BattleSnapshot` persists in-progress battle data:

- player HP
- full wave list
- board tiles
- `jadeAegisAvailable`
- `stoneBarkCharges`
- active skill charge state
- spent active skill IDs
- selected row and column

Nested snapshot records include:

- `WaveSnapshot`
- `EnemySnapshot`
- `SpawnSnapshot`
- `TileSnapshot`
- `ActiveSkillSnapshot`

This is materially deeper than the current `MatchFantasy` run-save surface.

## Test Surface

The local `sigil_descent/test` directory contains `45` test files, covering:

- app shell and flow
- battle logic and resolver behavior
- presentation planner and driver
- board drag UX and projectile geometry
- reward service and offer selection
- run-map generation, layout, and screen rendering
- save repository behavior
- content metadata

Validation was not rerun during this audit because the local toolchain does not meet the project SDK requirement.

## Source Inventory

### App

- `lib/main.dart`: bootstrap and Riverpod root
- `lib/src/app/app.dart`: app shell and screen switch
- `lib/src/app/app_flow_state.dart`: top-level flow enum
- `lib/src/app/app_controller.dart`: orchestration, battle loop, persistence, reward/shop flow
- `lib/src/app/screens/title_screen.dart`: title and run entry
- `lib/src/app/screens/shop_screen.dart`: shop UX with price and replacement flow
- `lib/src/app/screens/rest_screen.dart`: rest-node action screen
- `lib/src/app/screens/event_screen.dart`: event-node action screen
- `lib/src/app/screens/placeholder_screen.dart`: fallback scene
- `lib/src/app/widgets/fixed_viewport_frame.dart`: portrait frame scaler
- `lib/src/app/widgets/node_scene_shell.dart`: atmospheric node wrapper

### Battle Models

- `lib/src/battle/model/active_skill_state.dart`: active skill charge state
- `lib/src/battle/model/battle_presentation_event.dart`: typed presentation events
- `lib/src/battle/model/battle_resolution.dart`: battle outcome wrapper
- `lib/src/battle/model/battle_state.dart`: main battle aggregate
- `lib/src/battle/model/battle_tile.dart`: tile payload including special type
- `lib/src/battle/model/board_position.dart`: coordinate primitive
- `lib/src/battle/model/board_resolution.dart`: full board-resolution result
- `lib/src/battle/model/board_resolution_step.dart`: per-cascade step snapshot
- `lib/src/battle/model/board_state.dart`: board matrix API
- `lib/src/battle/model/enemy_hit_feedback.dart`: damage feedback payload
- `lib/src/battle/model/enemy_spawn.dart`: delayed spawn payload
- `lib/src/battle/model/enemy_state.dart`: enemy runtime state
- `lib/src/battle/model/match_group.dart`: raw match grouping
- `lib/src/battle/model/projectile_flight.dart`: projectile timing and damage
- `lib/src/battle/model/projectile_volley.dart`: volley wrapper
- `lib/src/battle/model/resolved_match_group.dart`: match group after resolution semantics
- `lib/src/battle/model/wave_state.dart`: current and queued wave data

### Battle Logic

- `lib/src/battle/logic/active_slot_manager.dart`: active-slot rules
- `lib/src/battle/logic/battle_engine.dart`: apply board-resolution outcome to battle state
- `lib/src/battle/logic/battle_presentation_driver.dart`: consume presentation queue
- `lib/src/battle/logic/battle_presentation_planner.dart`: build event queue from resolution
- `lib/src/battle/logic/board_generator.dart`: no-match board generation
- `lib/src/battle/logic/board_match_finder.dart`: match detection
- `lib/src/battle/logic/board_resolver.dart`: cascades, specials, combos, refill
- `lib/src/battle/logic/board_swap_service.dart`: adjacency validation and special-swap routing
- `lib/src/battle/logic/damage_router.dart`: front-most target damage application
- `lib/src/battle/logic/element_affinity.dart`: element multiplier rules
- `lib/src/battle/logic/enemy_advance_service.dart`: continuous enemy pressure update

### Battle View

- `lib/src/battle/view/battle_screen.dart`: battle scene composition
- `lib/src/battle/view/battle_layout_geometry.dart`: board and enemy layout math
- `lib/src/battle/view/projectile_path_geometry.dart`: cubic projectile path math
- `lib/src/battle/view/widgets/active_skill_rail.dart`: active skill controls
- `lib/src/battle/view/widgets/battle_hud.dart`: HUD layer
- `lib/src/battle/view/widgets/battle_projectile_overlay.dart`: projectile layer
- `lib/src/battle/view/widgets/board_grid.dart`: drag interaction and board animation shell
- `lib/src/battle/view/widgets/board_tile.dart`: tile visual widget
- `lib/src/battle/view/widgets/enemy_field.dart`: enemy presentation and hit feedback
- `lib/src/battle/view/widgets/passive_effect_strip.dart`: passive effect strip

### Content

- `lib/src/content/models/card_definition.dart`: card content schema
- `lib/src/content/models/effect_explanation.dart`: effect explanation schema
- `lib/src/content/models/element_type.dart`: element enum
- `lib/src/content/models/enemy_definition.dart`: enemy content schema
- `lib/src/content/models/mode_rules.dart`: board and slot rules
- `lib/src/content/models/reward_metadata.dart`: reward rarity and pricing metadata
- `lib/src/content/models/reward_rarity.dart`: rarity tiers, weights, base prices
- `lib/src/content/models/run_node_type.dart`: node type enum
- `lib/src/content/models/special_tile_type.dart`: special tile enum
- `lib/src/content/models/tile_kind.dart`: tile kind enum
- `lib/src/content/demo/demo_active_skill_specs.dart`: active charge specs
- `lib/src/content/demo/demo_asset_manifest.dart`: asset manifest
- `lib/src/content/demo/demo_battle_factory.dart`: battle assembly by node type and depth
- `lib/src/content/demo/demo_board_resolver_factory.dart`: resolver tuning factory
- `lib/src/content/demo/demo_content.dart`: demo rules, cards, enemies
- `lib/src/content/demo/demo_effect_explanations.dart`: explanation content
- `lib/src/content/demo/demo_labels.dart`: text labels
- `lib/src/content/demo/demo_reward_metadata.dart`: rarity mapping
- `lib/src/content/demo/demo_shop_pricing.dart`: shop price calculation
- `lib/src/content/view/effect_detail_dialog.dart`: explanation dialog

### Run

- `lib/src/run/model/run_map.dart`: graph model and availability rules
- `lib/src/run/model/run_map_layout.dart`: layout output model
- `lib/src/run/model/run_map_visual_state.dart`: node and edge state enum
- `lib/src/run/model/run_node.dart`: node record
- `lib/src/run/model/run_state.dart`: run-state aggregate
- `lib/src/run/logic/run_flow_service.dart`: legal node movement
- `lib/src/run/logic/run_map_generator.dart`: seeded map builder
- `lib/src/run/logic/run_map_layout_service.dart`: visible layout generation
- `lib/src/run/view/run_map_edge_geometry.dart`: edge path geometry
- `lib/src/run/view/run_map_screen.dart`: map screen
- `lib/src/run/view/widgets/run_map_edge_painter.dart`: edge rendering
- `lib/src/run/view/widgets/run_map_node.dart`: node widget

### Rewards

- `lib/src/rewards/model/reward_option.dart`: passive and active reward union
- `lib/src/rewards/model/shop_offer.dart`: shop offer wrapper
- `lib/src/rewards/logic/reward_offer_picker.dart`: weighted reward and shop generation
- `lib/src/rewards/logic/reward_service.dart`: reward application logic
- `lib/src/rewards/view/reward_screen.dart`: reward selection screen

### Persistence and Meta

- `lib/src/persistence/save_repository.dart`: persistence interface
- `lib/src/persistence/local_json_save_repository.dart`: JSON implementation
- `lib/src/persistence/model/run_save.dart`: run-save payload
- `lib/src/persistence/model/battle_snapshot.dart`: battle-save payload
- `lib/src/persistence/model/unlock_save.dart`: unlock payload
- `lib/src/meta/view/run_result_screen.dart`: run-end summary view

## MatchFantasy Relevance

The most valuable reference implementations to reuse are:

- presentation planning and driving
- richer special-tile combo matrix
- projectile path and impact sequencing
- weighted reward and shop metadata
- full battle snapshot persistence
- run-map layout and edge highlighting
- viewport and scene-shell composition patterns

The least portable pieces are the app-wide Riverpod state machine and the all-widget battle renderer, because `MatchFantasy` currently depends on Flame plus router-based navigation.
