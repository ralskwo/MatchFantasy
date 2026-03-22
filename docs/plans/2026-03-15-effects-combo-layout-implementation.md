# Effects, Combo & Layout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 콤보 시스템(캐스케이드 기반 대미지 배율), 타격감 이펙트(화면 흔들림·피격 플래시·플로팅 숫자), 전장:보드 1:1 레이아웃, 보드 확장 유물을 추가한다.

**Architecture:** 모든 이펙트는 기존 Canvas 렌더링 파이프라인(`match_fantasy_game.dart`)에 추가. `HudState`에 `comboCount` 필드를 추가해 Flutter HUD와 연동. `MonsterState`에 `hitFlashTimer` 추가. 레이아웃은 `_battlefieldRect()`와 `_boardGeometry()` 계산식 수정으로 처리.

**Tech Stack:** Flutter, Flame 1.35.1, Dart, Canvas API

---

## Phase 1 — 레이아웃 재설계

---

### Task 1: 보드 6×6 + 전장:보드 1:1 비율

**Files:**
- Modify: `lib/game/match_fantasy_game.dart:104-148` (resetSession)
- Modify: `lib/game/match_fantasy_game.dart:2213-2253` (_battlefieldRect, _boardGeometry)

**Step 1: resetSession에서 보드 크기 변경**

`lib/game/match_fantasy_game.dart`의 `resetSession()` 안에서:

현재:
```dart
board = BoardEngine(rows: 7, columns: 7, random: _random);
```

변경:
```dart
final int boardSize = (runState?.hasRelic('ancient_grid_stone') ?? false) ? 7 : 6;
board = BoardEngine(rows: boardSize, columns: boardSize, random: _random);
```

**Step 2: _battlefieldRect() 수정 — 전장 50%**

현재 전체를 다음으로 교체:
```dart
Rect _battlefieldRect() {
  const double horizontalPadding = 18;
  const double topInset = 48; // 상태바 여유
  final double bottom = size.y * 0.50;
  return Rect.fromLTRB(
    horizontalPadding,
    topInset,
    size.x - horizontalPadding,
    bottom,
  );
}
```

**Step 3: _boardGeometry() 수정 — 보드 50%**

현재 전체를 다음으로 교체:
```dart
_BoardGeometry _boardGeometry() {
  final double top = size.y * 0.50 + 8;
  final double bottom = size.y - 8;
  final Rect frame = Rect.fromLTRB(18, top, size.x - 18, bottom);
  final double cellSize = math.min(
    frame.width / board.columns,
    (frame.height - 34) / board.rows,
  );
  final double gridWidth = cellSize * board.columns;
  final double gridHeight = cellSize * board.rows;
  final Rect grid = Rect.fromLTWH(
    frame.left + ((frame.width - gridWidth) / 2),
    frame.top + 34 + (((frame.height - 34) - gridHeight) / 2),
    gridWidth,
    gridHeight,
  );
  return _BoardGeometry(frame: frame, grid: grid, cellSize: cellSize);
}
```

**Step 4: 분석 확인**
```
flutter analyze --no-fatal-infos
```
Expected: No issues found.

**Step 5: 실행 확인**
```
flutter run -d windows
```
Expected: 전장과 보드가 화면을 절반씩 차지. 보드가 6×6.

---

## Phase 2 — 콤보 시스템

---

### Task 2: 콤보 필드 + 캐스케이드 집계

**Files:**
- Modify: `lib/game/match_fantasy_game.dart`
- Test: `test/roguelike/combo_test.dart`

**Step 1: 콤보 필드 추가**

`match_fantasy_game.dart`의 `int _killCount = 0;` 바로 아래에 추가:
```dart
int _comboCount = 0;   // 현재 스왑의 캐스케이드 콤보 수
int _peakCombo = 0;    // 이번 스왑 최대 콤보 (HUD 표시용)
```

**Step 2: resetSession()에 콤보 리셋 추가**

`_killCount = 0;` 바로 아래:
```dart
_comboCount = 0;
_peakCombo = 0;
```

**Step 3: _applyBoardResult에서 콤보 집계**

`_applyBoardResult` 메서드 내에서 `_queueBoardAnimation(move);` 앞에 추가:
```dart
// 캐스케이드 수만큼 콤보 누적
final int cascadeSteps = move.cascadeBoards.length;
if (cascadeSteps > 0) {
  _comboCount += cascadeSteps;
  if (_comboCount > _peakCombo) _peakCombo = _comboCount;
}
```

