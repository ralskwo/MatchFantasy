# Run Save/Continue + Pause Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 런 진행 상태를 SharedPreferences에 저장해 앱 재시작 시 이어하기를 지원하고, 전투 중 일시정지 오버레이를 추가한다.

**Architecture:** `MapNode`/`RunMap`에 toJson/fromJson을 추가하고, `RunState`에 `save()`/`tryLoadSave()`/`clearSave()`를 추가한다. `main.dart`에서 `RunState`를 직접 인스턴스화해 `ChangeNotifierProvider.value`로 주입한다. 일시정지는 `MatchFantasyGame.pauseForOverlay()` + Flutter `PauseOverlay` 위젯으로 구현한다.

**Tech Stack:** Flutter, Dart, shared_preferences ^2.3.2, provider ^6.1.2, Flame 1.35.1

---

## Phase 1 — 직렬화 기반

---

### Task 1: MapNode + RunMap toJson/fromJson

**Files:**
- Modify: `lib/roguelike/models/map_node.dart`
- Modify: `lib/roguelike/models/run_map.dart`
- Test: `test/roguelike/run_save_test.dart`

- [ ] **Step 1: MapNode.toJson / MapNode.fromJson 테스트 작성**

`test/roguelike/run_save_test.dart` 생성:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/roguelike/models/map_node.dart';
import 'package:match_fantasy/roguelike/models/run_map.dart';

