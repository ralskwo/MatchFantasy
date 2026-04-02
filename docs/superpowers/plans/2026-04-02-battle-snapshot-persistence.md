# Battle Snapshot Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앱을 종료하거나 일시정지해도 전투 중 상태(보드, 웨이브, 체력, 차지 등)를 복원할 수 있도록 전투 스냅샷을 RunState 세이브에 통합한다.

**Architecture:** 각 전투 런타임 클래스에 `toJson`/`fromJson`을 추가하고, 이를 하나의 `BattleSnapshot` 모델로 묶어 `RunState.pendingBattleSnapshot` 필드에 직렬화한다. `CombatScreen`이 `AppLifecycleState.paused` 시 스냅샷을 저장하고, 재진입 시 복원한다. 버전 필드로 미래 마이그레이션을 준비한다.

**Tech Stack:** Flutter/Dart, `dart:math`, `shared_preferences` (이미 사용 중), Flame 1.35.1

---

## 파일 맵

| 파일 | 변경 내용 |
| --- | --- |
| `lib/game/models/gem_tile.dart` | `toJson()`, `factory GemTile.fromJson()` 추가 |
| `lib/game/models/monster_state.dart` | `toJson()`, `factory MonsterState.fromJson()` 추가 |
| `lib/game/systems/board_engine.dart` | `toJson()`, `factory BoardEngine.fromJson()`, `BoardEngine._restore()` 생성자 추가 |
| `lib/game/systems/wave_controller.dart` | `toJson()`, `factory WaveController.fromJson()`, `WaveController._restore()` 생성자 추가 |
| `lib/game/systems/combat_resolver.dart` | `SessionResources.toJson()`, `factory SessionResources.fromJson()` 추가 |
| `lib/game/models/battle_snapshot.dart` | **NEW** — `BattleSnapshot` 모델 |
| `lib/game/match_fantasy_game.dart` | `toSnapshot()`, `loadSnapshot()` 추가 |
| `lib/roguelike/state/run_state.dart` | `pendingBattleSnapshot` 필드, `setBattleSnapshot`, `clearBattleSnapshot`, save/load 통합 |
| `lib/roguelike/screens/combat_screen.dart` | `WidgetsBindingObserver` 등록, 일시정지 시 저장, 재진입 시 복원, 종료 시 클리어 |
| `test/battle_snapshot_test.dart` | **NEW** — 직렬화 레이어별 단위 테스트 |
| `test/roguelike/run_save_test.dart` | `pendingBattleSnapshot` 저장/복원 테스트 추가 |

---

## Task 1: GemTile + MonsterState 직렬화

**Files:**
- Modify: `lib/game/models/gem_tile.dart`
- Modify: `lib/game/models/monster_state.dart`
- Create: `test/battle_snapshot_test.dart`

- [ ] **Step 1-A: 실패 테스트 작성 — GemTile 직렬화**

`test/battle_snapshot_test.dart` 파일을 생성한다:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/gem_tile.dart';
import 'package:match_fantasy/game/models/monster_state.dart';

void main() {
  group('GemTile serialization', () {
    test('round-trip with special gem', () {
      const original = GemTile(
        id: 7,
        type: BlockType.ember,
        power: 3,
        isStar: true,
        special: GemSpecialKind.cross,
      );
      final json = original.toJson();
      final restored = GemTile.fromJson(json);
      expect(restored.id, 7);
      expect(restored.type, BlockType.ember);
      expect(restored.power, 3);
      expect(restored.isStar, true);
      expect(restored.special, GemSpecialKind.cross);
    });

    test('round-trip with null special', () {
      const original = GemTile(id: 1, type: BlockType.tide, power: 2);
      final restored = GemTile.fromJson(original.toJson());
      expect(restored.special, isNull);
    });
  });

  group('MonsterState serialization', () {
    test('round-trip preserves all mutable fields', () {
      final original = MonsterState(
        id: 3,
        kind: MonsterKind.brute,
        lane: 1,
        maxHealth: 40.0,
        speed: 0.04,
      );
      original.health = 28.0;
      original.progress = 0.55;
      original.slowFactor = 0.5;
      original.slowTimer = 1.2;
      original.hasteFactor = 1.8;
      original.hasteTimer = 0.5;
      original.rushTriggered = true;

      final restored = MonsterState.fromJson(original.toJson());
      expect(restored.id, 3);
      expect(restored.kind, MonsterKind.brute);
      expect(restored.lane, 1);
      expect(restored.maxHealth, 40.0);
      expect(restored.speed, 0.04);
      expect(restored.health, 28.0);
      expect(restored.progress, closeTo(0.55, 1e-9));
      expect(restored.slowFactor, 0.5);
      expect(restored.slowTimer, closeTo(1.2, 1e-9));
      expect(restored.hasteFactor, 1.8);
      expect(restored.hasteTimer, closeTo(0.5, 1e-9));
      expect(restored.rushTriggered, true);
    });
  });
}
```

- [ ] **Step 1-B: 테스트 실행 — 실패 확인**

```bash
flutter test test/battle_snapshot_test.dart
```

Expected: `Error: The method 'toJson' isn't defined for the class 'GemTile'`

