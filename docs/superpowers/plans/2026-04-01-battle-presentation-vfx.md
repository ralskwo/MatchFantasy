# Battle Presentation VFX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 콤보 캐스케이드에 스케일링 버스트 연출을 추가하고, Sigil Descent 수준의 드래그 ghost tile·투사체 gradient tail·몬스터 피격 damage popup 위치를 MatchFantasy에 적용한다.

**Architecture:** 모든 변경은 `lib/game/match_fantasy_game.dart` 한 파일에 집중한다. 새 모델 클래스(`_ImpactRing`)와 기존 클래스(`_ClearBurst`, `_Projectile`) 확장, 렌더링 메서드 수정으로 구현한다. Flame Canvas 기반이므로 Flutter Widget overlay 추가 없이 기존 `render()` 파이프라인에 통합한다.

**Tech Stack:** Flutter/Flame 1.35.1, Dart, `dart:ui` (이미 `import 'dart:ui' as ui;`로 임포트됨)

---

## 파일 맵

| 파일 | 변경 내용 |
|------|----------|
| `lib/game/match_fantasy_game.dart` | 모든 VFX 변경 집중 |
| `lib/game/ui/game_palette.dart` | 없음 (기존 색상 재사용) |

---

## Task 1: `_ClearBurst` 콤보 스케일링

**Files:**
- Modify: `lib/game/match_fantasy_game.dart` (class `_ClearBurst` ~line 3340, method `_queueBoardAnimation` ~line 1103, method `_queueBoardFeedback` ~line 1056)

### 1-A. `_ClearBurst`에 `comboScale` 필드 추가

- [ ] `_ClearBurst` 클래스를 찾아 `comboScale` 필드와 `particleCount`/`maxRadius` 게터를 수정한다.

기존:
```dart
class _ClearBurst {
  _ClearBurst({
    required this.center,
    required this.color,
    required this.cellSize,
    required this.isStar,
    required this.specialKind,
  });
  // ...
  int get particleCount => specialKind != null ? 8 : isStar ? 7 : 5;
  double get maxRadius =>
      cellSize * (specialKind != null ? 1.1 : isStar ? 0.9 : 0.65);
}
```

변경 후:
```dart
class _ClearBurst {
  _ClearBurst({
    required this.center,
    required this.color,
    required this.cellSize,
    required this.isStar,
    required this.specialKind,
    this.comboScale = 1.0,
  });
  // ... 기존 필드들 유지
  final double comboScale;

  int get particleCount =>
      ((specialKind != null ? 8 : isStar ? 7 : 5) * comboScale).round().clamp(5, 20);
  double get maxRadius =>
      cellSize * (specialKind != null ? 1.1 : isStar ? 0.9 : 0.65) * comboScale;
}
```

### 1-B. `_queueBoardAnimation`에 comboScale 전달

- [ ] `_queueBoardAnimation` 메서드 안의 `_clearBursts.add(...)` 호출을 수정한다.

기존 (~line 1110):
```dart
_clearBursts.add(_ClearBurst(
  center: Offset(
    geometry.grid.left + (gem.fromColumn + 0.5) * geometry.cellSize,
    geometry.grid.top + (gem.fromRow + 0.5) * geometry.cellSize,
  ),
  color: GamePalette.block(gem.tile.type),
  cellSize: geometry.cellSize,
  isStar: gem.tile.isStar,
  specialKind: gem.tile.special,
));
```

변경 후:
```dart
_clearBursts.add(_ClearBurst(
  center: Offset(
    geometry.grid.left + (gem.fromColumn + 0.5) * geometry.cellSize,
    geometry.grid.top + (gem.fromRow + 0.5) * geometry.cellSize,
  ),
  color: GamePalette.block(gem.tile.type),
  cellSize: geometry.cellSize,
  isStar: gem.tile.isStar,
  specialKind: gem.tile.special,
  comboScale: _comboBurstScale(move.comboDepth),
));
```

### 1-C. `_comboBurstScale` 헬퍼 추가 + 5x 보드 플래시

- [ ] `_queueBoardFeedback` 직후에 헬퍼 메서드를 추가하고, `_queueBoardFeedback`에 5콤보 플래시 로직을 넣는다.

