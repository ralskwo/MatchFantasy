# Combat Visual Effects Design

**Date:** 2026-03-22
**Scope:** Five priority combat visual enhancements for MatchFantasy

---

## Goal

Add five missing visual effect layers to close the gap between MatchFantasy and the Sigil Descent reference document, in recommended priority order: bezier-arc projectile, Flame-layer combo banner, monster death particles, tile clear flash, HP bar lerp.

## Architecture Decision

All five effects are implemented **in-place** in `lib/game/match_fantasy_game.dart`, following the existing private-class pattern (`_BattleEffect`, `_FloatingNumber`, etc.). This avoids introducing new files or restructuring existing systems.

Two supporting files receive small additions:
- `lib/game/models/hud_state.dart` — two new `double` fields
- `lib/game/ui/game_hud_overlay.dart` — HP chip replaced with bar widget

No changes to `combat_cue.dart`, `combat_resolver.dart`, `board_engine.dart`, or `wave_controller.dart`.

---

## Effect 1: `_Projectile` — Bezier-Arc Projectile

### Purpose
Replace the flat linear stroke of the existing `_BattleEffectKind.ember` with a curved arc trajectory. Also add projectile arcs for `bloom` and `spark` (which currently have only area effects).

### Class definition
```dart
class _Projectile {
  _Projectile({
    required this.origin,
    required this.control,
    required this.target,
    required this.color,
    required this.duration,
    this.icon,
  });

  final Offset origin;    // bottom-center of battlefield rect (battleRect.center.dx, battleRect.bottom+28)
  final Offset control;   // bezier control: midpoint shifted laterally
  final Offset target;    // laneImpactPoint of front-most monster
  final Color color;
  final double duration;  // 0.42s
  final ui.Image? icon;   // element icon (optional, drawn at tip)
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);

  // Quadratic bezier position at t
  Offset posAt(double t) {
    final double u = 1 - t;
    return origin * (u * u) + control * (2 * u * t) + target * (t * t);
  }
}
```

### Bezier control point formula
In Flame, Y increases downward. `origin.dy` > `target.dy` (origin is below battlefield, target is inside it). The formula below moves the control point upward (lower Y value) by 30% of the vertical travel distance, causing the arc to bulge **toward the board** (i.e., laterally outward from the straight line). A random lateral jitter prevents all projectiles looking identical:

```dart
final Offset mid = Offset((origin.dx + target.dx) / 2, (origin.dy + target.dy) / 2);
final Offset control = Offset(
  mid.dx + (_random.nextDouble() - 0.5) * 40,   // ±20px lateral jitter
  mid.dy - (origin.dy - target.dy) * 0.3,        // arc bulges toward the board (upward in screen coords)
);
```

### Rendering
- **Tip circle:** `drawCircle(posAt(t), 9 * intensity, solidColor)`
- **Trail:** 3 ghost circles at `t - 0.10`, `t - 0.20`, `t - 0.30` with radii `7, 5, 3` and alpha `0.55, 0.30, 0.12`
- **Arrival burst:** when `t >= 0.85`, draw expanding circle at `target` with radius lerped `0→24`, alpha fading from `0.80→0`

### Trigger point
In `_queueCombatCues`, inside `CombatCueKind.elementBurst` case, when `cue.element` ∈ `{BlockType.ember, BlockType.bloom, BlockType.spark}`:
```dart
_projectiles.add(_Projectile(
  origin: boardOrigin,
  control: control,
  target: impactPoint,
  color: GamePalette.block(cue.element!),
  duration: 0.42,
  icon: _elementIcons[cue.element],
));
```
Note: `boardOrigin` and `impactPoint` must be computed here (same logic as `_drawBattleEffects`).

The existing `_BattleEffectKind.ember` rendering is **kept as-is** (area glow). The projectile is additive.

### Storage
```dart
final List<_Projectile> _projectiles = [];
```