- [ ] **Step 1-C: GemTile 직렬화 구현**

`lib/game/models/gem_tile.dart`에 추가:

```dart
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'power': power,
    'isStar': isStar,
    'special': special?.name,
  };

  factory GemTile.fromJson(Map<String, dynamic> json) => GemTile(
    id: json['id'] as int,
    type: BlockType.values.byName(json['type'] as String),
    power: json['power'] as int,
    isStar: (json['isStar'] as bool?) ?? false,
    special: json['special'] == null
        ? null
        : GemSpecialKind.values.byName(json['special'] as String),
  );
```

- [ ] **Step 1-D: MonsterState 직렬화 구현**

`lib/game/models/monster_state.dart`에 추가:

```dart
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind.name,
    'lane': lane,
    'maxHealth': maxHealth,
    'speed': speed,
    'health': health,
    'progress': progress,
    'slowFactor': slowFactor,
    'slowTimer': slowTimer,
    'hasteFactor': hasteFactor,
    'hasteTimer': hasteTimer,
    'rushTriggered': rushTriggered,
  };

  factory MonsterState.fromJson(Map<String, dynamic> json) {
    final m = MonsterState(
      id: json['id'] as int,
      kind: MonsterKind.values.byName(json['kind'] as String),
      lane: json['lane'] as int,
      maxHealth: (json['maxHealth'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
    );
    m.health = (json['health'] as num).toDouble();
    m.progress = (json['progress'] as num).toDouble();
    m.slowFactor = (json['slowFactor'] as num? ?? 1).toDouble();
    m.slowTimer = (json['slowTimer'] as num? ?? 0).toDouble();
    m.hasteFactor = (json['hasteFactor'] as num? ?? 1).toDouble();
    m.hasteTimer = (json['hasteTimer'] as num? ?? 0).toDouble();
    m.rushTriggered = (json['rushTriggered'] as bool?) ?? false;
    return m;
  }
```

- [ ] **Step 1-E: 테스트 실행 — 통과 확인**

```bash
flutter test test/battle_snapshot_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 1-F: flutter analyze**

```bash
flutter analyze --no-fatal-infos
```

Expected: `No issues found!`

- [ ] **Step 1-G: 커밋**

```bash
git add lib/game/models/gem_tile.dart lib/game/models/monster_state.dart test/battle_snapshot_test.dart
git commit -m "feat: add toJson/fromJson to GemTile and MonsterState"
```

---

## Task 2: BoardEngine 직렬화

**Files:**
- Modify: `lib/game/systems/board_engine.dart`
- Modify: `test/battle_snapshot_test.dart`

- [ ] **Step 2-A: 실패 테스트 추가**

`test/battle_snapshot_test.dart`의 `main()` 끝에 추가:

```dart
  group('BoardEngine serialization', () {
    test('round-trip preserves all cells and nextTileId', () {
      import 'dart:math';
      final board = BoardEngine(rows: 3, columns: 3, random: Random(42));
      final original = board.snapshot();
      final json = board.toJson();

      final restored = BoardEngine.fromJson(json, random: Random(1));
      expect(restored.rows, 3);
      expect(restored.columns, 3);
      final restoredSnap = restored.snapshot();
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          expect(restoredSnap[r][c].id, original[r][c].id);
          expect(restoredSnap[r][c].type, original[r][c].type);
          expect(restoredSnap[r][c].power, original[r][c].power);
          expect(restoredSnap[r][c].isStar, original[r][c].isStar);
          expect(restoredSnap[r][c].special, original[r][c].special);
        }
      }
    });
  });