`_queueBoardFeedback` 메서드 끝의 닫는 `}` 바로 앞에 추가:
```dart
    // 5콤보+ 전체 보드 플래시
    if (move.comboDepth >= 5) {
      _boardPulses.add(
        _BoardPulse(
          color: GamePalette.accent,
          duration: 0.35,
          intensity: 1.8,
        ),
      );
    }
```

`_queueBoardFeedback` 다음에 신규 헬퍼 메서드 추가:
```dart
  double _comboBurstScale(int comboDepth) {
    if (comboDepth >= 5) return 1.8;
    if (comboDepth >= 4) return 1.5;
    if (comboDepth >= 3) return 1.3;
    return 1.0;
  }
```

### 1-D. 콤보 쉐이크 스케일링 수정

- [ ] `_dispatchPresentationEvent` 안의 `elementBurst` 쉐이크 로직을 강화한다.

기존 (~line 775):
```dart
case CombatCuePresentationEvent():
  _queueCombatCues(<CombatCue>[event.cue]);
  if (event.cue.kind == CombatCueKind.elementBurst) {
    final bool highCombo = _comboCount >= 3;
    _triggerShake(
      intensity: highCombo ? 8.0 : 4.0,
      duration: highCombo ? 0.25 : 0.18,
    );
  }
  break;
```

변경 후:
```dart
case CombatCuePresentationEvent():
  _queueCombatCues(<CombatCue>[event.cue]);
  if (event.cue.kind == CombatCueKind.elementBurst) {
    final double shakeIntensity = _comboCount >= 5
        ? 16.0
        : _comboCount >= 4
            ? 12.0
            : _comboCount >= 3
                ? 8.0
                : 4.0;
    final double shakeDuration = _comboCount >= 4 ? 0.30 : _comboCount >= 3 ? 0.25 : 0.18;
    _triggerShake(intensity: shakeIntensity, duration: shakeDuration);
  }
  break;
```

### 1-E. `flutter analyze` + commit

- [ ] `flutter analyze --no-fatal-infos` 실행 → "No issues found" 확인
- [ ] 커밋:
```bash
git add lib/game/match_fantasy_game.dart
git commit -m "feat: scale combo burst vfx by cascade depth — ring/particle/shake grow at 3/4/5x"
```

---

## Task 2: 드래그 Ghost Tile (Canvas)

**Files:**
- Modify: `lib/game/match_fantasy_game.dart`
  - 필드 추가 (~line 111 드래그 섹션)
  - `onDragUpdate` (~line 529)
  - `_completeDragSwap` (~line 554)
  - `onDragCancel` (~line 547)
  - `update()` 루프 (~line 990)
  - `_drawBoard` 타일 루프 (~line 1895)
  - 신규 헬퍼 `_drawDragGhost`, `_cellCenterAt`

### 2-A. 드래그 ghost 상태 필드 추가

- [ ] `_dragCurrentPosition` 선언 아래(~line 114)에 다음을 추가한다:

```dart
  GridPoint? _dragTargetCell;          // 드래그 방향에서 예측된 스왑 대상 셀
  double? _dragReboundStartTime;       // rebound 애니메이션 시작 _totalTime
  Offset? _dragReboundFrom;            // rebound 시작 위치
  GridPoint? _dragReboundCell;         // rebound 원점 셀
  static const double _kDragReboundDuration = 0.16;
```

### 2-B. `resetSession()`에 초기화 추가

- [ ] `_dragCurrentPosition = null;` 아래에 다음을 추가한다:

```dart
    _dragTargetCell = null;
    _dragReboundStartTime = null;
    _dragReboundFrom = null;
    _dragReboundCell = null;
```

### 2-C. `onDragUpdate`에서 `_dragTargetCell` 실시간 계산

- [ ] `onDragUpdate`를 다음과 같이 변경한다:

기존:
```dart
  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragCurrentPosition != null) {
      _dragCurrentPosition = Offset(
        _dragCurrentPosition!.dx + event.localDelta.x,
        _dragCurrentPosition!.dy + event.localDelta.y,
      );
    }
  }
```

변경 후:
```dart
  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragCurrentPosition != null) {
      _dragCurrentPosition = Offset(
        _dragCurrentPosition!.dx + event.localDelta.x,
        _dragCurrentPosition!.dy + event.localDelta.y,
      );
      _dragTargetCell = _resolvedDragTarget(
        _dragStartCell,
        _dragStartPosition,
        _dragCurrentPosition,
      );
    }
  }
```

### 2-D. `onDragCancel` 정리