### Update (in `update()`)
```dart
for (final p in _projectiles) p.elapsed += dt;
_projectiles.removeWhere((p) => p.elapsed >= p.duration);
```

### Render location
Called from `render()` after `_drawBattleEffects`.

---

## Effect 2: `_ComboBanner` — Flame-Layer Combo Banner

### Purpose
A large dramatic text popup rendered directly on the Flame canvas (not in Flutter HUD) when combo ≥ 3. Coexists with the Flutter HUD's small combo chip.

### Class definition
```dart
class _ComboBanner {
  _ComboBanner({required this.count, required this.color});

  final int count;
  final Color color;
  static const double duration = 1.2;
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);

  String get label => count >= 5 ? '★ COMBO ×$count ★' : 'COMBO ×$count';

  // Scale: 0→0.15 scale-in (0.4→1.1), 0.15→0.80 hold at 1.0, 0.80→1.0 fade
  double get scale {
    if (progress < 0.15) return 0.4 + (0.7 * Curves.easeOutBack.transform(progress / 0.15));
    return 1.0;
  }

  double get alpha {
    if (progress < 0.80) return 1.0;
    return 1.0 - ((progress - 0.80) / 0.20);
  }

  // Upward drift during fade-out
  double get yDrift {
    if (progress < 0.80) return 0.0;
    return -20.0 * ((progress - 0.80) / 0.20);
  }
}
```

### Render
Drawn centered over the battlefield area (vertically at 40% down from battlefield top). Font size: 28 for combo < 5, 36 for combo ≥ 5. Color from `GamePalette.comboColor(count)`. Wrap canvas transforms in `canvas.save()` / `canvas.restore()` to prevent scale leaking to subsequent draws:
```dart
final Offset center = Offset(battleRect.center.dx, battleRect.top + battleRect.height * 0.4 + banner.yDrift);
canvas.save();
canvas.translate(center.dx, center.dy);
canvas.scale(banner.scale);
canvas.translate(-center.dx, -center.dy);
// draw text centered at `center`
canvas.restore();
```

### `_comboColor` dependency
`_comboColor(int)` is currently a free function in `game_hud_overlay.dart`. For use on the Flame canvas, add a matching static method to `GamePalette`:
```dart
// In game_palette.dart:
static Color comboColor(int count) {
  if (count >= 5) return Colors.amber;
  if (count >= 3) return const Color(0xFFFF6B35);
  return const Color(0xFF4BD0D1);
}
```
Use `GamePalette.comboColor(count)` everywhere in `match_fantasy_game.dart`.

### Trigger
In `_queueCombatCues`, **after** the closing `}` of the `for (final CombatCue cue in cues)` loop, add:
```dart
if (_comboCount >= 3) {
  _comboBanners.add(_ComboBanner(
    count: _comboCount,
    color: GamePalette.comboColor(_comboCount),
  ));
}
```

### Render pipeline placement
Call `_drawComboBanners(canvas, battleRect)` from `render()` after `_drawBattleEffects` and after `_drawProjectiles`, so banners overlay everything else in the battlefield region.

### Storage
```dart
final List<_ComboBanner> _comboBanners = [];
```

### Update
```dart
for (final b in _comboBanners) b.elapsed += dt;
_comboBanners.removeWhere((b) => b.elapsed >= _ComboBanner.duration);
```

---

## Effect 3: `_DeathParticle` — Monster Death Ring Burst

### Purpose
Ring + radial sparks at a monster's position when it is defeated, providing visual feedback for kills.

### Class definition
```dart
class _DeathParticle {
  _DeathParticle({required this.lane, required this.progress, required this.color});

  final int lane;
  final double progress;  // monster.progress (0–1) at time of death
  final Color color;
  static const double duration = 0.50;
  double elapsed = 0;

  double get t => (elapsed / duration).clamp(0.0, 1.0);
}
```