```

**주의:** `dart:math` import가 이미 파일 상단에 없으면 파일 상단에 `import 'dart:math';`를 추가한다.

- [ ] **Step 2-B: BoardEngine 직렬화 구현**

`lib/game/systems/board_engine.dart` 클래스 내부에 아래 메서드와 생성자를 추가한다.

먼저 `_restore` 내부 생성자 추가 (기존 생성자 바로 아래):

```dart
  BoardEngine._restore({
    required this.rows,
    required this.columns,
    required Random random,
  }) : _random = random;
```

그 다음 `toJson` 및 `fromJson` 추가:

```dart
  Map<String, dynamic> toJson() => <String, dynamic>{
    'rows': rows,
    'columns': columns,
    'nextTileId': _nextTileId,
    'cells': snapshot()
        .map((List<GemTile> row) =>
            row.map((GemTile tile) => tile.toJson()).toList())
        .toList(),
  };

  factory BoardEngine.fromJson(
    Map<String, dynamic> json, {
    Random? random,
  }) {
    final int rows = json['rows'] as int;
    final int cols = json['columns'] as int;
    final List<dynamic> rawCells = json['cells'] as List<dynamic>;
    final List<List<GemTile>> cells = List<List<GemTile>>.generate(
      rows,
      (int r) => List<GemTile>.generate(
        cols,
        (int c) => GemTile.fromJson(
          (rawCells[r] as List<dynamic>)[c] as Map<String, dynamic>,
        ),
      ),
    );
    final BoardEngine board = BoardEngine.fromRows(cells, random: random);
    board._nextTileId = json['nextTileId'] as int;
    return board;
  }
```

- [ ] **Step 2-C: 테스트 실행 — 통과 확인**

```bash
flutter test test/battle_snapshot_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 2-D: flutter analyze**

```bash
flutter analyze --no-fatal-infos
```

Expected: `No issues found!`

- [ ] **Step 2-E: 커밋**

```bash
git add lib/game/systems/board_engine.dart test/battle_snapshot_test.dart
git commit -m "feat: add toJson/fromJson to BoardEngine"
```

---

## Task 3: WaveController + SessionResources 직렬화

**Files:**
- Modify: `lib/game/systems/wave_controller.dart`
- Modify: `lib/game/systems/combat_resolver.dart`
- Modify: `test/battle_snapshot_test.dart`

- [ ] **Step 3-A: 실패 테스트 추가**

`test/battle_snapshot_test.dart`의 import 목록에 추가:

```dart
import 'package:match_fantasy/game/systems/combat_resolver.dart';
import 'package:match_fantasy/game/systems/wave_controller.dart';
```

`main()` 끝에 그룹 추가:

```dart
  group('SessionResources serialization', () {
    test('round-trip preserves all fields', () {
      final r = SessionResources(maxHealth: 30, maxMana: 100);
      r.health = 22;
      r.shield = 5;
      r.mana = 60;

      final restored = SessionResources.fromJson(r.toJson());
      expect(restored.maxHealth, 30);
      expect(restored.maxMana, 100);
      expect(restored.health, 22);
      expect(restored.shield, 5);
      expect(restored.mana, 60);
    });
  });

  group('WaveController serialization', () {
    test('round-trip preserves wave number and monsters', () {
      final wave = WaveController(random: Random(42), healthMultiplier: 1.5);
      wave.update(2.5); // 몬스터 스폰 유발
      final json = wave.toJson();

      final restored = WaveController.fromJson(json, random: Random(1));
      expect(restored.waveNumber, wave.waveNumber);
      expect(restored.monsters.length, wave.monsters.length);
      if (wave.monsters.isNotEmpty) {
        expect(restored.monsters.first.id, wave.monsters.first.id);
        expect(restored.monsters.first.kind, wave.monsters.first.kind);
        expect(restored.monsters.first.lane, wave.monsters.first.lane);
        expect(
          restored.monsters.first.health,
          closeTo(wave.monsters.first.health, 1e-6),
        );
        expect(
          restored.monsters.first.progress,
          closeTo(wave.monsters.first.progress, 1e-6),
        );
      }
    });
  });
```

- [ ] **Step 3-B: SessionResources 직렬화 구현**