- [ ] `onDragCancel` 메서드를 수정한다:

기존:
```dart
  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragStartCell = null;
    _dragStartPosition = null;
    _dragCurrentPosition = null;
  }
```

변경 후:
```dart
  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragStartCell = null;
    _dragStartPosition = null;
    _dragCurrentPosition = null;
    _dragTargetCell = null;
    _dragReboundStartTime = null;
    _dragReboundFrom = null;
    _dragReboundCell = null;
  }
```

### 2-E. `_completeDragSwap`에 rebound 트리거 추가

- [ ] `_completeDragSwap`에서 유효하지 않은 드래그 시 rebound를 시작한다.

`_completeDragSwap` 메서드 내부에서, `if (dist < minDrag)` 블록을 찾아 수정한다:

기존:
```dart
    if (dist < minDrag) {
      // Too small – treat as a tap: leave _selectedCell so the user can
      // complete the swap with a second tap as before.
      return;
    }
```

변경 후:
```dart
    if (dist < minDrag) {
      // Too small – treat as a tap; leave _selectedCell for second-tap swap.
      return;
    }
```

그리고 타겟 셀 결정 후 유효하지 않은 경우 (타겟이 null이거나 인접하지 않을 때)를 찾아 rebound를 추가한다. `_completeDragSwap` 끝 부분에서 스왑이 실행되지 않는 경우 rebound를 시작:

`_completeDragSwap` 메서드 전체를 찾아, 타겟 셀이 결정되어 `board.trySwap` 호출 직전 코드 바로 위에 아무 처리 없이 반환되는 지점에 추가한다. 구체적으로, 타겟 셀이 없는 경우:

```dart
    // 유효한 대각선이 아닌 단순 드래그 방향 결정 후 타겟 없으면 rebound
    final GridPoint? dragTarget = _resolvedDragTarget(startCell, startPos, endPos);
    if (dragTarget == null) {
      _dragReboundStartTime = _totalTime;
      _dragReboundFrom = endPos;
      _dragReboundCell = startCell;
      _dragTargetCell = null;
      return;
    }
```

**주의**: `_completeDragSwap`의 기존 타겟 결정 로직과 중복되지 않도록 `_resolvedDragTarget` 헬퍼로 통일한다 (아래 2-G 참조).

### 2-F. `update()` 루프에 rebound 진행 처리

- [ ] `update()` 메서드에서 `_totalTime += dt;` 직후(또는 projectile 루프 직후)에 추가한다:

```dart
    // drag rebound 완료 정리
    if (_dragReboundStartTime != null &&
        _totalTime - _dragReboundStartTime! >= _kDragReboundDuration) {
      _dragReboundStartTime = null;
      _dragReboundFrom = null;
      _dragReboundCell = null;
    }
```

### 2-G. `_resolvedDragTarget` 헬퍼 추가

- [ ] `_completeDragSwap` 다음에 신규 헬퍼를 추가한다:

```dart
  GridPoint? _resolvedDragTarget(
    GridPoint? startCell,
    Offset? startPos,
    Offset? endPos,
  ) {
    if (startCell == null || startPos == null || endPos == null) return null;
    final double dx = endPos.dx - startPos.dx;
    final double dy = endPos.dy - startPos.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double minDrag = _boardGeometry().cellSize * 0.33;
    if (dist < minDrag) return null;

    final bool horizontal = dx.abs() >= dy.abs();
    final _BoardGeometry geometry = _boardGeometry();
    if (horizontal) {
      final int targetCol = startCell.column + (dx > 0 ? 1 : -1);
      if (targetCol < 0 || targetCol >= board.colCount) return null;
      return GridPoint(startCell.row, targetCol);
    } else {
      final int targetRow = startCell.row + (dy > 0 ? 1 : -1);
      if (targetRow < 0 || targetRow >= board.rowCount) return null;
      return GridPoint(targetRow, startCell.column);
    }
  }

  Offset _cellCenterAt(_BoardGeometry geometry, GridPoint cell) {
    return Offset(
      geometry.grid.left + (cell.column + 0.5) * geometry.cellSize,
      geometry.grid.top + (cell.row + 0.5) * geometry.cellSize,
    );
  }
```

**참고**: `board.colCount`가 없으면 `BoardEngine`에서 컬럼 수를 확인해 `board.snapshot().first.length` 또는 `BoardEngine.columns` 상수를 사용한다.