void main() {
  group('MapNode serialization', () {
    test('toJson / fromJson round-trip preserves all fields', () {
      final node = MapNode(
        id: 'n_0_0',
        type: NodeType.combat,
        row: 0,
        col: 0,
        isAvailable: true,
        isVisited: false,
        nextNodeIds: ['n_1_0', 'n_1_1'],
      );
      final json = node.toJson();
      final restored = MapNode.fromJson(json);
      expect(restored.id, node.id);
      expect(restored.type, node.type);
      expect(restored.row, node.row);
      expect(restored.col, node.col);
      expect(restored.isAvailable, node.isAvailable);
      expect(restored.isVisited, node.isVisited);
      expect(restored.nextNodeIds, node.nextNodeIds);
    });
  });

  group('RunMap serialization', () {
    test('toJson / fromJson round-trip preserves nodes and startNodeId', () {
      final original = RunMap.generate(seed: 42, actRows: 4);
      final json = original.toJson();
      final restored = RunMap.fromJson(json);
      expect(restored.startNodeId, original.startNodeId);
      expect(restored.nodes.length, original.nodes.length);
      for (final entry in original.nodes.entries) {
        final r = restored.nodes[entry.key]!;
        expect(r.id, entry.value.id);
        expect(r.type, entry.value.type);
        expect(r.row, entry.value.row);
        expect(r.col, entry.value.col);
        expect(r.isAvailable, entry.value.isAvailable);
        expect(r.isVisited, entry.value.isVisited);
        expect(r.nextNodeIds, entry.value.nextNodeIds);
      }
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```
flutter test test/roguelike/run_save_test.dart
```
Expected: FAIL (toJson/fromJson not defined)

- [ ] **Step 3: MapNode.toJson / fromJson 구현**

`lib/roguelike/models/map_node.dart`에 추가:
```dart
Map<String, dynamic> toJson() => {
  'id': id,
  'type': type.name,
  'row': row,
  'col': col,
  'isAvailable': isAvailable,
  'isVisited': isVisited,
  'nextNodeIds': nextNodeIds,
};

factory MapNode.fromJson(Map<String, dynamic> j) => MapNode(
  id: j['id'] as String,
  type: NodeType.values.byName(j['type'] as String),
  row: j['row'] as int,
  col: j['col'] as int,
  isAvailable: j['isAvailable'] as bool,
  isVisited: j['isVisited'] as bool,
  nextNodeIds: List<String>.from(j['nextNodeIds'] as List),
);
```

- [ ] **Step 4: RunMap.toJson / fromJson 구현**

`lib/roguelike/models/run_map.dart`에 추가:
```dart
Map<String, dynamic> toJson() => {
  'startNodeId': startNodeId,
  'nodes': nodes.map((k, v) => MapEntry(k, v.toJson())),
};

factory RunMap.fromJson(Map<String, dynamic> j) => RunMap(
  startNodeId: j['startNodeId'] as String,
  nodes: (j['nodes'] as Map<String, dynamic>).map(
    (k, v) => MapEntry(k, MapNode.fromJson(v as Map<String, dynamic>)),
  ),
);
```

- [ ] **Step 5: 테스트 통과 확인**

```
flutter test test/roguelike/run_save_test.dart
```
Expected: PASS

- [ ] **Step 6: 분석 확인**

```
flutter analyze --no-fatal-infos
```
Expected: No issues found.

- [ ] **Step 7: 커밋**

```
git add lib/roguelike/models/map_node.dart lib/roguelike/models/run_map.dart test/roguelike/run_save_test.dart
git commit -m "feat: add toJson/fromJson to MapNode and RunMap"
```

---

### Task 2: RunState save / tryLoadSave / clearSave

**Files:**
- Modify: `lib/roguelike/state/run_state.dart`
- Modify: `lib/roguelike/data/classes_data.dart` (allClasses 접근용 — 이미 존재)
- Test: `test/roguelike/run_save_test.dart`

**의존성:** Task 1 완료 필요

- [ ] **Step 1: RunState 직렬화 테스트 추가**

`test/roguelike/run_save_test.dart`에 추가:
```dart
import 'package:match_fantasy/roguelike/data/classes_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

// run_save_test.dart 파일 상단 import 섹션에 추가:
// import 'package:shared_preferences/shared_preferences.dart';

// 기존 group 아래에 추가:
group('RunState serialization', () {
  setUp(() {
    // SharedPreferences 플랫폼 채널 mock 초기화 (MissingPluginException 방지)
    SharedPreferences.setMockInitialValues({});
  });

  test('toSaveJson / fromSaveJson round-trip preserves run state', () {
    final run = RunState();
    run.startRun(
      playerClass: allClasses.first,
      startingRelic: relicById('ember_core'),
      runMap: RunMap.generate(seed: 99, actRows: 4),
    );
    run.earnGold(50);
    run.takeDamage(5);

    final json = run.toSaveJson();
    final restored = RunState();
    restored.fromSaveJson(json);

    expect(restored.isActive, true);
    expect(restored.health, run.health);
    expect(restored.gold, run.gold);
    expect(restored.selectedClass?.id, run.selectedClass?.id);
    expect(restored.relics.map((r) => r.id), run.relics.map((r) => r.id));
    expect(restored.map?.startNodeId, run.map?.startNodeId);
  });

  test('endRun sets isActive false', () async {
    SharedPreferences.setMockInitialValues({});
    final run = RunState();
    run.startRun(
      playerClass: allClasses.first,
      startingRelic: relicById('ember_core'),
      runMap: RunMap.generate(seed: 1, actRows: 4),
    );
    expect(run.isActive, true);
    run.endRun();
    expect(run.isActive, false);
  });
});
```

- [ ] **Step 2: 테스트 실패 확인**

```
flutter test test/roguelike/run_save_test.dart
```
Expected: FAIL (toSaveJson/fromSaveJson not defined)

- [ ] **Step 3: RunState에 직렬화 메서드 + SharedPreferences 저장 구현**

`lib/roguelike/state/run_state.dart` 상단에 import 추가:
```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:match_fantasy/roguelike/data/classes_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';
```

클래스에 추가 (상수 + 메서드):
```dart
static const String _saveKey = 'run_save_v1';

/// 현재 런 상태를 JSON Map으로 직렬화 (SharedPreferences 저장용)
Map<String, dynamic> toSaveJson() => {
  'classId': selectedClass!.id.name,
  'relicIds': relics.map((r) => r.id).toList(),
  'cardIds': cards.map((c) => c.id).toList(),
  'map': map!.toJson(),
  'currentNodeId': currentNodeId,
  'health': health,
  'maxHealth': maxHealth,
  'gold': gold,
  'actNumber': actNumber,
  'isActive': isActive,
};

/// JSON Map에서 런 상태를 복원
void fromSaveJson(Map<String, dynamic> j) {
  final classId = PlayerClassId.values.byName(j['classId'] as String);
  selectedClass = allClasses.firstWhere((c) => c.id == classId);
  relics = (j['relicIds'] as List).map((id) => relicById(id as String)).toList();
  cards = (j['cardIds'] as List).map((id) => cardById(id as String)).toList();
  map = RunMap.fromJson(j['map'] as Map<String, dynamic>);
  currentNodeId = j['currentNodeId'] as String?;
  health = j['health'] as int;
  maxHealth = j['maxHealth'] as int;
  gold = j['gold'] as int;
  actNumber = j['actNumber'] as int;
  isActive = j['isActive'] as bool;
}

/// SharedPreferences에 현재 런 저장
Future<void> save() async {
  if (!isActive) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_saveKey, jsonEncode(toSaveJson()));
}

/// SharedPreferences에서 런 복원 시도; 없으면 무동작
Future<void> tryLoadSave() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_saveKey);
  if (raw == null) return;
  try {
    fromSaveJson(jsonDecode(raw) as Map<String, dynamic>);
    notifyListeners();
  } catch (_) {
    // 손상된 저장 무시
    await prefs.remove(_saveKey);
  }
}

/// 저장 데이터 삭제
Future<void> clearSave() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_saveKey);
}
```

`endRun()` 수정 — `clearSave()` 자동 호출:
```dart
import 'dart:async'; // unawaited 사용을 위해 상단에 추가

void endRun() {
  isActive = false;
  unawaited(clearSave());  // fire-and-forget; analyzer discarded_futures lint 억제
  notifyListeners();
}
```

- [ ] **Step 4: 테스트 통과 확인**

```
flutter test test/roguelike/run_save_test.dart
```
Expected: PASS

- [ ] **Step 5: 전체 테스트 통과 확인**

```
flutter test
```
Expected: All tests pass.

- [ ] **Step 6: 분석 확인**

```
flutter analyze --no-fatal-infos
```

- [ ] **Step 7: 커밋**

```
git add lib/roguelike/state/run_state.dart test/roguelike/run_save_test.dart
git commit -m "feat: add run save/load/clear to RunState"
```

---

## Phase 2 — 앱 진입점 + UI

---

### Task 3: main.dart + match_fantasy_app.dart Provider 리팩터

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/app/match_fantasy_app.dart`

**의존성:** Task 2 완료 필요

- [ ] **Step 1: main.dart 수정**

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/app/match_fantasy_app.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  final meta = MetaState();
  await meta.load();

  final runState = RunState();
  await runState.tryLoadSave();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: meta),
        ChangeNotifierProvider.value(value: runState),
      ],
      child: const MatchFantasyApp(),
    ),
  );
}
```

- [ ] **Step 2: match_fantasy_app.dart에서 RunState Provider 제거**

`lib/app/match_fantasy_app.dart`에서 `ChangeNotifierProvider(create: (_) => RunState(), ...)` 래퍼 제거. `MaterialApp.router`를 직접 반환하도록 변경:

현재:
```dart
return ChangeNotifierProvider(
  create: (_) => RunState(),
  child: MaterialApp.router(
    ...
  ),
);
```

변경:
```dart
return MaterialApp.router(
  ...
);
```

(RunState import도 제거)

- [ ] **Step 3: 분석 확인**

```
flutter analyze --no-fatal-infos
```
Expected: No issues found.

- [ ] **Step 4: 앱 실행 확인 (컴파일 통과)**

```
flutter test test/widget_test.dart
```
Expected: PASS

- [ ] **Step 5: 커밋**

```
git add lib/main.dart lib/app/match_fantasy_app.dart
git commit -m "feat: provide RunState from main with tryLoadSave"
```

---

### Task 4: MainMenuScreen 이어하기 버튼

**Files:**
- Modify: `lib/roguelike/screens/main_menu_screen.dart`

**의존성:** Task 3 완료 필요

- [ ] **Step 1: main_menu_screen.dart 읽기**

파일을 읽어 현재 버튼 레이아웃과 RunState 접근 방식을 확인한다.

- [ ] **Step 2: Consumer<RunState> + 이어하기 버튼 추가**

현재 `"새 게임 시작"` 버튼 앞에 `Consumer<RunState>`를 추가:

```dart
import 'package:match_fantasy/roguelike/state/run_state.dart';

// 버튼 영역에 추가:
Consumer<RunState>(
  builder: (ctx, run, _) {
    if (!run.isActive) return const SizedBox.shrink();
    return Column(
      children: [
        FilledButton(
          onPressed: () => context.go('/map'),
          child: const Text('이어하기'),
        ),
        const SizedBox(height: 8),
      ],
    );
  },
),
```

"새 게임 시작" 버튼의 `onPressed`에 `clearSave()` 추가:

> **주의:** 현재 코드에서 새 게임 버튼은 `context.go('/class')`가 아니라 `context.push('/class')`를 사용한다. 파일을 읽어 정확한 호출 방식을 확인 후 동일한 방식으로 작성.

```dart
onPressed: () async {
  final run = context.read<RunState>();
  await run.clearSave();
  if (context.mounted) context.push('/class'); // 기존 코드 방식에 맞춰 go 또는 push 사용
},
```

- [ ] **Step 3: 분석 확인**

```
flutter analyze --no-fatal-infos
```

- [ ] **Step 4: 전체 테스트 통과 확인**

```
flutter test
```
Expected: All tests pass.

- [ ] **Step 5: 커밋**

```
git add lib/roguelike/screens/main_menu_screen.dart
git commit -m "feat: show continue button on main menu when run is active"
```

---

### Task 5: 노드 화면에서 맵 복귀 전 save() 호출

**Files:**
- Modify: `lib/roguelike/screens/upgrade_screen.dart`
- Modify: `lib/roguelike/screens/shop_screen.dart`
- Modify: `lib/roguelike/screens/event_screen.dart`
- Modify: `lib/roguelike/screens/rest_screen.dart`

**의존성:** Task 2 완료 필요

- [ ] **Step 1: 각 화면에서 맵 복귀 직전 save() 추가**

각 화면에서 `context.go('/map')` 호출 직전에:
```dart
await context.read<RunState>().save();
if (context.mounted) context.go('/map');
```

각 화면을 읽어 `/map`으로 이동하는 라우터 호출 위치를 찾아 위 패턴으로 교체.

> **참고:** 호출이 여러 곳(선택 완료, 건너뛰기, 나가기 등)에 있을 수 있으니 모두 찾아서 적용. `async`가 아닌 핸들러는 `async`로 변경.

> **⚠️ 제외 대상:** `lib/roguelike/screens/relic_select_screen.dart`에도 `/map`으로 이동하는 코드가 있으나, 이 화면은 `startRun()` 호출 직후라 `save()`를 호출하면 안 된다(`isActive`가 방금 true로 설정됐지만 저장 타이밍이 의도에 맞지 않음). `relic_select_screen.dart`는 수정하지 않는다.

- [ ] **Step 2: 분석 확인**

```
flutter analyze --no-fatal-infos
```

- [ ] **Step 3: 전체 테스트 통과 확인**

```
flutter test
```

- [ ] **Step 4: 커밋**

```
git add lib/roguelike/screens/upgrade_screen.dart lib/roguelike/screens/shop_screen.dart lib/roguelike/screens/event_screen.dart lib/roguelike/screens/rest_screen.dart
git commit -m "feat: save run state before returning to map from node screens"
```

---

## Phase 3 — 일시정지 오버레이

---

### Task 6: MatchFantasyGame pauseForOverlay / resumeForOverlay

**Files:**
- Modify: `lib/game/match_fantasy_game.dart`

- [ ] **Step 1: 일시정지 메서드 추가**

`match_fantasy_game.dart`에 `_isManuallyPaused` 필드와 두 메서드 추가:

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

`resetSession()`에 리셋 추가:
```dart
_isManuallyPaused = false;
```

- [ ] **Step 2: 분석 확인**

```
flutter analyze --no-fatal-infos
```

- [ ] **Step 3: 전체 테스트 통과 확인**

```
flutter test
```

- [ ] **Step 4: 커밋**

```
git add lib/game/match_fantasy_game.dart
git commit -m "feat: add pauseForOverlay/resumeForOverlay to MatchFantasyGame"
```

---

### Task 7: CombatScreen 일시정지 상태 + PauseOverlay + HUD 버튼

**Files:**
- Modify: `lib/roguelike/screens/combat_screen.dart`
- Modify: `lib/game/ui/game_hud_overlay.dart`

**의존성:** Task 6 완료 필요

- [ ] **Step 1: combat_screen.dart 읽기**

파일을 읽어 현재 `_game` 필드, `GameWidget` 레이아웃, `GameHudOverlay` 통합 방식을 확인한다.

- [ ] **Step 2: CombatScreen에 _isPaused 상태 + PauseOverlay 추가**

`CombatScreen` (`StatefulWidget`)에 추가:

```dart
bool _isPaused = false;

void _togglePause() {
  setState(() {
    _isPaused = !_isPaused;
    if (_isPaused) {
      _game.pauseForOverlay();
    } else {
      _game.resumeForOverlay();
    }
  });
}
```

`build()` 메서드에서 현재 `GameWidget`을 `Stack`으로 감싼다. `GameWidget`의 `overlayBuilderMap` 안에서 `GameHudOverlay`를 생성할 때 `onPause: _togglePause`를 전달한다. `_isPaused`일 때 HUD 입력은 `IgnorePointer`로 차단하고 `_PauseOverlay`를 최상단에 표시한다:

```dart
// build() 반환값:
Stack(
  children: [
    GameWidget<MatchFantasyGame>(
      game: _game,
      overlayBuilderMap: {
        GameHudOverlay.overlayKey: (ctx, game) => IgnorePointer(
          ignoring: _isPaused,                    // 일시정지 중 HUD 입력 차단
          child: GameHudOverlay(
            game: game as MatchFantasyGame,
            onPause: _togglePause,                // ← 여기서 _togglePause 전달
          ),
        ),
      },
    ),
    if (_isPaused) _PauseOverlay(onResume: _togglePause),
  ],
)
```

> **참고:** `GameHudOverlay.overlayKey`는 현재 파일을 읽어 실제 overlay 등록 키 이름을 확인 후 사용. 보통 `'hud'` 또는 클래스에 정의된 상수.

`_PauseOverlay` 위젯 (같은 파일 내 private class):
```dart
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume});
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('일시정지',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onResume,
                  child: const Text('전투 재개'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: GameHudOverlay에 일시정지 버튼 추가**

`lib/game/ui/game_hud_overlay.dart`에서:

`GameHudOverlay`는 현재 `onCombatEnd` 콜백을 받는다. `onPause` 콜백을 추가로 받도록 수정:

```dart
// GameHudOverlay 생성자에 추가:
final VoidCallback? onPause;
```

HUD 레이아웃에서 적절한 위치(레이아웃 버튼 옆)에 일시정지 버튼 추가:
```dart
IconButton(
  icon: const Icon(Icons.pause, color: Colors.white70, size: 20),
  tooltip: '일시정지',
  onPressed: onPause,
),
```

`CombatScreen`에서 `GameHudOverlay` 생성 시 `onPause: _togglePause` 전달.

- [ ] **Step 4: 분석 확인**

```
flutter analyze --no-fatal-infos
```

- [ ] **Step 5: 전체 테스트 통과 확인**

```
flutter test
```
Expected: All tests pass.

- [ ] **Step 6: 커밋**

```
git add lib/roguelike/screens/combat_screen.dart lib/game/ui/game_hud_overlay.dart
git commit -m "feat: add pause overlay to combat screen"
```

---

## 최종 검증

- [ ] **전체 테스트**

```
flutter test
```
Expected: All tests pass.

- [ ] **전체 분석**

```
flutter analyze --no-fatal-infos
```
Expected: No issues found.

- [ ] **수동 확인 체크리스트**
  - [ ] 런 시작 → 상점 진입 → 나가기 → 앱 재시작 → 메인 메뉴에서 "이어하기" 표시
  - [ ] "이어하기" → 맵으로 복귀, 이전 HP/골드/유물 유지
  - [ ] "새 게임 시작" → 저장 삭제, 클래스 선택 화면
  - [ ] 런 완료/실패 후 "이어하기" 버튼 미표시
  - [ ] 전투 중 ⏸ 버튼 → overlay 표시, 적 이동 정지
  - [ ] "전투 재개" → overlay 사라짐, 적 이동 재개