**Step 4: 다음 스왑 시작 시 콤보 리셋**

`onTapDown` 메서드 상단 (`if (_isGameOver || _isBoardAnimating) { return; }` 바로 아래):
```dart
_comboCount = 0;
_peakCombo = 0;
```

동일하게 `onDragEnd` 메서드 상단 드래그 완료 직전(swap 수행 전):
```dart
_comboCount = 0;
_peakCombo = 0;
```

**Step 5: _getBurstMultiplier에 콤보 배율 추가**

현재:
```dart
double _getBurstMultiplier() {
  if (runState == null) return 1.0;
  return RelicEffectApplier.burstDamageMultiplier(runState!) +
      ClassPassiveApplier.burstDamageBonus(runState!);
}
```

변경:
```dart
double _getBurstMultiplier() {
  final double baseMultiplier = runState == null
      ? 1.0
      : RelicEffectApplier.burstDamageMultiplier(runState!) +
          ClassPassiveApplier.burstDamageBonus(runState!);
  return baseMultiplier + (_comboCount * 0.10);
}
```

**Step 6: 단위 테스트**

```dart
// test/roguelike/combo_test.dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/game/match_fantasy_game.dart';

void main() {
  group('Combo multiplier', () {
    test('no combo = base multiplier 1.0', () {
      final game = MatchFantasyGame(random: Random(42));
      // _comboCount is 0 at start
      // getBurstMultiplier with no runState = 1.0 + 0 * 0.10 = 1.0
      expect(game.testBurstMultiplier(), 1.0);
    });
  });
}
```

> **참고:** `testBurstMultiplier()` 공개 헬퍼를 `MatchFantasyGame`에 추가해야 테스트 가능:
```dart
// match_fantasy_game.dart에 추가 (테스트용)
double testBurstMultiplier() => _getBurstMultiplier();
```

```
flutter test test/roguelike/combo_test.dart
```
Expected: PASS.

**Step 7: 분석**
```
flutter analyze --no-fatal-infos
```

---

### Task 3: HudState comboCount + HUD 표시

**Files:**
- Modify: `lib/game/models/hud_state.dart`
- Modify: `lib/game/match_fantasy_game.dart:2192-2211` (_publishHud)
- Modify: `lib/game/ui/game_hud_overlay.dart`

**Step 1: HudState에 comboCount 추가**

`lib/game/models/hud_state.dart`:

`required this.difficulty,` 앞에 추가:
```dart
required this.comboCount,
```

필드 선언에 추가 (`final GameDifficulty difficulty;` 앞):
```dart
final int comboCount;
```

**Step 2: _publishHud에 comboCount 전달**

`difficulty: _difficulty,` 바로 앞에 추가:
```dart
comboCount: _peakCombo,
```

`MatchFantasyGame`의 초기 HudState 생성자(hud 필드 초기화 부분)에도 `comboCount: 0,` 추가.

**Step 3: HUD 오버레이에 콤보 표시**

`lib/game/ui/game_hud_overlay.dart`에서 콤보 위젯 추가.

기존 HUD 레이아웃의 score 표시 근처에 다음 위젯 삽입:
```dart
// ValueListenableBuilder 안의 Column 또는 Stack 내부에 추가
if (hud.comboCount >= 2) ...[
  AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: _comboColor(hud.comboCount).withOpacity(0.85),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      hud.comboCount >= 5
          ? '★ COMBO ×${hud.comboCount} ★'
          : 'COMBO ×${hud.comboCount}',
      style: TextStyle(
        fontSize: hud.comboCount >= 3 ? 20 : 16,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1.2,
      ),
    ),
  ),
  const SizedBox(height: 4),
],
```

헬퍼 함수:
```dart
Color _comboColor(int count) {
  if (count >= 5) return Colors.amber;
  if (count >= 3) return const Color(0xFFFF6B35);
  return const Color(0xFF4BD0D1);
}
```

**Step 4: 분석**
```
flutter analyze --no-fatal-infos
```

---

## Phase 3 — 타격감 이펙트

---

### Task 4: 화면 흔들림 (Screen Shake)

**Files:**
- Modify: `lib/game/match_fantasy_game.dart`