### 2-H. `_drawBoard`에 ghost tile 렌더링 추가

- [ ] `_drawBoard` 메서드 안의 타일 루프에서 드래그 중인 소스 셀을 hole로 처리한다.

타일 루프 내부 (`_drawGemTile` 호출 직전)를 찾아:

기존:
```dart
        _drawGemTile(
          canvas,
          geometry: geometry,
          tile: tile,
          cellRect: cellRect,
          // ...
        );
```

변경 후:
```dart
        // 드래그 ghost: 소스 셀은 빈 hole로 표시
        final bool isDragSource =
            _dragStartCell != null &&
            GridPoint(row, column) == _dragStartCell;
        final bool isReboundSource =
            _dragReboundCell != null &&
            GridPoint(row, column) == _dragReboundCell;
        if (isDragSource || isReboundSource) {
          // hole indicator: dim ring
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              cellRect.deflate(geometry.cellSize * 0.07),
              Radius.circular(geometry.cellSize * 0.20),
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..color = Colors.white.withValues(alpha: 0.18),
          );
          continue;
        }

        // 드래그 target preview: -22% 카운터 이동
        Offset extraOffset = Offset.zero;
        if (_dragStartCell != null &&
            _dragTargetCell != null &&
            GridPoint(row, column) == _dragTargetCell) {
          final Offset dragDelta =
              _dragCurrentPosition! - _dragStartPosition!;
          extraOffset = Offset(
            dragDelta.dx.abs() > dragDelta.dy.abs()
                ? -dragDelta.dx * 0.22
                : 0,
            dragDelta.dy.abs() > dragDelta.dx.abs()
                ? -dragDelta.dy * 0.22
                : 0,
          );
        }

        canvas.save();
        if (extraOffset != Offset.zero) canvas.translate(extraOffset.dx, extraOffset.dy);
        _drawGemTile(
          canvas,
          geometry: geometry,
          tile: tile,
          cellRect: cellRect,
          tileFrame: tileFrame,
          isSelected: isSelected,
          isHinted: isHinted,
          isArmedTarget: isArmedTarget,
          alpha: _dragTargetCell != null &&
                  GridPoint(row, column) == _dragTargetCell
              ? 0.70
              : 1.0,
        );
        if (extraOffset != Offset.zero) canvas.restore();
        if (extraOffset == Offset.zero) canvas.restore();
```

**주의**: 기존 `_drawGemTile` 호출에 `canvas.save()`/`canvas.restore()` 없는 경우, 단순히 조건부로 `translate` 후 복원하는 패턴으로 맞춘다. 기존 코드에 이미 `canvas.save()`가 없다면 위 패턴 대신 `cellRect`에 `extraOffset`을 직접 더하는 방식으로 변경한다:

```dart
        final Rect drawCellRect = extraOffset != Offset.zero
            ? cellRect.shift(extraOffset)
            : cellRect;
        final RRect drawTileFrame = extraOffset != Offset.zero
            ? RRect.fromRectAndRadius(
                drawCellRect.deflate(geometry.cellSize * 0.07),
                Radius.circular(geometry.cellSize * 0.20),
              )
            : tileFrame;
        _drawGemTile(
          canvas,
          geometry: geometry,
          tile: tile,
          cellRect: drawCellRect,
          tileFrame: drawTileFrame,
          isSelected: isSelected,
          isHinted: isHinted,
          isArmedTarget: isArmedTarget,
          alpha: (_dragTargetCell != null &&
                  GridPoint(row, column) == _dragTargetCell)
              ? 0.70
              : 1.0,
        );
```

- [ ] `_drawBoard` 메서드 맨 끝(보드 특수 이펙트 draw 이후)에 `_drawDragGhost(canvas, geometry)` 호출을 추가한다.

### 2-I. `_drawDragGhost` 메서드 신규 추가

- [ ] `_drawBoardAnimation` 메서드 직전에 `_drawDragGhost`를 추가한다:

```dart
  void _drawDragGhost(Canvas canvas, _BoardGeometry geometry) {
    // 활성 드래그 ghost
    if (_dragStartCell != null && _dragCurrentPosition != null) {
      final GemTile? tile = board.tileAt(
        _dragStartCell!.row,
        _dragStartCell!.column,
      );
      if (tile != null) {
        const double kScale = 1.12;
        final double cs = geometry.cellSize;
        final Rect ghostRect = Rect.fromCenter(
          center: _dragCurrentPosition!,
          width: cs * kScale,
          height: cs * kScale,
        );
        final RRect ghostFrame = RRect.fromRectAndRadius(
          ghostRect.deflate(cs * 0.07 * kScale),
          Radius.circular(cs * 0.20 * kScale),
        );
        // drop shadow / glow
        canvas.drawCircle(
          _dragCurrentPosition!,
          cs * 0.55,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.32)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
        );
        canvas.drawCircle(
          _dragCurrentPosition!,
          cs * 0.40,
          Paint()
            ..color = GamePalette.block(tile.type).withValues(alpha: 0.22),
        );
        _drawGemTile(
          canvas,
          geometry: geometry,
          tile: tile,
          cellRect: ghostRect,
          tileFrame: ghostFrame,
          isSelected: true,
          scale: kScale,
        );
      }
      return;
    }

    // rebound 애니메이션 ghost
    if (_dragReboundStartTime != null &&
        _dragReboundCell != null &&
        _dragReboundFrom != null) {
      final double elapsed = _totalTime - _dragReboundStartTime!;
      final double rawT = (elapsed / _kDragReboundDuration).clamp(0.0, 1.0);
      final double reboundT = Curves.easeOutBack.transform(rawT);
      final Offset targetCenter = _cellCenterAt(geometry, _dragReboundCell!);
      final Offset ghostPos = Offset.lerp(_dragReboundFrom!, targetCenter, reboundT)!;
      final GemTile? tile = board.tileAt(
        _dragReboundCell!.row,
        _dragReboundCell!.column,
      );
      if (tile != null) {
        final double cs = geometry.cellSize;
        final double scaleVal = ui.lerpDouble(1.10, 1.0, rawT)!;
        final Rect ghostRect = Rect.fromCenter(
          center: ghostPos,
          width: cs * scaleVal,
          height: cs * scaleVal,
        );
        final RRect ghostFrame = RRect.fromRectAndRadius(
          ghostRect.deflate(cs * 0.07 * scaleVal),
          Radius.circular(cs * 0.20 * scaleVal),
        );
        _drawGemTile(
          canvas,
          geometry: geometry,
          tile: tile,
          cellRect: ghostRect,
          tileFrame: ghostFrame,
          scale: scaleVal,
          alpha: ui.lerpDouble(0.9, 1.0, rawT)!,
        );
      }
    }
  }
```

### 2-J. `flutter analyze` + commit

- [ ] `flutter analyze --no-fatal-infos` 실행 → "No issues found" 확인
- [ ] 커밋:
```bash
git add lib/game/match_fantasy_game.dart
git commit -m "feat: add drag ghost tile with hole/preview/rebound (Sigil Descent style)"
```

---

## Task 3: 투사체 Gradient Tail 업그레이드

**Files:**
- Modify: `lib/game/match_fantasy_game.dart` (method `_drawProjectiles` ~line 2800)

### 3-A. `_drawProjectiles` 메서드 교체

- [ ] `_drawProjectiles` 메서드 전체를 다음으로 교체한다:

기존:
```dart
  void _drawProjectiles(Canvas canvas) {
    if (_projectiles.isEmpty) return;
    for (final _Projectile proj in _projectiles) {
      final Offset pos = proj.currentPos;
      final double a = proj.alpha;
      // 발광 원 (outer glow)
      canvas.drawCircle(
        pos,
        7.0,
        Paint()..color = proj.color.withValues(alpha: 0.25 * a),
      );
      // 코어
      canvas.drawCircle(
        pos,
        4.5,
        Paint()..color = proj.color.withValues(alpha: 0.9 * a),
      );
      // trail (3 dots)
      for (int i = 1; i <= 3; i++) {
        final double trailT = (proj.progress - (i * 0.08)).clamp(0.0, 1.0);
        final Offset trailPos = proj.positionAt(trailT);
        canvas.drawCircle(
          trailPos,
          3.0 - i * 0.6,
          Paint()..color = proj.color.withValues(alpha: (0.4 - i * 0.1) * a),
        );
      }
    }
  }
```