`lib/game/systems/combat_resolver.dart`의 `SessionResources` 클래스에 추가:

```dart
  Map<String, dynamic> toJson() => <String, dynamic>{
    'maxHealth': maxHealth,
    'maxMana': maxMana,
    'health': health,
    'shield': shield,
    'mana': mana,
  };

  factory SessionResources.fromJson(Map<String, dynamic> json) =>
      SessionResources(
        maxHealth: json['maxHealth'] as int,
        maxMana: json['maxMana'] as int,
      )
        ..health = json['health'] as int
        ..shield = json['shield'] as int
        ..mana = json['mana'] as int;
```

- [ ] **Step 3-C: WaveController 직렬화 구현**

`lib/game/systems/wave_controller.dart`에서 기존 public 생성자 아래에 `_restore` 생성자 추가:

```dart
  WaveController._restore({
    required Random random,
    this.laneCount = 3,
    List<WaveProfile>? profiles,
    this.healthMultiplier = 1.0,
    this.speedMultiplier = 1.0,
    this.spawnIntervalMultiplier = 1.0,
  })  : _random = random,
        _profiles = profiles ?? defaultWaveProfiles;
```

그 다음 `toJson` 및 `fromJson` 추가:

```dart
  Map<String, dynamic> toJson() => <String, dynamic>{
    'waveNumber': waveNumber,
    'profileIndex': _profileIndex,
    'loop': _loop,
    'timeInWave': _timeInWave,
    'spawnTimer': _spawnTimer,
    'bossSkillTimer': _bossSkillTimer,
    'nextMonsterId': _nextMonsterId,
    'laneCount': laneCount,
    'healthMultiplier': healthMultiplier,
    'speedMultiplier': speedMultiplier,
    'spawnIntervalMultiplier': spawnIntervalMultiplier,
    'monsters': monsters
        .map((MonsterState m) => m.toJson())
        .toList(),
  };

  factory WaveController.fromJson(
    Map<String, dynamic> json, {
    Random? random,
    List<WaveProfile>? profiles,
  }) {
    final WaveController controller = WaveController._restore(
      random: random ?? Random(),
      laneCount: (json['laneCount'] as int?) ?? 3,
      profiles: profiles,
      healthMultiplier: (json['healthMultiplier'] as num).toDouble(),
      speedMultiplier: (json['speedMultiplier'] as num).toDouble(),
      spawnIntervalMultiplier:
          (json['spawnIntervalMultiplier'] as num).toDouble(),
    );
    controller.waveNumber = json['waveNumber'] as int;
    controller._profileIndex = json['profileIndex'] as int;
    controller._loop = json['loop'] as int;
    controller._timeInWave = (json['timeInWave'] as num).toDouble();
    controller._spawnTimer = (json['spawnTimer'] as num).toDouble();
    controller._bossSkillTimer = (json['bossSkillTimer'] as num).toDouble();
    controller._nextMonsterId = json['nextMonsterId'] as int;
    for (final dynamic m in json['monsters'] as List<dynamic>) {
      controller.monsters.add(
        MonsterState.fromJson(m as Map<String, dynamic>),
      );
    }
    return controller;
  }
```

- [ ] **Step 3-D: 테스트 실행 — 통과 확인**