**Step 1: 흔들림 필드 추가**

`int _comboCount = 0;` 근처에 추가:
```dart
double _shakeIntensity = 0.0;
double _shakeTimer = 0.0;
```

**Step 2: update()에 shakeTimer 감소 추가**

`update()` 메서드 안, `if (_isGameOver) { return; }` 바로 아래:
```dart
if (_shakeTimer > 0) {
  _shakeTimer = math.max(0, _shakeTimer - dt);
  if (_shakeTimer == 0) _shakeIntensity = 0;
}
```

**Step 3: render()에 shake translate 적용**

`render()` 메서드:
```dart
@override
void render(Canvas canvas) {
  super.render(canvas);
  if (_shakeTimer > 0) {
    final double dx = (_random.nextDouble() - 0.5) * _shakeIntensity;
    final double dy = (_random.nextDouble() - 0.5) * _shakeIntensity;
    canvas.translate(dx, dy);
  }
  _drawBackground(canvas);
  _drawBattlefield(canvas);
  _drawBoard(canvas);
}
```

**Step 4: _triggerShake() 헬퍼 추가**

```dart
void _triggerShake({required double intensity, required double duration}) {
  if (intensity > _shakeIntensity) {
    _shakeIntensity = intensity;
    _shakeTimer = duration;
  }
}
```

**Step 5: 버스트 이벤트에서 흔들림 트리거**

`_queueCombatCues(summary.cues);` 바로 다음 (`_applyBoardResult` 내):
```dart
// 버스트가 있었으면 흔들림
if (summary.cues.any((c) => c.kind == CombatCueKind.elementBurst)) {
  final bool highCombo = _comboCount >= 3;
  _triggerShake(
    intensity: highCombo ? 8.0 : 4.0,
    duration: highCombo ? 0.25 : 0.18,
  );
}
```

메테오 발동(`castMeteor`) 성공 시 (기존 `_score += summary.scoreDelta;` 근처):
```dart
_triggerShake(intensity: 14.0, duration: 0.40);
```

보스 돌파 시 (`_triggerGameOver()` 안 `_statusText` 설정 위):
```dart
_triggerShake(intensity: 10.0, duration: 0.30);
```

**Step 6: resetSession에 리셋**

`_shakeIntensity = 0; _shakeTimer = 0;` 추가.

**Step 7: 분석**
```
flutter analyze --no-fatal-infos
```

---

### Task 5: 몬스터 피격 플래시 (Hit Flash)

**Files:**
- Modify: `lib/game/models/monster_state.dart`
- Modify: `lib/game/match_fantasy_game.dart` (applyDamage 호출부, 몬스터 렌더)

**Step 1: MonsterState에 hitFlashTimer 추가**

`lib/game/models/monster_state.dart`의 `MonsterState` 클래스에 추가:
```dart
double hitFlashTimer = 0.0;
```

**Step 2: WaveController에서 대미지 적용 시 flashTimer 설정**

`lib/game/systems/wave_controller.dart`에서 `monster.applyDamage(...)` 호출 직후:
```dart
monster.hitFlashTimer = 0.12;
```

wave_controller.dart에서 `damageFrontMonster`, `damageAll`, `damageAllByBomb` 등의 메서드를 찾아 각 `applyDamage` 호출 뒤에 추가. 먼저 파일을 읽어서 정확한 위치를 파악 후 수정.

**Step 3: update()에서 hitFlashTimer 감소**

`match_fantasy_game.dart`의 `update()` 내, wave.update(dt) 호출 후:
```dart
for (final monster in wave.monsters) {
  if (monster.hitFlashTimer > 0) {
    monster.hitFlashTimer = math.max(0, monster.hitFlashTimer - dt);
  }
}
```

**Step 4: 몬스터 렌더에 피격 플래시 색상 적용**

`match_fantasy_game.dart`에서 몬스터를 그리는 메서드를 찾아 (grep으로 `_drawMonster` 또는 monster paint 코드 위치 확인).

몬스터 색상 계산 부분에서:
```dart
final Color baseColor = GamePalette.monster(monster.kind);
final Color renderColor = monster.hitFlashTimer > 0
    ? Color.lerp(baseColor, Colors.white,
        (monster.hitFlashTimer / 0.12).clamp(0.0, 1.0))!
    : baseColor;
```