변경 후:
```dart
  void _drawProjectiles(Canvas canvas) {
    if (_projectiles.isEmpty) return;
    for (final _Projectile proj in _projectiles) {
      final Offset pos = proj.currentPos;
      final double a = proj.alpha;

      // --- gradient tail (Sigil Descent style) ---
      final double tailT = (proj.progress - 0.18).clamp(0.0, 1.0);
      final Offset tailStart = proj.positionAt(tailT);
      final double tailLength = (pos - tailStart).distance;
      if (tailLength > 1.0) {
        final Paint tailPaint = Paint()
          ..shader = ui.Gradient.linear(
            tailStart,
            pos,
            <Color>[
              proj.color.withValues(alpha: 0),
              proj.color.withValues(alpha: 0.12 * a),
              proj.color.withValues(alpha: 0.55 * a),
              proj.color.withValues(alpha: 0.90 * a),
            ],
            <double>[0.0, 0.25, 0.70, 1.0],
          )
          ..strokeWidth = 8.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(tailStart, pos, tailPaint);
      }

      // outer glow
      canvas.drawCircle(
        pos,
        10.0,
        Paint()..color = proj.color.withValues(alpha: 0.18 * a),
      );
      // mid glow
      canvas.drawCircle(
        pos,
        6.5,
        Paint()..color = proj.color.withValues(alpha: 0.50 * a),
      );
      // white core
      canvas.drawCircle(
        pos,
        4.0,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.92 * a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(
        pos,
        2.8,
        Paint()..color = Colors.white.withValues(alpha: 0.98 * a),
      );
    }
  }
```

### 3-B. `flutter analyze` + commit

- [ ] `flutter analyze --no-fatal-infos` 실행 → "No issues found" 확인
- [ ] 커밋:
```bash
git add lib/game/match_fantasy_game.dart
git commit -m "feat: upgrade projectile to gradient tail + multi-layer glow core (Sigil Descent style)"
```

---

## Task 4: 몬스터 피격 Damage Popup 위치 개선 + Impact Ring

**Files:**
- Modify: `lib/game/match_fantasy_game.dart`
  - `_queueCombatCues` (~line 715) — `_FloatingNumber` 위치를 몬스터 위치로
  - `update()` 루프 (~line 1046) — `_impactRings` 업데이트
  - `_drawBattlefield` (~line 1531) — impact ring 렌더
  - 신규 class `_ImpactRing` 추가
  - 신규 list `_impactRings` 필드 추가

### 4-A. `_ImpactRing` 클래스 추가

- [ ] `_ClearBurst` 클래스 바로 다음에 `_ImpactRing`을 추가한다:

```dart
class _ImpactRing {
  _ImpactRing({
    required this.center,
    required this.color,
    required this.radius,
  });

  final Offset center;
  final Color color;
  final double radius;
  static const double duration = 0.38;
  double elapsed = 0;

  bool get isDone => elapsed >= duration;
  double get t => (elapsed / duration).clamp(0.0, 1.0);
  double get currentRadius => ui.lerpDouble(0, radius, Curves.easeOut.transform(t))!;
  double get alpha => (1.0 - t).clamp(0.0, 1.0);
}
```

### 4-B. `_impactRings` 필드 + 초기화

- [ ] `_clearBursts` 선언 아래에 추가한다:

```dart
  final List<_ImpactRing> _impactRings = <_ImpactRing>[];
```

- [ ] `resetSession()` 안 `_clearBursts.clear();` 다음에 추가한다:

```dart
    _impactRings.clear();
```

### 4-C. `update()` 루프에 `_impactRings` 업데이트

- [ ] `_clearBursts` 루프 다음에 추가한다:

```dart
    for (int index = _impactRings.length - 1; index >= 0; index--) {
      _impactRings[index].elapsed += dt;
      if (_impactRings[index].isDone) {
        _impactRings.removeAt(index);
      }
    }
```

### 4-D. `_queueCombatCues`에서 FloatingNumber 위치 + ImpactRing 트리거

- [ ] `_queueCombatCues` 메서드 안에서 `_floatingNumbers.add(...)` 호출을 수정하고 `_impactRings.add(...)`를 추가한다.

기존 (~line 718):
```dart
        final double x = battleRect.left + _random.nextDouble() * battleRect.width;
        final double y = battleRect.center.dy;
        final bool highCombo = _comboCount >= 3;
        _floatingNumbers.add(
          _FloatingNumber(
            position: Offset(x, y),
            text: highCombo
                ? '×$_comboCount ${cue.magnitude}'
                : '${cue.magnitude}',
```