```bash
flutter test test/battle_snapshot_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 3-E: flutter analyze**

```bash
flutter analyze --no-fatal-infos
```

Expected: `No issues found!`

- [ ] **Step 3-F: 커밋**

```bash
git add lib/game/systems/wave_controller.dart lib/game/systems/combat_resolver.dart test/battle_snapshot_test.dart
git commit -m "feat: add toJson/fromJson to WaveController and SessionResources"
```

---

## Task 4: BattleSnapshot 모델 + RunState 통합

**Files:**
- Create: `lib/game/models/battle_snapshot.dart`
- Modify: `lib/roguelike/state/run_state.dart`
- Modify: `test/battle_snapshot_test.dart`
- Modify: `test/roguelike/run_save_test.dart`

- [ ] **Step 4-A: 실패 테스트 추가 (BattleSnapshot)**

`test/battle_snapshot_test.dart` import 추가:

```dart
import 'package:match_fantasy/game/models/battle_snapshot.dart';
import 'package:match_fantasy/game/systems/board_engine.dart';
```

`main()` 끝에 그룹 추가:

```dart
  group('BattleSnapshot serialization', () {
    test('round-trip preserves all fields', () {
      final board = BoardEngine(rows: 3, columns: 3, random: Random(1));
      final wave = WaveController(random: Random(2));
      final resources = SessionResources(maxHealth: 30, maxMana: 100);
      resources.health = 22;
      resources.mana = 40;

      final snapshot = BattleSnapshot(
        boardJson: board.toJson(),
        waveJson: wave.toJson(),
        resourcesJson: resources.toJson(),
        elementCharges: const <String, int>{'ember': 3, 'tide': 0},
        itemCharges: const <String, int>{'timeStone': 2},
        killCount: 7,
        score: 1500,
        maxComboThisCombat: 4,
        activeCardUses: const <String, int>{'shield_charge': 1},
        activeCardChargeProgress: const <String, int>{'shield_charge': 5},
        timeStopRemaining: 0.0,
      );

      final restored = BattleSnapshot.fromJson(snapshot.toJson());
      expect(restored.killCount, 7);
      expect(restored.score, 1500);
      expect(restored.maxComboThisCombat, 4);
      expect(restored.elementCharges['ember'], 3);
      expect(restored.elementCharges['tide'], 0);
      expect(restored.itemCharges['timeStone'], 2);
      expect(restored.activeCardUses['shield_charge'], 1);
      expect(restored.activeCardChargeProgress['shield_charge'], 5);
      expect(restored.timeStopRemaining, 0.0);
      expect(restored.boardJson['rows'], 3);
      expect(restored.waveJson['waveNumber'], 1);
      expect(restored.resourcesJson['health'], 22);
    });

    test('fromJson throws FormatException on unknown version', () {
      expect(
        () => BattleSnapshot.fromJson(<String, dynamic>{'version': 999}),
        throwsA(isA<FormatException>()),
      );
    });
  });
```

- [ ] **Step 4-B: BattleSnapshot 모델 구현**

새 파일 `lib/game/models/battle_snapshot.dart` 생성:

```dart
class BattleSnapshot {
  const BattleSnapshot({
    required this.boardJson,
    required this.waveJson,
    required this.resourcesJson,
    required this.elementCharges,
    required this.itemCharges,
    required this.killCount,
    required this.score,
    required this.maxComboThisCombat,
    required this.activeCardUses,
    required this.activeCardChargeProgress,
    required this.timeStopRemaining,
  });

  static const int _currentVersion = 1;

  final Map<String, dynamic> boardJson;
  final Map<String, dynamic> waveJson;
  final Map<String, dynamic> resourcesJson;
  final Map<String, int> elementCharges;
  final Map<String, int> itemCharges;
  final int killCount;
  final int score;
  final int maxComboThisCombat;
  final Map<String, int> activeCardUses;
  final Map<String, int> activeCardChargeProgress;
  final double timeStopRemaining;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': _currentVersion,
    'board': boardJson,
    'wave': waveJson,
    'resources': resourcesJson,
    'elementCharges': elementCharges,
    'itemCharges': itemCharges,
    'killCount': killCount,
    'score': score,
    'maxComboThisCombat': maxComboThisCombat,
    'activeCardUses': activeCardUses,
    'activeCardChargeProgress': activeCardChargeProgress,
    'timeStopRemaining': timeStopRemaining,
  };

  factory BattleSnapshot.fromJson(Map<String, dynamic> json) {
    final int version = (json['version'] as int?) ?? 0;
    if (version != _currentVersion) {
      throw FormatException(
        'Unsupported battle snapshot version: $version',
      );
    }
    return BattleSnapshot(
      boardJson: json['board'] as Map<String, dynamic>,
      waveJson: json['wave'] as Map<String, dynamic>,
      resourcesJson: json['resources'] as Map<String, dynamic>,
      elementCharges: (json['elementCharges'] as Map<String, dynamic>)
          .map((String k, dynamic v) => MapEntry<String, int>(k, v as int)),
      itemCharges: (json['itemCharges'] as Map<String, dynamic>)
          .map((String k, dynamic v) => MapEntry<String, int>(k, v as int)),
      killCount: json['killCount'] as int,
      score: json['score'] as int,
      maxComboThisCombat: json['maxComboThisCombat'] as int,
      activeCardUses: (json['activeCardUses'] as Map<String, dynamic>)
          .map((String k, dynamic v) => MapEntry<String, int>(k, v as int)),
      activeCardChargeProgress:
          (json['activeCardChargeProgress'] as Map<String, dynamic>)
              .map((String k, dynamic v) => MapEntry<String, int>(k, v as int)),
      timeStopRemaining: (json['timeStopRemaining'] as num).toDouble(),
    );
  }
}
```

- [ ] **Step 4-C: RunState에 pendingBattleSnapshot 추가**

`lib/roguelike/state/run_state.dart`에서:

1. import 추가 (파일 상단):
```dart
import 'package:match_fantasy/game/models/battle_snapshot.dart';
```

2. 필드 추가 (기존 `pendingShopOffers` 선언 아래):
```dart
  BattleSnapshot? pendingBattleSnapshot;