### Pixel position computation
At render time, use the same formula as `_monsterPosition()`:
```dart
Offset _deathPosition(Rect battleRect, double defenseY, _DeathParticle p) {
  final double laneWidth = battleRect.width / wave.laneCount;
  final double x = battleRect.left + (laneWidth * p.lane) + (laneWidth / 2);
  final double y = ui.lerpDouble(battleRect.top + 44, defenseY - 24, p.progress.clamp(0, 1))!;
  return Offset(x, y);
}
```

### Rendering
```
ring:     radius = lerp(0, 36, easeOut(t)),  alpha = 0.85 * (1 - t),  strokeWidth=3
6 sparks: each at angle = i * 60°, travels 0→30px, alpha = 1.0 * (1 - t), radius 3px dot
```

### Trigger — snapshot-diff pattern
`WaveController.monsters` is mutated **inside** `CombatResolver.resolveClear()`. The snapshot must be taken inside `_applyBoardResult()`, **before** the `CombatResolver.resolveClear(...)` call (around line 584):

```dart
// Inside _applyBoardResult(), BEFORE CombatResolver.resolveClear():
final List<MonsterState> beforeMonsters = List.of(wave.monsters);

final CombatSummary summary = CombatResolver.resolveClear(
  move: move,
  wave: wave,
  resources: resources,
  burstDamageMultiplier: _getBurstMultiplier(),
);

// After resolver: diff to find killed monsters
final Color killColor = summary.cues
    .where((c) => c.kind == CombatCueKind.elementBurst && c.element != null)
    .map((c) => GamePalette.block(c.element!))
    .firstOrNull ?? Colors.white;
for (final MonsterState dead in beforeMonsters.where((m) => !wave.monsters.contains(m))) {
  _deathParticles.add(_DeathParticle(lane: dead.lane, progress: dead.progress, color: killColor));
}
```

Do NOT take the snapshot before `_queueCombatCues` — by that point `wave.monsters` is already mutated.

### Storage
```dart
final List<_DeathParticle> _deathParticles = [];
```

### Update (in `update()`)
```dart
for (final p in _deathParticles) p.elapsed += dt;
_deathParticles.removeWhere((p) => p.elapsed >= _DeathParticle.duration);
```

### Render location
Called from `render()` inside or immediately after `_drawBattleEffects`, passing `battleRect` and `defenseY`.

---

## Effect 4: `_TileClearFlash` — Board Tile Burst Flash

### Purpose
A brief radial flash at the centroid of cleared tiles for each element type, confirming tile destruction visually.

### Class definition
```dart
class _TileClearFlash {
  _TileClearFlash({required this.center, required this.color, required this.cellSize});

  final Offset center;    // pixel centroid of cleared cells
  final Color color;
  final double cellSize;
  static const double duration = 0.28;
  double elapsed = 0;

  double get t => (elapsed / duration).clamp(0.0, 1.0);
}
```

### Rendering
```
flash circle: radius = lerp(0, cellSize * 1.6, easeOut(t))
inner white:  alpha = 0.75 * (1 - t),  fill
outer color:  alpha = 0.35 * (1 - t),  fill (slightly larger)
```

### Trigger
In `_queueBoardFeedback`, after the existing `_boardPulses.add(...)` loop, add one flash per element type cleared. Use `geometry.grid.center` as the flash origin (board center) since `ElementClearSummary` does not expose per-cell positions and `board_engine.dart` is out of scope:

```dart
final _BoardGeometry geometry = _boardGeometry();
for (final MapEntry<BlockType, ElementClearSummary> entry in move.clearedByType.entries) {
  if (entry.value.count == 0) continue;
  _tileClearFlashes.add(_TileClearFlash(
    center: geometry.grid.center,
    color: GamePalette.block(entry.key),
    cellSize: geometry.cellSize,
  ));
}
```

`ElementClearSummary` has only `count`, `powerTotal`, and `starCount` — no cell positions. Using `geometry.grid.center` gives a correct visual focal point without modifying data models or board engine.