기존 `GamePalette.monster(monster.kind)` 사용 부분을 `renderColor`로 교체.

**Step 5: 분석 + 전체 테스트**
```
flutter analyze --no-fatal-infos
flutter test
```

---

### Task 6: 플로팅 대미지 숫자

**Files:**
- Modify: `lib/game/match_fantasy_game.dart`

**Step 1: _FloatingNumber 클래스 추가**

`match_fantasy_game.dart` 하단 private 클래스들 근처 (`_BattleEffect`, `_BoardPulse` 등 옆):
```dart
class _FloatingNumber {
  _FloatingNumber({
    required this.position,
    required this.text,
    required this.color,
    this.fontSize = 18.0,
    this.lifetime = 0.8,
  });

  final Offset position;
  final String text;
  final Color color;
  final double fontSize;
  final double lifetime;
  double elapsed = 0.0;

  bool get isDone => elapsed >= lifetime;
  double get progress => (elapsed / lifetime).clamp(0.0, 1.0);

  // easeOut y offset (위로 60px)
  double get yOffset {
    final t = 1.0 - (1.0 - progress) * (1.0 - progress);
    return -60.0 * t;
  }

  // 후반 0.3초 페이드아웃
  double get alpha {
    final fadeStart = (lifetime - 0.3) / lifetime;
    if (progress < fadeStart) return 1.0;
    return 1.0 - ((progress - fadeStart) / (1.0 - fadeStart));
  }
}
```

**Step 2: 리스트 필드 추가**

`_boardSpecialEffects` 근처:
```dart
final List<_FloatingNumber> _floatingNumbers = <_FloatingNumber>[];
```

**Step 3: update()에 FloatingNumber 업데이트**

wave.monsters 플래시 업데이트 아래:
```dart
for (int i = _floatingNumbers.length - 1; i >= 0; i--) {
  _floatingNumbers[i].elapsed += dt;
  if (_floatingNumbers[i].isDone) _floatingNumbers.remove(_floatingNumbers[i]);
}
```

**Step 4: 렌더 메서드에 FloatingNumber 그리기**

`render()`의 `_drawBattlefield(canvas)` 아래에 (또는 `_drawBattlefield` 내부 마지막):
```dart
_drawFloatingNumbers(canvas);
```

구현:
```dart
void _drawFloatingNumbers(Canvas canvas) {
  for (final fn in _floatingNumbers) {
    final paint = Paint()
      ..color = fn.color.withOpacity(fn.alpha.clamp(0.0, 1.0));
    _drawText(
      canvas,
      fn.text,
      Offset(fn.position.dx, fn.position.dy + fn.yOffset),
      fontSize: fn.fontSize,
      color: fn.color.withOpacity(fn.alpha.clamp(0.0, 1.0)),
      fontWeight: FontWeight.w900,
    );
  }
}
```

**Step 5: 버스트 대미지 발생 시 FloatingNumber 생성**

`_queueCombatCues(summary.cues)` 이후 (`_applyBoardResult` 내):
```dart
for (final cue in summary.cues) {
  if (cue.kind == CombatCueKind.elementBurst) {
    // 전장 중앙 랜덤 위치에 숫자 표시
    final Rect battleRect = _battlefieldRect();
    final double x = battleRect.left + _random.nextDouble() * battleRect.width;
    final double y = battleRect.center.dy;
    final bool isStarBoost = cue.starBoost;
    final bool highCombo = _comboCount >= 3;
    _floatingNumbers.add(_FloatingNumber(
      position: Offset(x, y),
      text: highCombo
          ? '×${_comboCount} ${cue.magnitude}'
          : '${cue.magnitude}',
      color: isStarBoost
          ? Colors.amber
          : GamePalette.block(cue.element!),
      fontSize: isStarBoost ? 26 : (highCombo ? 24 : 18),
    ));
  }
}
```

> `cue.element`와 `cue.magnitude`가 `CombatCue`에 있는지 확인 필요. `lib/game/models/combat_cue.dart`를 읽고 필드명 확인 후 적용.

**Step 6: resetSession에 클리어**
```dart
_floatingNumbers.clear();
```

**Step 7: 분석 + 전체 테스트**
```
flutter analyze --no-fatal-infos
flutter test
```

---

## Phase 4 — 보드 확장 희귀 유물

---

### Task 7: boardExpand 유물 데이터 + 효과 연동