변경 후:
```dart
        final MonsterState? frontMonster = _frontMonsterForEffects();
        final double defenseY = battleRect.bottom - 26;
        final Offset impactPos = frontMonster != null
            ? _monsterCenter(frontMonster, battleRect, defenseY)
            : Offset(battleRect.center.dx, battleRect.center.dy);
        final bool highCombo = _comboCount >= 3;
        // impact ring at monster position
        _impactRings.add(_ImpactRing(
          center: impactPos,
          color: GamePalette.block(cue.element ?? BlockType.ember),
          radius: frontMonster != null
              ? 42 * (frontMonster.kind.scale) * 0.9
              : 28.0,
        ));
        _floatingNumbers.add(
          _FloatingNumber(
            position: Offset(
              impactPos.dx + 12,
              impactPos.dy - (frontMonster != null ? 42 * frontMonster.kind.scale * 0.55 : 20),
            ),
            text: highCombo
                ? '×$_comboCount ${cue.magnitude}'
                : '${cue.magnitude}',
```

### 4-E. `_drawBattlefield`에 impact ring 렌더 추가

- [ ] 몬스터 루프 직후(또는 `_drawBattlefieldAlerts` 호출 전)에 impact ring 렌더를 추가한다.

`_drawBattlefield` 메서드 안, 몬스터 렌더 for 루프가 끝나는 `}` 바로 다음에:

```dart
    // impact rings
    for (final _ImpactRing ring in _impactRings) {
      canvas.drawCircle(
        ring.center,
        ring.currentRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = ring.color.withValues(alpha: ring.alpha * 0.75),
      );
      canvas.drawCircle(
        ring.center,
        ring.currentRadius * 0.65,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: ring.alpha * 0.40),
      );
    }
```

### 4-F. `flutter analyze` + commit

- [ ] `flutter analyze --no-fatal-infos` 실행 → "No issues found" 확인
- [ ] 커밋:
```bash
git add lib/game/match_fantasy_game.dart
git commit -m "feat: anchor damage popups to monster position + add impact ring vfx"
```

---

## Task 5: 로드맵 및 문서 업데이트

### 5-A. MEMORY.md + 로드맵 업데이트

- [ ] `docs/plans/2026-03-28-improvement-roadmap.md`의 진행 현황 테이블에 battle VFX 항목을 추가한다.
- [ ] `MEMORY.md`에 VFX 시스템 변경 내역을 기록한다.
- [ ] 커밋:
```bash
git add docs/plans/2026-03-28-improvement-roadmap.md
git add C:/Users/ralskwo/.claude/projects/c--Users-ralskwo-Desktop-Study-Privates-MatchFantasy/memory/MEMORY.md
git commit -m "docs: record battle VFX enhancements in roadmap and memory"
```

---

## 자체 검토

### Spec 커버리지 확인
- [x] 콤보 버스트 B안 (스케일링) → Task 1
- [x] 드래그 ghost tile Canvas 렌더 → Task 2
- [x] 투사체 gradient tail → Task 3
- [x] 적 피격 damage popup 위치 개선 → Task 4-D
- [x] Impact ring VFX → Task 4-E
- [x] Sigil Descent cubic bezier 경로 — `_Projectile`이 이미 `ProjectilePathGeometry.pointAt()` 사용 중이므로 별도 작업 불필요

### Placeholder 스캔
- `board.colCount` → 실제 컬럼 수 API 확인 필요. `BoardEngine`에 `colCount` 상수가 없다면 `board.snapshot()[0].length` 또는 `_boardGeometry().columnCount` 등을 사용한다. 실행 시 `board` 필드를 읽어 실제 API 확인 후 수정.
- `cue.element` → `CombatCue`에 `element: BlockType?` 필드가 있음 (grep 결과에서 확인됨)
- `frontMonster.kind.scale` → `MonsterKind.scale` 필드는 `_drawBattlefield`에서 이미 사용 중 (line 1533)

### 타입 일관성
- `_ImpactRing.currentRadius` — `ui.lerpDouble` 반환값은 `double?`이므로 `!` 처리 포함
- `_drawDragGhost`의 `board.tileAt(row, col)` — 기존 `_drawBoard`에서 동일 시그니처 사용 중이므로 일치
- `_resolvedDragTarget` 반환 타입 `GridPoint?` — `_dragTargetCell` 필드 타입과 일치
