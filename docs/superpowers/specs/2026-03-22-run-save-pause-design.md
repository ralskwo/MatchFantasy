# Run Save/Continue + Pause Overlay — Design Spec

**Date:** 2026-03-22
**Project:** MatchFantasy (Flutter + Flame 1.35.1)

---

## 1. 목적

### 1-A. 런 저장/이어하기
앱 종료 시 진행 중인 런이 소실되는 문제를 해결한다.
노드를 완료할 때마다 `RunState`를 JSON으로 `SharedPreferences`에 저장하고, 다음 앱 실행 시 메인 메뉴에서 "이어하기" 버튼으로 복원한다.

### 1-B. 일시정지 오버레이
전투 중 게임을 일시정지할 수 있는 UI를 추가한다.
정지 중에는 적 이동, 보드 입력, 액티브 사용이 모두 차단된다.

---

## 2. 런 저장/이어하기 설계

### 2.1 저장 대상 필드

```
RunState → JSON:
  classId        : String         (selectedClass.id.name  ← PlayerClassId enum → .name)
  relicIds       : List<String>   (relics.map(r => r.id))
  cardIds        : List<String>   (cards.map(c => c.id))
  map            : {              (RunMap 전체를 하위 객체로 직렬화)
    startNodeId  : String
    nodes        : Map<id, {
      id          : String
      row         : int           ← MapNode 생성자 필수 필드
      col         : int           ← MapNode 생성자 필수 필드
      type        : String        (NodeType.name)
      isAvailable : bool
      isVisited   : bool
      nextNodeIds : List<String>
    }>
  }
  currentNodeId  : String?
  health         : int
  maxHealth      : int
  gold           : int
  actNumber      : int
  isActive       : bool
```

- `classId` 역직렬화: `PlayerClassId.values.byName(json['classId'])` → `allClasses.firstWhere(...)`
- `relicIds` 역직렬화: `relicById(id)` 사용
- `cardIds` 역직렬화: `cardById(id)` 사용

전투 스냅샷은 저장하지 않는다. 전투 중 앱 종료 시 해당 전투는 소실되고, 복원 시 같은 노드에서 전투를 다시 시작한다.

### 2.2 저장 키

`SharedPreferences` 키: `run_save_v1`

### 2.3 저장 시점

| 시점 | 동작 |
|------|------|
| 노드 방문 후 맵으로 복귀 시 | `RunState.save()` 호출 |
| 런 종료 시 (승리/패배) | 저장 데이터 삭제 (`clearSave()`) |

### 2.4 로드 시점

`main.dart`의 `MetaState.load()` 이후, `RunState.tryLoadSave()` 호출.
저장 데이터가 있으면 `RunState`를 복원 후 `isActive = true`.

### 2.5 RunState 변경 사항

```dart
// 추가 메서드
Future<void> save() async { ... }           // SharedPreferences에 저장
Future<void> tryLoadSave() async { ... }    // 저장 복원 시도; 저장 있으면 필드 복원
Future<void> clearSave() async { ... }      // 저장 삭제
```

`save()`는 각 노드 화면(shop/event/rest/upgrade)에서 맵으로 돌아가기 직전 호출.
`endRun()` 호출 시 `clearSave()` 자동 호출.

`hasSave` 게터는 **사용하지 않는다.** 대신:
- `main.dart`에서 `await runState.tryLoadSave()` 호출 후 `runState.isActive`로 판단
- `tryLoadSave()`는 SharedPreferences에 키가 없으면 아무것도 하지 않음 → `isActive` 유지 false
- `tryLoadSave()` 성공 시 `isActive = true`로 설정

### 2.6 메인 메뉴 변경

```
현재: "새 게임 시작" 버튼만 있음

변경:
  - isActive == true → "이어하기" 버튼 (상단) + "새 게임 시작" 버튼 (하단)
  - isActive == false → "새 게임 시작" 버튼만

"이어하기" 클릭 시: context.go('/map')
"새 게임 시작" 클릭 시: clearSave() → context.go('/class')
```

### 2.7 라우터 가드

`RunState.isActive == true`이고 현재 경로가 `/`이면 자동으로 `/map`으로 리다이렉트하지 않는다.
사용자가 명시적으로 버튼을 클릭해야 복원된다 (의도치 않은 자동 이동 방지).

---

## 3. 일시정지 오버레이 설계

### 3.1 아키텍처

```
GameHudOverlay (Flutter)
  └─ 일시정지 버튼 (⏸ 아이콘)
       └─ onTap → _gameController.pause()

CombatScreen
  └─ _isPaused: bool (setState)
  └─ PauseOverlay (조건부 표시)

MatchFantasyGame
  └─ pauseForOverlay() / resumeForOverlay()
       → pauseEngine() / resumeEngine() 호출
```