### Storage
```dart
final List<_TileClearFlash> _tileClearFlashes = [];
```

---

## Effect 5: HP Bar Smooth Lerp

### Purpose
Replace the snapping HP/Shield text chip with a smooth-animating visual bar.

### Game state changes
Add to `MatchFantasyGame`:
```dart
double _displayHealth = 30.0;
double _displayShield = 0.0;
```

In `update(dt)`:
```dart
const double lerpRate = 150.0;
_displayHealth = _moveToward(_displayHealth, resources.health.toDouble(), lerpRate * dt);
_displayShield = _moveToward(_displayShield, resources.shield.toDouble(), lerpRate * dt);
```

Add `_moveToward` as a **private instance method** of `MatchFantasyGame`:
```dart
double _moveToward(double current, double target, double maxDelta) {
  final double diff = target - current;
  if (diff.abs() <= maxDelta) return target;
  return current + diff.sign * maxDelta;
}
```

In `resetSession()`:
```dart
_displayHealth = resources.maxHealth.toDouble();
_displayShield = 0.0;
```

### HudState changes
Add two fields to `HudState`:
```dart
final double displayHealth;   // lerped value for smooth bar
final double displayShield;   // lerped value for smooth bar
```

Publish in `_publishHud()`:
```dart
displayHealth: _displayHealth,
displayShield: _displayShield,
```

Also update the **inline field initializer** for the `hud` `ValueNotifier` (lines 62–82 in `match_fantasy_game.dart`), which constructs an initial `HudState(...)` before `resetSession()` runs. Add both new required fields there too:
```dart
displayHealth: 30.0,
displayShield: 0.0,
```

### GameHudOverlay changes
Replace the HP `_StatChip` widget with an `_HpBar` widget:
```dart
class _HpBar extends StatelessWidget {
  const _HpBar({required this.hud});
  final HudState hud;

  @override
  Widget build(BuildContext context) {
    final double frac = (hud.displayHealth / hud.maxHealth).clamp(0.0, 1.0);
    final Color barColor = frac > 0.5
        ? const Color(0xFF4CAF50)
        : frac > 0.25
            ? const Color(0xFFFF9800)
            : const Color(0xFFFF6B6B);
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('HP  ${hud.health}/${hud.maxHealth}',
              style: const TextStyle(color: GamePalette.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              backgroundColor: const Color(0xFF1A3550),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),
          if (hud.displayShield > 0) ...[
            const SizedBox(height: 2),
            Text('Shield ${hud.shield}',
                style: const TextStyle(color: Color(0xFF7FDBFF), fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
```

---

## Reset / Lifecycle

All new lists are cleared in `resetSession()`:
```dart
_projectiles.clear();
_comboBanners.clear();
_deathParticles.clear();
_tileClearFlashes.clear();
_displayHealth = resources.maxHealth.toDouble();
_displayShield = 0.0;
```

---

## Files Changed

| File | Change |
|------|--------|
| `lib/game/match_fantasy_game.dart` | Add 4 new classes, 4 lists, render methods, triggers, HP lerp fields + `_moveToward` method |
| `lib/game/models/hud_state.dart` | Add `displayHealth: double`, `displayShield: double` required fields |
| `lib/game/ui/game_hud_overlay.dart` | Replace HP `_StatChip` with `_HpBar` widget |
| `lib/game/ui/game_palette.dart` | Add `static Color comboColor(int count)` method |

---

## Non-Goals

- No changes to `combat_cue.dart`, `combat_resolver.dart`, `wave_controller.dart`, `board_engine.dart`
- No architectural refactor of existing effect classes
- No new asset files required
- Death particle color is best-effort (last burst element); does not require cue changes

---

## Testing Notes

- `flutter analyze` must pass with 0 warnings
- All existing behavior is preserved (new effects are additive only)
- `resetSession()` must clear all new lists to prevent leaks on restart
- HP lerp initialized to `resources.maxHealth` on session start to avoid initial animation from 0

