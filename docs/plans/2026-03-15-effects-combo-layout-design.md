# MatchFantasy — Effects, Combo & Layout Design
**Date:** 2026-03-15
**Status:** Approved

---

## 1. 콤보 시스템

### 트리거
한 번의 스왑에서 발생하는 캐스케이드 단계마다 콤보 카운트 +1.
`BoardMoveResult.cascadeBoards.length` = 해당 스왑의 캐스케이드 수.

### 리셋 조건
다음 스왑이 시작되는 순간(`onTapDown` / `onDragEnd`) `_comboCount = 0` 초기화.

### 신규 필드 (MatchFantasyGame)
```dart
int _comboCount = 0;   // 현재 콤보 수
int _peakCombo = 0;    // 이번 스왑의 최대 콤보 (HUD 표시용)
```

### 대미지 배율
`_getBurstMultiplier()`에 콤보 보너스를 합산:
```
최종 배율 = 기존배율(유물+클래스) + (_comboCount × 0.10)
```
예: 3콤보 + 기본 1.0 = 1.30배 버스트 대미지.

### HUD 표시
`HudState`에 `comboCount: int` 필드 추가.
- 콤보 0: 숨김
- 콤보 1~2: 소형 텍스트 "COMBO ×N" (흰색)
- 콤보 3~4: 원소 강조 색상, 폰트 크기 +30%
- 콤보 5+: 화면 상단 펄스 애니메이션 + 금색
- 리셋 시: 0.3초 페이드아웃 후 숨김

---

## 2. 타격감 이펙트

### 구현 방식
기존 Canvas 렌더링 파이프라인에 추가. 신규 리스트·필드를 `match_fantasy_game.dart`에 추가.

### 2-1. 화면 흔들림 (Screen Shake)
```dart
double _shakeIntensity = 0; // pixels
double _shakeTimer = 0;     // seconds remaining
```
`render()` 첫 줄에 canvas translate 적용:
```dart
if (_shakeTimer > 0) {
  final dx = (_random.nextDouble() - 0.5) * _shakeIntensity;
  final dy = (_random.nextDouble() - 0.5) * _shakeIntensity;
  canvas.translate(dx, dy);
  _shakeTimer -= dt; // update()에서 감소
}
```

트리거 강도표:
| 이벤트 | 강도 | 지속 |
|--------|------|------|
| 일반 버스트 | 4px | 0.18s |
| 콤보 3+ 버스트 | 8px | 0.25s |
| 메테오 | 14px | 0.40s |
| 보스 돌파 | 10px | 0.30s |

### 2-2. 몬스터 피격 플래시 (Hit Flash)
`MonsterState`에 `double hitFlashTimer = 0` 추가.
대미지 적용 시 `hitFlashTimer = 0.12` 설정.
렌더 시:
```dart
final flashRatio = (monster.hitFlashTimer / 0.12).clamp(0.0, 1.0);
final color = Color.lerp(baseColor, Colors.white, flashRatio)!;
```
`update(dt)`에서 `hitFlashTimer = max(0, hitFlashTimer - dt)`.

### 2-3. 플로팅 대미지 숫자 (_FloatingNumber)
```dart
class _FloatingNumber {
  Offset position;   // 몬스터 머리 위 기준
  String text;       // "124", "3× COMBO!"
  Color color;       // 원소 색상
  double fontSize;   // 기본 18, 콤보 중 +40%, 스타부스트 금색
  double lifetime;   // 0.8초
  double elapsed;
}
```
- y축: `elapsed` 동안 위로 60px 이동 (easeOut)
- 알파: 후반 0.3초 동안 페이드아웃
- 콤보 3+: 텍스트 앞에 "🔥×N " 접두사
- 스타 부스트: 금색(`Colors.amber`) + 크기 1.4×

---

## 3. 레이아웃 재설계

### 기본 모드: 세로 (Portrait)
창 크기 유지: `440×860`.

전장:보드 = **1:1 비율** (각 50%):
```
┌─────────────┐  y=0
│  전장 (50%) │  몹이 위→아래 이동
│  h = size.y/2│
├─────────────┤  y = size.y/2
│  보드 (50%) │  6×6 매치 보드
│  h = size.y/2│
└─────────────┘  y = size.y
```

`_battlefieldRect()` 수정:
- top = 0 + statusBarPadding (≈48px)
- bottom = size.y * 0.50

`_boardGeometry()` 수정:
- top = size.y * 0.50
- height = size.y * 0.50

### 가로 모드 (Landscape, 설정에서 전환)
창 크기: `860×440`.

방향 A (기본): 몹 오른쪽→왼쪽, 전장=왼쪽, 보드=오른쪽
```
┌──────────┬──────────┐
│ 전장(50%)│ 보드(50%)│
└──────────┴──────────┘
```

방향 B: 몹 왼쪽→오른쪽, 전장=오른쪽, 보드=왼쪽
```
┌──────────┬──────────┐
│ 보드(50%)│ 전장(50%)│
└──────────┴──────────┘
```

설정 저장: `SharedPreferences` 키 `layout_orientation` (`portrait`/`landscape_a`/`landscape_b`).
설정 UI: HUD 내 간단한 아이콘 버튼.

### 보드 크기
기본: **6×6** (`BoardEngine(rows: 6, columns: 6)`).
보드 확장 유물 보유 시: **7×7** 로 증가.

---

## 4. 보드 확장 희귀 유물

```dart
Relic(
  id: 'ancient_grid_stone',
  name: '고대의 격자석',
  rarity: RelicRarity.rare,
  description: '매치 보드가 6×6 → 7×7로 확장됩니다.',
  effect: RelicEffect(tag: RelicEffectTag.boardExpand, value: 1),
)
```

- `RelicEffectTag`에 `boardExpand` 추가
- `RelicEffectApplier.applyOnCombatStart()`에서 감지:
  ```dart
  case RelicEffectTag.boardExpand:
    // MatchFantasyGame에서 board 재초기화 처리
    break;
  ```
- `MatchFantasyGame.resetSession()`에서:
  ```dart
  final boardSize = (runState?.hasRelic('ancient_grid_stone') ?? false) ? 7 : 6;
  board = BoardEngine(rows: boardSize, columns: boardSize, random: _random);
  ```

---

## 5. 구현 우선순위

1. **Phase 1** — 레이아웃: 보드 6×6 변경, 전장:보드 1:1 비율, 세로 기본
2. **Phase 2** — 콤보: _comboCount 필드, 캐스케이드 집계, 배율 적용, HUD 표시
3. **Phase 3** — 이펙트: 화면 흔들림, 피격 플래시, 플로팅 대미지 숫자
4. **Phase 4** — 보드 확장 유물: RelicEffectTag.boardExpand, ancient_grid_stone 데이터
5. **Phase 5** — 가로 모드: 설정 UI, 방향 A/B 렌더링 분기, 창 크기 전환