```

3. `startRun()` 안 `pendingShopOffers = <ShopOffer>[];` 아래에 추가:
```dart
    pendingBattleSnapshot = null;
```

4. 메서드 추가 (`clearPendingShopOffers` 다음):
```dart
  void setBattleSnapshot(BattleSnapshot snapshot) {
    pendingBattleSnapshot = snapshot;
    notifyListeners();
  }

  void clearBattleSnapshot() {
    pendingBattleSnapshot = null;
    notifyListeners();
  }
```

5. `toSaveJson()` 맵에 추가:
```dart
    'battleSnapshot': pendingBattleSnapshot?.toJson(),
```

6. `fromSaveJson()` 끝부분 (`notifyListeners()` 직전)에 추가:
```dart
    final dynamic rawSnapshot = j['battleSnapshot'];
    pendingBattleSnapshot = rawSnapshot == null
        ? null
        : BattleSnapshot.fromJson(rawSnapshot as Map<String, dynamic>);
```

- [ ] **Step 4-D: run_save_test에 스냅샷 테스트 추가**

`test/roguelike/run_save_test.dart`에 import 추가:

```dart
import 'dart:math';
import 'package:match_fantasy/game/models/battle_snapshot.dart';
import 'package:match_fantasy/game/systems/board_engine.dart';
import 'package:match_fantasy/game/systems/combat_resolver.dart';
import 'package:match_fantasy/game/systems/wave_controller.dart';
```

`'RunState serialization'` 그룹 안에 테스트 추가:

```dart
    test('pendingBattleSnapshot survives toSaveJson/fromSaveJson', () {
      SharedPreferences.setMockInitialValues({});
      final run = RunState();
      run.startRun(
        playerClass: allClasses.first,
        startingRelic: relicById('flame_seal'),
        runMap: RunMap.generate(seed: 0, actRows: 4),
      );

      final board = BoardEngine(rows: 3, columns: 3, random: Random(1));
      final wave = WaveController(random: Random(2));
      final resources = SessionResources(maxHealth: 30, maxMana: 100);
      resources.health = 18;

      run.setBattleSnapshot(BattleSnapshot(
        boardJson: board.toJson(),
        waveJson: wave.toJson(),
        resourcesJson: resources.toJson(),
        elementCharges: const <String, int>{'ember': 5, 'spark': 2},
        itemCharges: const <String, int>{'timeStone': 1},
        killCount: 4,
        score: 1200,
        maxComboThisCombat: 3,
        activeCardUses: const <String, int>{},
        activeCardChargeProgress: const <String, int>{},
        timeStopRemaining: 0.0,
      ));

      final json = run.toSaveJson();
      final restored = RunState()..fromSaveJson(json);

      expect(restored.pendingBattleSnapshot, isNotNull);
      expect(restored.pendingBattleSnapshot!.killCount, 4);
      expect(restored.pendingBattleSnapshot!.score, 1200);
      expect(restored.pendingBattleSnapshot!.maxComboThisCombat, 3);
      expect(restored.pendingBattleSnapshot!.elementCharges['ember'], 5);
      expect(restored.pendingBattleSnapshot!.itemCharges['timeStone'], 1);
      expect(restored.pendingBattleSnapshot!.resourcesJson['health'], 18);
      expect(restored.pendingBattleSnapshot!.boardJson['rows'], 3);
    });

    test('startRun clears pendingBattleSnapshot', () {
      final run = RunState();
      run.startRun(
        playerClass: allClasses.first,
        startingRelic: relicById('flame_seal'),
        runMap: RunMap.generate(seed: 1, actRows: 4),
      );
      run.setBattleSnapshot(BattleSnapshot(
        boardJson: const <String, dynamic>{'rows': 3, 'columns': 3, 'nextTileId': 10, 'cells': []},
        waveJson: const <String, dynamic>{},
        resourcesJson: const <String, dynamic>{},
        elementCharges: const <String, int>{},
        itemCharges: const <String, int>{},
        killCount: 0, score: 0, maxComboThisCombat: 0,
        activeCardUses: const <String, int>{},
        activeCardChargeProgress: const <String, int>{},
        timeStopRemaining: 0.0,
      ));
      expect(run.pendingBattleSnapshot, isNotNull);

      run.startRun(
        playerClass: allClasses.first,
        startingRelic: relicById('flame_seal'),
        runMap: RunMap.generate(seed: 2, actRows: 4),
      );
      expect(run.pendingBattleSnapshot, isNull);
    });