### 3.2 MatchFantasyGame 변경

```dart
bool _isManuallyPaused = false;

void pauseForOverlay() {
  _isManuallyPaused = true;
  pauseEngine();
}

void resumeForOverlay() {
  _isManuallyPaused = false;
  resumeEngine();
}
```

### 3.3 PauseOverlay 위젯

```
배경: 반투명 검정 (opacity 0.6)
중앙 카드:
  - 제목: "일시정지"
  - 버튼: "전투 재개"
  - 버튼 클릭 → game.resumeForOverlay() + setState(_isPaused = false)
```

### 3.4 일시정지 중 차단 항목

`pauseEngine()`이 호출되면 Flame의 `update()` 루프가 멈추므로 자동으로 차단:
- 적 이동
- 보드 애니메이션 (Flame 기반)
- 플로팅 숫자 / 흔들림

Flutter HUD 입력 차단 (수동):
- `IgnorePointer(ignoring: _isPaused)` 로 HUD 감싸기

### 3.5 일시정지 버튼 위치

`GameHudOverlay`의 최상단 행 우측 (레이아웃 버튼 옆).

---

## 4. 데이터 흐름

```
[앱 시작]
  main.dart
    final metaState = MetaState();
    await metaState.load();
    final runState = RunState();           ← NEW: main에서 인스턴스 생성
    await runState.tryLoadSave();          ← NEW: 저장 복원 시도
    runApp(
      MultiProvider(providers: [
        ChangeNotifierProvider.value(value: metaState),
        ChangeNotifierProvider.value(value: runState),  ← NEW: .value 패턴
      ], child: MatchFantasyApp())
    )

  match_fantasy_app.dart:
    RunState ChangeNotifierProvider(create:) 제거 (main에서 주입)

[메인 메뉴]
  RunState.isActive?
    yes → "이어하기" 버튼 표시
    no  → "새 게임 시작"만 표시

[이어하기]
  context.go('/map')

[노드 완료 → 맵 복귀]
  RunState.visitNode()
  RunState.save()            ← NEW (각 노드 화면에서)

[런 종료]
  RunState.endRun()
    → clearSave()            ← NEW (내부 자동 호출)
  MetaState.recordRunEnd()
  context.go('/')
```

---

## 5. 파일 변경 목록

| 파일 | 변경 내용 |
|------|-----------|
| `lib/roguelike/state/run_state.dart` | `save()`, `tryLoadSave()`, `clearSave()` 추가; `endRun()`에서 `clearSave()` 호출 |
| `lib/roguelike/models/run_map.dart` | `MapNode` / `RunMap` toJson/fromJson 추가 |
| `lib/roguelike/models/map_node.dart` | `toJson()` / `fromJson()` 추가 |
| `lib/main.dart` | `RunState` 인스턴스를 `main()`에서 생성, `await runState.tryLoadSave()` 호출, `ChangeNotifierProvider.value`로 제공 |
| `lib/app/match_fantasy_app.dart` | RunState `ChangeNotifierProvider(create:)` 제거 (main에서 주입으로 변경) |
| `lib/roguelike/screens/main_menu_screen.dart` | "이어하기" 버튼 조건부 표시 |
| `lib/roguelike/screens/upgrade_screen.dart` | 맵 복귀 전 `RunState.save()` 호출 |
| `lib/roguelike/screens/shop_screen.dart` | 맵 복귀 전 `RunState.save()` 호출 |
| `lib/roguelike/screens/event_screen.dart` | 맵 복귀 전 `RunState.save()` 호출 |
| `lib/roguelike/screens/rest_screen.dart` | 맵 복귀 전 `RunState.save()` 호출 |
| `lib/roguelike/screens/combat_screen.dart` | `_isPaused` + pause/resume 메서드 + PauseOverlay |
| `lib/game/match_fantasy_game.dart` | `pauseForOverlay()` / `resumeForOverlay()` 추가 |
| `lib/game/ui/game_hud_overlay.dart` | 일시정지 버튼 추가 (IgnorePointer + onPause 콜백) |

---

## 6. 테스트 계획

### 런 저장/이어하기
- `RunState.save()` → `tryLoadSave()` 왕복 후 모든 필드 일치 확인
- `endRun()` 후 저장 데이터 없음 확인
- 이어하기 후 currentNodeId 및 health 복원 확인

### 일시정지
- 일시정지 버튼 클릭 → overlay 표시 확인
- 재개 버튼 클릭 → overlay 사라짐 확인
- 일시정지 중 HUD 입력 차단 확인

---

## 7. 제약 / 비범위

- 전투 중 스냅샷 저장 없음 (전투 진입 전 상태만 저장)
- 복수 런 저장 없음 (최신 1개만)
- 자동 리다이렉트 없음 (사용자가 명시적으로 이어하기 클릭)