**Files:**
- Modify: `lib/roguelike/models/relic.dart`
- Modify: `lib/roguelike/data/relics_data.dart`

**Step 1: RelicEffectTag에 boardExpand 추가**

`lib/roguelike/models/relic.dart`의 `RelicEffectTag` enum에:
```dart
boardExpand,
```
추가.

**Step 2: allRelics에 ancient_grid_stone 추가**

`lib/roguelike/data/relics_data.dart`의 Rare 섹션:
```dart
Relic(
  id: 'ancient_grid_stone',
  name: '고대의 격자석',
  rarity: RelicRarity.rare,
  description: '매치 보드가 6×6 → 7×7로 확장됩니다.',
  effect: RelicEffect(tag: RelicEffectTag.boardExpand, value: 1),
),
```

**Step 3: 단위 테스트**
```dart
// test/roguelike/models_test.dart에 추가
test('ancient_grid_stone has boardExpand tag', () {
  final relic = relicById('ancient_grid_stone');
  expect(relic.effect.tag, RelicEffectTag.boardExpand);
});
```

**Step 4: 테스트 실행**
```
flutter test test/roguelike/models_test.dart
```
Expected: PASS.

**Step 5: 분석**
```
flutter analyze --no-fatal-infos
```

---

## Phase 5 — 가로 모드 설정 (Landscape A/B)

---

### Task 8: 레이아웃 모드 enum + SharedPreferences 저장

**Files:**
- Create: `lib/game/models/layout_mode.dart`
- Modify: `lib/roguelike/state/meta_state.dart`

**Step 1: LayoutMode enum 생성**

```dart
// lib/game/models/layout_mode.dart
enum LayoutMode {
  portrait,     // 기본: 세로, 몹 위→아래
  landscapeA,   // 가로: 몹 오른쪽→왼쪽, 전장=왼쪽, 보드=오른쪽
  landscapeB,   // 가로: 몹 왼쪽→오른쪽, 전장=오른쪽, 보드=왼쪽
}
```

**Step 2: MetaState에 layoutMode 추가**

```dart
LayoutMode layoutMode = LayoutMode.portrait;
```

`_toJson()`에:
```dart
'layoutMode': layoutMode.name,
```

`_fromJson()`에:
```dart
layoutMode = LayoutMode.values.firstWhere(
  (m) => m.name == (j['layoutMode'] as String? ?? 'portrait'),
  orElse: () => LayoutMode.portrait,
);
```

**Step 3: 분석**
```
flutter analyze --no-fatal-infos
```

---

### Task 9: MatchFantasyGame에 layoutMode 파라미터 + 렌더 분기

**Files:**
- Modify: `lib/game/match_fantasy_game.dart`
- Modify: `lib/roguelike/screens/combat_screen.dart`

**Step 1: layoutMode 필드 추가**

`MatchFantasyGame` 생성자:
```dart
MatchFantasyGame({math.Random? random, this.runState, this.layoutMode = LayoutMode.portrait})
    : _random = random ?? math.Random() {
  resetSession();
}

final LayoutMode layoutMode;
```

`layout_mode.dart` import 추가:
```dart
import 'package:match_fantasy/game/models/layout_mode.dart';
```

**Step 2: _battlefieldRect()와 _boardGeometry()에 가로 모드 분기 추가**

```dart
Rect _battlefieldRect() {
  const double padding = 18;
  switch (layoutMode) {
    case LayoutMode.portrait:
      return Rect.fromLTRB(padding, 48, size.x - padding, size.y * 0.50);
    case LayoutMode.landscapeA:
      // 전장 왼쪽 50%
      return Rect.fromLTRB(padding, padding, size.x * 0.50, size.y - padding);
    case LayoutMode.landscapeB:
      // 전장 오른쪽 50%
      return Rect.fromLTRB(size.x * 0.50, padding, size.x - padding, size.y - padding);
  }
}

_BoardGeometry _boardGeometry() {
  switch (layoutMode) {
    case LayoutMode.portrait:
      final double top = size.y * 0.50 + 8;
      final Rect frame = Rect.fromLTRB(18, top, size.x - 18, size.y - 8);
      return _buildBoardGeometry(frame);
    case LayoutMode.landscapeA:
      // 보드 오른쪽 50%
      final Rect frame = Rect.fromLTRB(size.x * 0.50 + 8, 18, size.x - 18, size.y - 18);
      return _buildBoardGeometry(frame);
    case LayoutMode.landscapeB:
      // 보드 왼쪽 50%
      final Rect frame = Rect.fromLTRB(18, 18, size.x * 0.50 - 8, size.y - 18);
      return _buildBoardGeometry(frame);
  }
}

_BoardGeometry _buildBoardGeometry(Rect frame) {
  final double cellSize = math.min(
    frame.width / board.columns,
    (frame.height - 34) / board.rows,
  );
  final double gridWidth = cellSize * board.columns;
  final double gridHeight = cellSize * board.rows;
  final Rect grid = Rect.fromLTWH(
    frame.left + ((frame.width - gridWidth) / 2),
    frame.top + 34 + (((frame.height - 34) - gridHeight) / 2),
    gridWidth,
    gridHeight,
  );
  return _BoardGeometry(frame: frame, grid: grid, cellSize: cellSize);
}
```