```

- [ ] **Step 4-E: 테스트 실행 — 통과 확인**

```bash
flutter test test/battle_snapshot_test.dart test/roguelike/run_save_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 4-F: flutter analyze**

```bash
flutter analyze --no-fatal-infos
```

Expected: `No issues found!`

- [ ] **Step 4-G: 커밋**

```bash
git add lib/game/models/battle_snapshot.dart lib/roguelike/state/run_state.dart test/battle_snapshot_test.dart test/roguelike/run_save_test.dart
git commit -m "feat: add BattleSnapshot model and integrate into RunState save/load"
```

---

## Task 5: MatchFantasyGame 스냅샷 메서드 + CombatScreen 라이프사이클

**Files:**
- Modify: `lib/game/match_fantasy_game.dart`
- Modify: `lib/roguelike/screens/combat_screen.dart`

- [ ] **Step 5-A: MatchFantasyGame import 추가**

`lib/game/match_fantasy_game.dart` 상단 import 목록에 추가 (아직 없으면):

```dart
import 'package:match_fantasy/game/models/battle_snapshot.dart';
```

- [ ] **Step 5-B: MatchFantasyGame.toSnapshot() 추가**

`_publishHud()` 메서드 근처에 아래 두 메서드를 추가한다. (`resetSession()` 메서드 바로 아래가 적당하다):

```dart
  BattleSnapshot toSnapshot() => BattleSnapshot(
    boardJson: board.toJson(),
    waveJson: wave.toJson(),
    resourcesJson: resources.toJson(),
    elementCharges: _elementCharges.map(
      (BlockType k, int v) => MapEntry<String, int>(k.name, v),
    ),
    itemCharges: _itemCharges.map(
      (ItemType k, int v) => MapEntry<String, int>(k.name, v),
    ),
    killCount: _killCount,
    score: _score,
    maxComboThisCombat: _maxComboThisCombat,
    activeCardUses: Map<String, int>.of(_activeCardUses),
    activeCardChargeProgress: Map<String, int>.of(_activeCardChargeProgress),
    timeStopRemaining: _timeStopRemaining,
  );

  void loadSnapshot(BattleSnapshot snapshot) {
    board = BoardEngine.fromJson(snapshot.boardJson, random: _random);
    wave = WaveController.fromJson(snapshot.waveJson, random: _random);
    resources = SessionResources.fromJson(snapshot.resourcesJson);
    _elementCharges = snapshot.elementCharges.map(
      (String k, int v) => MapEntry<BlockType, int>(BlockType.values.byName(k), v),
    );
    _itemCharges = snapshot.itemCharges.map(
      (String k, int v) => MapEntry<ItemType, int>(ItemType.values.byName(k), v),
    );
    _killCount = snapshot.killCount;
    _score = snapshot.score;
    _maxComboThisCombat = snapshot.maxComboThisCombat;
    _activeCardUses
      ..clear()
      ..addAll(snapshot.activeCardUses);
    _activeCardChargeProgress
      ..clear()
      ..addAll(snapshot.activeCardChargeProgress);
    _timeStopRemaining = snapshot.timeStopRemaining;
    _publishHud();
  }
```

- [ ] **Step 5-C: CombatScreen에 WidgetsBindingObserver 등록**

`lib/roguelike/screens/combat_screen.dart`에서 `_CombatScreenState`의 클래스 선언을 수정한다:

변경 전:
```dart
class _CombatScreenState extends State<CombatScreen> {
```

변경 후:
```dart
class _CombatScreenState extends State<CombatScreen>
    with WidgetsBindingObserver {
```

- [ ] **Step 5-D: CombatScreen 필드 + initState + dispose 수정**

`_CombatScreenState`에 필드 추가:

```dart
  bool _combatEnded = false;
```

`initState()` 안 `super.initState();` 바로 다음 줄에 추가:

```dart
    WidgetsBinding.instance.addObserver(this);
```

`initState()` 안 `_game.onCombatEnd = _onCombatEnd;` 바로 다음에 추가:

```dart
    final RunState run = context.read<RunState>();
    if (run.pendingBattleSnapshot != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _game.loadSnapshot(run.pendingBattleSnapshot!);
        } catch (_) {
          context.read<RunState>().clearBattleSnapshot();
        }
      });
    }
```

기존 `dispose()` 메서드를 수정하거나 없으면 추가:

```dart
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
```

- [ ] **Step 5-E: didChangeAppLifecycleState 추가**

`dispose()` 바로 앞에 추가:

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_combatEnded) {
      _saveSnapshot();
    }
  }

  Future<void> _saveSnapshot() async {
    if (!mounted) return;
    final RunState run = context.read<RunState>();
    run.setBattleSnapshot(_game.toSnapshot());
    await run.save();
  }
```

- [ ] **Step 5-F: _onCombatEnd에 clearBattleSnapshot 추가**

기존 `_onCombatEnd` 콜백에서 `run.recordCombatResult(...)` 호출 바로 앞에 추가:

```dart
    _combatEnded = true;
    run.clearBattleSnapshot();
```

- [ ] **Step 5-G: flutter analyze**

```bash
flutter analyze --no-fatal-infos
```

Expected: `No issues found!`

- [ ] **Step 5-H: 전체 테스트 실행**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 5-I: 커밋**

```bash
git add lib/game/match_fantasy_game.dart lib/roguelike/screens/combat_screen.dart
git commit -m "feat: MatchFantasyGame snapshot save/restore + CombatScreen lifecycle hook"
```

---

## Task 6: 문서 업데이트

**Files:**
- Modify: `docs/plans/2026-03-28-improvement-roadmap.md`
- Modify: `C:/Users/ralskwo/.claude/projects/c--Users-ralskwo-Desktop-Study-Privates-MatchFantasy/memory/MEMORY.md`

- [ ] **Step 6-A: 로드맵 업데이트**

`docs/plans/2026-03-28-improvement-roadmap.md`의 Phase 7 섹션을 completed로 수정하고 Status Table에 반영한다.

- [ ] **Step 6-B: MEMORY.md 업데이트**

Phase 7 구현 내용을 MEMORY.md의 Completed 섹션에 추가한다.

- [ ] **Step 6-C: 커밋**

```bash
git add docs/plans/2026-03-28-improvement-roadmap.md
git commit -m "docs: record Phase 7 battle snapshot persistence in roadmap"
```

---

## 자체 검토

### Spec 커버리지
- [x] 전투 상태 직렬화: GemTile, MonsterState, BoardEngine, WaveController, SessionResources → Task 1–3
- [x] BattleSnapshot 버전 필드 → Task 4 (`version: 1`, FormatException on mismatch)
- [x] RunState 저장/복원 통합 → Task 4
- [x] 앱 일시정지 시 저장 → Task 5 (`didChangeAppLifecycleState`)
- [x] 재진입 시 복원 → Task 5 (`initState` postFrameCallback)
- [x] 전투 종료 시 클리어 → Task 5 (`_onCombatEnd`)
- [x] 오류 시 폴백 → Task 5 (try/catch → `clearBattleSnapshot`)

### Placeholder 스캔
없음. 모든 단계에 실제 코드 포함.

### 타입 일관성
- `BattleSnapshot` 필드명 → Task 4-B에서 정의, Task 4-D 테스트, Task 5-B에서 사용 — 일치
- `BoardEngine.fromJson` → Task 2-B 정의, Task 5-B에서 호출 — 일치
- `WaveController.fromJson` → Task 3-C 정의, Task 5-B에서 호출 — 일치
- `run.clearBattleSnapshot()` → Task 4-C 정의, Task 5-F에서 호출 — 일치