**Step 3: CombatScreen에서 layoutMode 전달**

```dart
// combat_screen.dart의 initState
final meta = context.read<MetaState>();
_game = MatchFantasyGame(runState: run, layoutMode: meta.layoutMode);
```

**Step 4: 분석 + 전체 테스트**
```
flutter analyze --no-fatal-infos
flutter test
```

---

### Task 10: 가로 모드 설정 UI (HUD 버튼)

**Files:**
- Modify: `lib/game/ui/game_hud_overlay.dart`
- Modify: `windows/runner/main.cpp`

**Step 1: HUD에 레이아웃 전환 버튼 추가**

`game_hud_overlay.dart`의 기존 difficulty 버튼 근처:
```dart
// MetaState provider 접근
final meta = context.read<MetaState>();

// 레이아웃 버튼 (설정 아이콘)
PopupMenuButton<LayoutMode>(
  icon: const Icon(Icons.screen_rotation, color: Colors.white70, size: 20),
  onSelected: (mode) => meta.layoutMode = mode, // MetaState setter 필요
  itemBuilder: (ctx) => [
    const PopupMenuItem(value: LayoutMode.portrait,   child: Text('세로 모드')),
    const PopupMenuItem(value: LayoutMode.landscapeA, child: Text('가로 (몹→왼쪽)')),
    const PopupMenuItem(value: LayoutMode.landscapeB, child: Text('가로 (몹→오른쪽)')),
  ],
),
```

MetaState에 setter 추가 (save + notifyListeners 포함):
```dart
void setLayoutMode(LayoutMode mode) {
  layoutMode = mode;
  save();
  notifyListeners();
}
```

**Step 2: Windows 창 크기 — 가로 모드 시 860×440**

현재 `windows/runner/main.cpp`:
```cpp
Win32Window::Size size(440, 860);
```

가로 모드 지원을 위해 일단 창 크기는 그대로 유지 (Flame의 `size`는 논리 크기 기준으로 자동 대응됨). 실제 창 리사이즈는 Flutter의 `Window` API나 `window_manager` 패키지가 필요해 이번 구현 범위 밖.

대신, `LayoutMode.landscapeA/B` 선택 시 `statusText`에 "가로 모드 활성 - 창 크기를 조절해주세요" 메시지 표시.

**Step 3: 최종 분석 + 전체 테스트**
```
flutter analyze --no-fatal-infos
flutter test
```
Expected: 모든 테스트 PASS, 이슈 0.

---

## 주의사항

- `CombatCue` 필드명 (`element`, `magnitude`, `starBoost`)은 `lib/game/models/combat_cue.dart`에서 반드시 확인 후 사용
- `_drawText` 메서드 시그니처는 현재 `(canvas, text, offset, fontSize, color)` 형태 — `fontWeight` 파라미터가 없으면 추가 필요
- `wave_controller.dart`에서 `applyDamage` 호출 위치는 파일을 읽어 정확히 확인 후 `hitFlashTimer` 설정
- `_FloatingNumber` 렌더 시 `canvas.save()`/`canvas.restore()` 로 shake offset 영향을 받지 않도록 처리 고려
- 가로 모드에서 몹 이동 방향(progress 0→1의 의미)이 변경됨 — `landscapeA`는 오른쪽→왼쪽이므로 몹 x좌표 계산 시 `battleRect.right - progress * battleRect.width` 형태로 반전 필요
