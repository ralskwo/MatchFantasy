# Roguelike System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** MatchFantasy에 Slay-the-Spire 스타일 로그라이크 레이어를 추가한다 — 노드 맵, 클래스·유물 선택, 런 중 업그레이드 카드, 두 트랙 메타 진행.

**Architecture:** Flutter 라우터가 모든 화면 전환을 담당하고 Flame은 전투 노드에서만 활성화된다. RunState(런 한 번의 상태)와 MetaState(영구 저장)를 ChangeNotifier로 관리하고 provider 패키지로 위젯 트리에 주입한다. 기존 MatchFantasyGame은 RunState를 읽어 파라미터를 적용하고 결과를 돌려쓴다.

**Tech Stack:** Flutter, Flame 1.35.1, provider ^6, shared_preferences ^2, go_router ^14

---

## Phase 1 — 런 골격 (라우팅·상태·화면 뼈대)

---

### Task 1: 의존성 추가

**Files:**
- Modify: `pubspec.yaml`

**Step 1: pubspec.yaml에 패키지 추가**

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flame: ^1.35.1
  provider: ^6.1.2
  shared_preferences: ^2.3.2
  go_router: ^14.3.0
```

**Step 2: 패키지 설치**

```
flutter pub get
```

Expected: 오류 없이 완료.

**Step 3: 분석**

```
flutter analyze --no-fatal-infos
```

Expected: No issues found.

**Step 4: Commit**

```
git add pubspec.yaml pubspec.lock
git commit -m "feat: add provider, shared_preferences, go_router dependencies"
```

---

### Task 2: 디렉터리 구조 생성

**Files:**
- Create: `lib/roguelike/models/player_class.dart`
- Create: `lib/roguelike/models/relic.dart`
- Create: `lib/roguelike/models/upgrade_card.dart`
- Create: `lib/roguelike/models/map_node.dart`
- Create: `lib/roguelike/models/run_map.dart`
- Create: `lib/roguelike/state/run_state.dart`
- Create: `lib/roguelike/state/meta_state.dart`
- Create: `lib/roguelike/screens/main_menu_screen.dart`
- Create: `lib/roguelike/screens/class_select_screen.dart`
- Create: `lib/roguelike/screens/relic_select_screen.dart`
- Create: `lib/roguelike/screens/run_map_screen.dart`
- Create: `lib/roguelike/screens/upgrade_screen.dart`
- Create: `lib/roguelike/screens/shop_screen.dart`
- Create: `lib/roguelike/screens/event_screen.dart`
- Create: `lib/roguelike/screens/rest_screen.dart`
- Create: `lib/roguelike/router.dart`
- Create: `lib/roguelike/data/classes_data.dart`
- Create: `lib/roguelike/data/relics_data.dart`
- Create: `lib/roguelike/data/cards_data.dart`
- Create: `lib/roguelike/data/events_data.dart`

**Step 1: 폴더 생성 (빈 파일로)**

각 파일을 아래 최소 내용으로 생성한다. 빌드 오류만 없으면 된다.

```dart
// lib/roguelike/models/player_class.dart
// TODO: implement
```

(모든 파일 동일하게 // TODO 한 줄)

**Step 2: 분석**

```
flutter analyze --no-fatal-infos
```

**Step 3: Commit**

```
git add lib/roguelike/
git commit -m "feat: scaffold roguelike directory structure"
```

---

### Task 3: 핵심 데이터 모델

**Files:**
- Modify: `lib/roguelike/models/player_class.dart`
- Modify: `lib/roguelike/models/relic.dart`
- Modify: `lib/roguelike/models/upgrade_card.dart`
- Modify: `lib/roguelike/models/map_node.dart`
- Test: `test/roguelike/models_test.dart`

**Step 1: PlayerClass 모델**

```dart
// lib/roguelike/models/player_class.dart
import 'package:match_fantasy/game/models/block_type.dart';

enum PlayerClassId {
  emberKnight,
  tideSage,
  bloomWarden,
  sparkTrickster,
  umbraReaper,
}

class PlayerClass {
  const PlayerClass({
    required this.id,
    required this.name,
    required this.element,
    required this.passiveDescription,
    required this.startingRelicIds,
  });

  final PlayerClassId id;
  final String name;
  final BlockType element;
  final String passiveDescription;
  // 시작 유물 후보 ID 목록 (3개, 이 중 1개 선택)
  final List<String> startingRelicIds;
}
```

**Step 2: Relic 모델**

```dart
// lib/roguelike/models/relic.dart
enum RelicRarity { common, uncommon, rare, boss }

class Relic {
  const Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.effect,
  });

  final String id;
  final String name;
  final String description;
  final RelicRarity rarity;
  // 효과는 Phase 4에서 실제 구현. 여기선 태그만.
  final RelicEffect effect;
}

enum RelicEffectTag {
  startHp, startMana, startGold,
  burstDamage, manaOnMatch, shieldOnBurst,
  meteorCostReduction, slowDuration,
  shopDiscount, onKillMana, onKillShield,
  phoenixRevive, manaOnTick, randomBuffDebuff,
}

class RelicEffect {
  const RelicEffect({required this.tag, this.value = 0.0});
  final RelicEffectTag tag;
  final double value;
}
```

**Step 3: UpgradeCard 모델**

```dart
// lib/roguelike/models/upgrade_card.dart
enum CardKind { passive, active }

class UpgradeCard {
  const UpgradeCard({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    this.usesPerCombat = 0,
    required this.effect,
  });

  final String id;
  final String name;
  final String description;
  final CardKind kind;
  final int usesPerCombat; // active 카드만 의미 있음
  final CardEffect effect;
}

enum CardEffectTag {
  extraClear, specialChance, burstDamage,
  elementSynergyDamage, activeElementClear,
  activeShield, activeTimeStop, activeBoardRefresh,
  manaOnKill, hpOnKill,
}

class CardEffect {
  const CardEffect({required this.tag, this.value = 0.0});
  final CardEffectTag tag;
  final double value;
}
```

**Step 4: MapNode 모델**

```dart
// lib/roguelike/models/map_node.dart
enum NodeType { combat, elite, shop, event, rest, boss }

class MapNode {
  MapNode({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
    this.isVisited = false,
    this.isAvailable = false,
    this.nextNodeIds = const [],
  });

  final String id;
  final NodeType type;
  final int row;
  final int col;
  bool isVisited;
  bool isAvailable;
  final List<String> nextNodeIds;
}
```

**Step 5: 단위 테스트 작성**

```dart
// test/roguelike/models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';
import 'package:match_fantasy/roguelike/models/map_node.dart';
import 'package:match_fantasy/game/models/block_type.dart';

void main() {
  group('PlayerClass', () {
    test('has required fields', () {
      const cls = PlayerClass(
        id: PlayerClassId.emberKnight,
        name: 'Ember Knight',
        element: BlockType.ember,
        passiveDescription: 'Ember 버스트 데미지 +30%',
        startingRelicIds: ['flame_seal', 'mana_crystal', 'lucky_coin'],
      );
      expect(cls.id, PlayerClassId.emberKnight);
      expect(cls.startingRelicIds.length, 3);
    });
  });

  group('MapNode', () {
    test('starts not visited and not available', () {
      final node = MapNode(id: 'n1', type: NodeType.combat, row: 0, col: 0);
      expect(node.isVisited, false);
      expect(node.isAvailable, false);
    });
  });
}
```

**Step 6: 테스트 실행**

```
flutter test test/roguelike/models_test.dart
```

Expected: PASS 2 tests.

**Step 7: Commit**

```
git add lib/roguelike/models/ test/roguelike/
git commit -m "feat: add roguelike core data models"
```

---

### Task 4: 데이터 정의 (클래스·유물·카드·이벤트)

**Files:**
- Modify: `lib/roguelike/data/classes_data.dart`
- Modify: `lib/roguelike/data/relics_data.dart`
- Modify: `lib/roguelike/data/cards_data.dart`
- Modify: `lib/roguelike/data/events_data.dart`

**Step 1: classes_data.dart**

```dart
// lib/roguelike/data/classes_data.dart
import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';

const List<PlayerClass> allClasses = [
  PlayerClass(
    id: PlayerClassId.emberKnight,
    name: 'Ember Knight',
    element: BlockType.ember,
    passiveDescription: 'Ember 버스트 데미지 +30%',
    startingRelicIds: ['flame_seal', 'mana_crystal', 'lucky_coin'],
  ),
  PlayerClass(
    id: PlayerClassId.tideSage,
    name: 'Tide Sage',
    element: BlockType.tide,
    passiveDescription: 'Tide 매치 시 마나 2배 회복',
    startingRelicIds: ['tidal_stone', 'worn_helmet', 'mana_crystal'],
  ),
  PlayerClass(
    id: PlayerClassId.bloomWarden,
    name: 'Bloom Warden',
    element: BlockType.bloom,
    passiveDescription: 'Bloom 버스트 시 실드 +3 추가 부여',
    startingRelicIds: ['life_seed', 'fragment_armor', 'worn_helmet'],
  ),
  PlayerClass(
    id: PlayerClassId.sparkTrickster,
    name: 'Spark Trickster',
    element: BlockType.spark,
    passiveDescription: 'Spark 슬로우 효과 지속 2배',
    startingRelicIds: ['lightning_feather', 'mana_crystal', 'lucky_coin'],
  ),
  PlayerClass(
    id: PlayerClassId.umbraReaper,
    name: 'Umbra Reaper',
    element: BlockType.umbra,
    passiveDescription: 'Umbra AOE 범위 +1칸',
    startingRelicIds: ['dark_scythe', 'fragment_armor', 'worn_helmet'],
  ),
];
```

**Step 2: relics_data.dart**

```dart
// lib/roguelike/data/relics_data.dart
import 'package:match_fantasy/roguelike/models/relic.dart';

const List<Relic> allRelics = [
  // Common
  Relic(id: 'worn_helmet', name: '낡은 투구', rarity: RelicRarity.common,
    description: '전투 시작 HP +3',
    effect: RelicEffect(tag: RelicEffectTag.startHp, value: 3)),
  Relic(id: 'mana_crystal', name: '마나 결정', rarity: RelicRarity.common,
    description: '매치 5회마다 마나 +5',
    effect: RelicEffect(tag: RelicEffectTag.manaOnMatch, value: 5)),
  Relic(id: 'lucky_coin', name: '행운의 동전', rarity: RelicRarity.common,
    description: '상점 가격 -10%',
    effect: RelicEffect(tag: RelicEffectTag.shopDiscount, value: 0.10)),
  Relic(id: 'flame_seal', name: '불꽃 인장', rarity: RelicRarity.common,
    description: 'Ember 버스트 데미지 +15%',
    effect: RelicEffect(tag: RelicEffectTag.burstDamage, value: 0.15)),
  Relic(id: 'tidal_stone', name: '조류석', rarity: RelicRarity.common,
    description: '메테오 마나 비용 -10',
    effect: RelicEffect(tag: RelicEffectTag.meteorCostReduction, value: 10)),
  Relic(id: 'life_seed', name: '생명의 씨앗', rarity: RelicRarity.common,
    description: '전투 시작 HP +5',
    effect: RelicEffect(tag: RelicEffectTag.startHp, value: 5)),
  Relic(id: 'lightning_feather', name: '번개 깃털', rarity: RelicRarity.common,
    description: 'Spark 슬로우 지속 +0.5초',
    effect: RelicEffect(tag: RelicEffectTag.slowDuration, value: 0.5)),
  Relic(id: 'dark_scythe', name: '어둠의 낫', rarity: RelicRarity.common,
    description: '몬스터 처치 시 마나 +3',
    effect: RelicEffect(tag: RelicEffectTag.onKillMana, value: 3)),
  Relic(id: 'fragment_armor', name: '파편 갑옷', rarity: RelicRarity.common,
    description: '몬스터 처치마다 실드 +1',
    effect: RelicEffect(tag: RelicEffectTag.onKillShield, value: 1)),

  // Uncommon
  Relic(id: 'twin_element_stone', name: '쌍둥이 원소석', rarity: RelicRarity.uncommon,
    description: '2가지 원소 동시 버스트 시 데미지 +25%',
    effect: RelicEffect(tag: RelicEffectTag.burstDamage, value: 0.25)),
  Relic(id: 'hourglass', name: '모래시계', rarity: RelicRarity.uncommon,
    description: '메테오 발동 시 3초 몬스터 정지',
    effect: RelicEffect(tag: RelicEffectTag.meteorCostReduction, value: 0)),
  Relic(id: 'shield_core', name: '보호 핵', rarity: RelicRarity.uncommon,
    description: 'Bloom 버스트 시 실드 +5',
    effect: RelicEffect(tag: RelicEffectTag.shieldOnBurst, value: 5)),

  // Rare
  Relic(id: 'phoenix_feather', name: '피닉스 깃털', rarity: RelicRarity.rare,
    description: '런 중 1회 HP 1에서 부활, 절반 회복',
    effect: RelicEffect(tag: RelicEffectTag.phoenixRevive, value: 1)),
  Relic(id: 'element_resonance', name: '원소 공명', rarity: RelicRarity.rare,
    description: '보드에 같은 원소 4개 이상 시 매 초 마나 +1',
    effect: RelicEffect(tag: RelicEffectTag.manaOnTick, value: 1)),
  Relic(id: 'chaos_dice', name: '혼돈의 주사위', rarity: RelicRarity.rare,
    description: '매 웨이브 시작 시 랜덤 버프/디버프',
    effect: RelicEffect(tag: RelicEffectTag.randomBuffDebuff, value: 0)),

  // Boss
  Relic(id: 'kings_seal', name: '왕의 인장', rarity: RelicRarity.boss,
    description: '모든 원소 버스트 데미지 +15%',
    effect: RelicEffect(tag: RelicEffectTag.burstDamage, value: 0.15)),
  Relic(id: 'heart_of_time', name: '시간의 심장', rarity: RelicRarity.boss,
    description: '메테오 발동마다 최전방 몬스터 즉사',
    effect: RelicEffect(tag: RelicEffectTag.onKillMana, value: 0)),
  Relic(id: 'void_core', name: '공허의 핵', rarity: RelicRarity.boss,
    description: 'Umbra 버스트 시 처치 수만큼 마나 회복',
    effect: RelicEffect(tag: RelicEffectTag.onKillMana, value: 0)),
];

Relic relicById(String id) =>
    allRelics.firstWhere((r) => r.id == id);

List<Relic> relicsByRarity(RelicRarity rarity) =>
    allRelics.where((r) => r.rarity == rarity).toList();
```

**Step 3: cards_data.dart**

```dart
// lib/roguelike/data/cards_data.dart
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';

const List<UpgradeCard> allCards = [
  // Passive
  UpgradeCard(id: 'extra_clear', name: '연쇄 클리어', kind: CardKind.passive,
    description: '3매치 시 인접 타일 1개 추가 클리어',
    effect: CardEffect(tag: CardEffectTag.extraClear, value: 1)),
  UpgradeCard(id: 'special_chance', name: '스페셜 기회', kind: CardKind.passive,
    description: '스페셜 젬 생성 확률 +15%',
    effect: CardEffect(tag: CardEffectTag.specialChance, value: 0.15)),
  UpgradeCard(id: 'burst_boost', name: '버스트 증폭', kind: CardKind.passive,
    description: '버스트 데미지 +10%',
    effect: CardEffect(tag: CardEffectTag.burstDamage, value: 0.10)),
  UpgradeCard(id: 'element_synergy', name: '원소 시너지', kind: CardKind.passive,
    description: 'Ember+Tide 연속 버스트 시 데미지 +20%',
    effect: CardEffect(tag: CardEffectTag.elementSynergyDamage, value: 0.20)),
  UpgradeCard(id: 'mana_on_kill', name: '마나 약탈', kind: CardKind.passive,
    description: '몬스터 처치 시 마나 +2',
    effect: CardEffect(tag: CardEffectTag.manaOnKill, value: 2)),
  UpgradeCard(id: 'hp_on_kill', name: '생명 흡수', kind: CardKind.passive,
    description: '몬스터 처치 시 HP +1 (최대치 초과 불가)',
    effect: CardEffect(tag: CardEffectTag.hpOnKill, value: 1)),

  // Active
  UpgradeCard(id: 'element_burst', name: '원소 폭발', kind: CardKind.active,
    description: '보드의 특정 원소 타일 전부 클리어',
    usesPerCombat: 1,
    effect: CardEffect(tag: CardEffectTag.activeElementClear)),
  UpgradeCard(id: 'shield_charge', name: '보호막 충전', kind: CardKind.active,
    description: '실드 +8 즉시',
    usesPerCombat: 2,
    effect: CardEffect(tag: CardEffectTag.activeShield, value: 8)),
  UpgradeCard(id: 'time_slip', name: '타임 슬립', kind: CardKind.active,
    description: '3초간 몬스터 정지',
    usesPerCombat: 1,
    effect: CardEffect(tag: CardEffectTag.activeTimeStop, value: 3)),
  UpgradeCard(id: 'board_refresh', name: '보드 리프레시', kind: CardKind.active,
    description: '전체 보드 새로고침',
    usesPerCombat: 1,
    effect: CardEffect(tag: CardEffectTag.activeBoardRefresh)),
];

UpgradeCard cardById(String id) =>
    allCards.firstWhere((c) => c.id == id);
```

**Step 4: events_data.dart**

```dart
// lib/roguelike/data/events_data.dart
class EventChoice {
  const EventChoice({
    required this.label,
    required this.description,
    required this.effect,
  });
  final String label;
  final String description;
  final EventOutcome effect;
}

enum EventOutcomeType { gainGold, loseHp, gainRelic, gainCards, gainGoldLoseHp }

class EventOutcome {
  const EventOutcome({required this.type, this.value = 0, this.relicId, this.cardCount = 0});
  final EventOutcomeType type;
  final int value;
  final String? relicId;
  final int cardCount;
}

class GameEvent {
  const GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.choices,
  });
  final String id;
  final String title;
  final String description;
  final List<EventChoice> choices;
}

const List<GameEvent> allEvents = [
  GameEvent(
    id: 'altar',
    title: '버려진 제단',
    description: '희미한 원소의 기운이 감돈다.',
    choices: [
      EventChoice(label: '제물 바치기', description: 'HP -8, Uncommon 유물 획득',
        effect: EventOutcome(type: EventOutcomeType.gainRelic, value: -8)),
      EventChoice(label: '그냥 지나친다', description: '골드 +10',
        effect: EventOutcome(type: EventOutcomeType.gainGold, value: 10)),
    ],
  ),
  GameEvent(
    id: 'merchant',
    title: '수상한 거래',
    description: '싸구려처럼 보이지만 빛이 난다.',
    choices: [
      EventChoice(label: '구매 (골드 -30)', description: '랜덤 카드 3장 획득',
        effect: EventOutcome(type: EventOutcomeType.gainCards, value: -30, cardCount: 3)),
      EventChoice(label: '거절', description: '없음',
        effect: EventOutcome(type: EventOutcomeType.gainGold, value: 0)),
    ],
  ),
  GameEvent(
    id: 'rift',
    title: '원소 균열',
    description: '보드가 흔들린다.',
    choices: [
      EventChoice(label: '수용', description: '버스트 데미지 +15%, 다음 전투 HP -5',
        effect: EventOutcome(type: EventOutcomeType.gainGoldLoseHp, value: -5)),
      EventChoice(label: '봉인', description: '골드 +20',
        effect: EventOutcome(type: EventOutcomeType.gainGold, value: 20)),
    ],
  ),
];
```

**Step 5: 분석**

```
flutter analyze --no-fatal-infos
```

**Step 6: Commit**

```
git add lib/roguelike/data/
git commit -m "feat: add roguelike data definitions (classes, relics, cards, events)"
```

---

### Task 5: RunState & MetaState

**Files:**
- Modify: `lib/roguelike/state/run_state.dart`
- Modify: `lib/roguelike/state/meta_state.dart`
- Test: `test/roguelike/state_test.dart`

**Step 1: RunState**

```dart
// lib/roguelike/state/run_state.dart
import 'package:flutter/foundation.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';
import 'package:match_fantasy/roguelike/models/run_map.dart';

class RunState extends ChangeNotifier {
  static const int maxCards = 10;

  PlayerClass? selectedClass;
  List<Relic> relics = [];
  List<UpgradeCard> cards = [];
  RunMap? map;
  String? currentNodeId;
  int health = 30;
  int maxHealth = 30;
  int gold = 0;
  int actNumber = 1;
  bool isActive = false;

  // 런 시작
  void startRun({
    required PlayerClass playerClass,
    required Relic startingRelic,
    required RunMap runMap,
  }) {
    selectedClass = playerClass;
    relics = [startingRelic];
    cards = [];
    map = runMap;
    currentNodeId = runMap.startNodeId;
    maxHealth = 30;
    health = maxHealth;
    gold = 20;
    actNumber = 1;
    isActive = true;
    notifyListeners();
  }

  void addRelic(Relic relic) {
    relics.add(relic);
    notifyListeners();
  }

  void addCard(UpgradeCard card) {
    if (cards.length < maxCards) {
      cards.add(card);
      notifyListeners();
    }
  }

  void removeCard(String cardId) {
    cards.removeWhere((c) => c.id == cardId);
    notifyListeners();
  }

  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
    notifyListeners();
  }

  void takeDamage(int amount) {
    health = (health - amount).clamp(0, maxHealth);
    notifyListeners();
  }

  void spendGold(int amount) {
    gold = (gold - amount).clamp(0, 9999);
    notifyListeners();
  }

  void earnGold(int amount) {
    gold += amount;
    notifyListeners();
  }

  void visitNode(String nodeId) {
    map?.visitNode(nodeId);
    currentNodeId = nodeId;
    notifyListeners();
  }

  void endRun() {
    isActive = false;
    notifyListeners();
  }

  bool get isDead => health <= 0;
  bool hasRelic(String id) => relics.any((r) => r.id == id);
}
```

**Step 2: RunMap 모델**

```dart
// lib/roguelike/models/run_map.dart
import 'dart:math';
import 'package:match_fantasy/roguelike/models/map_node.dart';

class RunMap {
  RunMap({required this.nodes, required this.startNodeId});

  final Map<String, MapNode> nodes;
  final String startNodeId;

  void visitNode(String nodeId) {
    final node = nodes[nodeId];
    if (node == null) return;
    node.isVisited = true;
    // 다음 노드들을 available로 표시
    for (final nextId in node.nextNodeIds) {
      nodes[nextId]?.isAvailable = true;
    }
  }

  List<MapNode> get availableNodes =>
      nodes.values.where((n) => n.isAvailable && !n.isVisited).toList();

  static RunMap generate({required int seed, required int actRows}) {
    final rng = Random(seed);
    final nodes = <String, MapNode>{};
    const int cols = 3;

    // 행별로 노드 생성
    for (int row = 0; row < actRows; row++) {
      final nodeCols = row == actRows - 1 ? 1 : (2 + rng.nextInt(2)); // 보스 행은 1개
      for (int col = 0; col < nodeCols; col++) {
        final id = 'n_${row}_$col';
        final type = row == actRows - 1
            ? NodeType.boss
            : _pickNodeType(rng, row);
        nodes[id] = MapNode(
          id: id,
          type: type,
          row: row,
          col: col,
        );
      }
    }

    // 연결 생성: 각 노드의 nextNodeIds 설정
    for (int row = 0; row < actRows - 1; row++) {
      final currentRowNodes = nodes.values.where((n) => n.row == row).toList();
      final nextRowNodes = nodes.values.where((n) => n.row == row + 1).toList();
      for (final node in currentRowNodes) {
        final next = nextRowNodes[rng.nextInt(nextRowNodes.length)];
        if (!node.nextNodeIds.contains(next.id)) {
          node.nextNodeIds.add(next.id);
        }
      }
    }

    // 시작 노드 설정
    final startNode = nodes.values.firstWhere((n) => n.row == 0);
    startNode.isAvailable = true;

    return RunMap(nodes: nodes, startNodeId: startNode.id);
  }

  static NodeType _pickNodeType(Random rng, int row) {
    final roll = rng.nextDouble();
    if (roll < 0.50) return NodeType.combat;
    if (roll < 0.60) return NodeType.elite;
    if (roll < 0.75) return NodeType.shop;
    if (roll < 0.90) return NodeType.event;
    return NodeType.rest;
  }
}
```

**Step 3: MetaState**

```dart
// lib/roguelike/state/meta_state.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';

class MetaState extends ChangeNotifier {
  static const _key = 'meta_state_v1';

  int currency = 0;
  Set<String> unlockedClassIds = {PlayerClassId.emberKnight.name};
  Set<String> unlockedRelicIds = {'worn_helmet', 'mana_crystal', 'lucky_coin',
    'flame_seal', 'fragment_armor'};
  Map<String, int> achievementProgress = {};
  Map<String, int> highScores = {};
  int totalRuns = 0;
  int totalKills = 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      notifyListeners();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_toJson()));
  }

  void addCurrency(int amount) {
    currency += amount;
    save();
    notifyListeners();
  }

  void spendCurrency(int amount) {
    currency = (currency - amount).clamp(0, 999999);
    save();
    notifyListeners();
  }

  void unlockClass(String id) {
    unlockedClassIds.add(id);
    save();
    notifyListeners();
  }

  void unlockRelic(String id) {
    unlockedRelicIds.add(id);
    save();
    notifyListeners();
  }

  void incrementAchievement(String key, {int by = 1}) {
    achievementProgress[key] = (achievementProgress[key] ?? 0) + by;
    save();
    notifyListeners();
  }

  void recordRunEnd({required int nodesCleared, required int kills,
      required int hpLeft, required bool act3Cleared}) {
    totalRuns++;
    totalKills += kills;
    int earned = nodesCleared * 5 + kills * 1 + hpLeft * 2;
    if (act3Cleared) earned += 100;
    addCurrency(earned);
    save();
    notifyListeners();
  }

  Map<String, dynamic> _toJson() => {
    'currency': currency,
    'unlockedClassIds': unlockedClassIds.toList(),
    'unlockedRelicIds': unlockedRelicIds.toList(),
    'achievementProgress': achievementProgress,
    'highScores': highScores,
    'totalRuns': totalRuns,
    'totalKills': totalKills,
  };

  void _fromJson(Map<String, dynamic> j) {
    currency = j['currency'] as int? ?? 0;
    unlockedClassIds = Set<String>.from(j['unlockedClassIds'] as List? ?? []);
    unlockedRelicIds = Set<String>.from(j['unlockedRelicIds'] as List? ?? []);
    achievementProgress = Map<String, int>.from(j['achievementProgress'] as Map? ?? {});
    highScores = Map<String, int>.from(j['highScores'] as Map? ?? {});
    totalRuns = j['totalRuns'] as int? ?? 0;
    totalKills = j['totalKills'] as int? ?? 0;
  }
}
```

**Step 4: 단위 테스트**

```dart
// test/roguelike/state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';

void main() {
  group('RunState', () {
    late RunState state;
    setUp(() => state = RunState());

    test('heal clamps to maxHealth', () {
      state.maxHealth = 30;
      state.health = 25;
      state.heal(10);
      expect(state.health, 30);
    });

    test('takeDamage clamps to 0', () {
      state.health = 5;
      state.takeDamage(10);
      expect(state.health, 0);
      expect(state.isDead, true);
    });

    test('addCard up to maxCards', () {
      for (int i = 0; i < RunState.maxCards; i++) {
        state.addCard(UpgradeCard(
          id: 'c$i', name: 'Card $i', kind: CardKind.passive,
          description: '', effect: CardEffect(tag: CardEffectTag.burstDamage)));
      }
      expect(state.cards.length, RunState.maxCards);
      // 초과 추가 무시
      state.addCard(UpgradeCard(
        id: 'overflow', name: 'Over', kind: CardKind.passive,
        description: '', effect: CardEffect(tag: CardEffectTag.burstDamage)));
      expect(state.cards.length, RunState.maxCards);
    });
  });
}
```

**Step 5: 테스트 실행**

```
flutter test test/roguelike/state_test.dart
```

Expected: PASS 3 tests.

**Step 6: Commit**

```
git add lib/roguelike/state/ lib/roguelike/models/run_map.dart test/roguelike/state_test.dart
git commit -m "feat: add RunState, MetaState, RunMap with persistence"
```

---

### Task 6: 앱 라우팅 연결

**Files:**
- Modify: `lib/roguelike/router.dart`
- Modify: `lib/app/match_fantasy_app.dart`
- Modify: `lib/main.dart`

**Step 1: router.dart**

```dart
// lib/roguelike/router.dart
import 'package:go_router/go_router.dart';
import 'package:match_fantasy/roguelike/screens/main_menu_screen.dart';
import 'package:match_fantasy/roguelike/screens/class_select_screen.dart';
import 'package:match_fantasy/roguelike/screens/relic_select_screen.dart';
import 'package:match_fantasy/roguelike/screens/run_map_screen.dart';
import 'package:match_fantasy/roguelike/screens/upgrade_screen.dart';
import 'package:match_fantasy/roguelike/screens/shop_screen.dart';
import 'package:match_fantasy/roguelike/screens/event_screen.dart';
import 'package:match_fantasy/roguelike/screens/rest_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',          builder: (ctx, state) => const MainMenuScreen()),
    GoRoute(path: '/class',     builder: (ctx, state) => const ClassSelectScreen()),
    GoRoute(path: '/relic',     builder: (ctx, state) => const RelicSelectScreen()),
    GoRoute(path: '/map',       builder: (ctx, state) => const RunMapScreen()),
    GoRoute(path: '/upgrade',   builder: (ctx, state) => const UpgradeScreen()),
    GoRoute(path: '/shop',      builder: (ctx, state) => const ShopScreen()),
    GoRoute(path: '/event',     builder: (ctx, state) => const EventScreen()),
    GoRoute(path: '/rest',      builder: (ctx, state) => const RestScreen()),
  ],
);
```

**Step 2: match_fantasy_app.dart 수정**

기존 `MaterialApp`을 `MaterialApp.router`로 교체하고 provider 주입.

```dart
// lib/app/match_fantasy_app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/router.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';
import 'package:match_fantasy/game/ui/game_palette.dart';

class MatchFantasyApp extends StatelessWidget {
  const MatchFantasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: GamePalette.accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: GamePalette.accent,
      secondary: GamePalette.secondaryAccent,
      surface: const Color(0xFF12233A),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MetaState()),
        ChangeNotifierProvider(create: (_) => RunState()),
      ],
      child: MaterialApp.router(
        title: 'Match Fantasy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: GamePalette.backgroundTop,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
```

**Step 3: main.dart에서 MetaState 로드**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/app/match_fantasy_app.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // MetaState를 앱 시작 전에 미리 로드
  final meta = MetaState();
  await meta.load();

  runApp(
    ChangeNotifierProvider.value(
      value: meta,
      child: const MatchFantasyApp(),
    ),
  );
}
```

> 참고: `MatchFantasyApp` 내부에서 중복 Provider가 생기지 않도록 main.dart의 MetaState를 앱이 그대로 소비하게 한다. `MatchFantasyApp`의 MultiProvider에서 MetaState는 제거하고 RunState만 남긴다.

**Step 4: 분석**

```
flutter analyze --no-fatal-infos
```

**Step 5: Commit**

```
git add lib/roguelike/router.dart lib/app/match_fantasy_app.dart lib/main.dart
git commit -m "feat: wire go_router and provider for roguelike navigation"
```

---

### Task 7: 화면 뼈대 (MainMenu → ClassSelect → RelicSelect → RunMap)

**Files:**
- Modify: `lib/roguelike/screens/main_menu_screen.dart`
- Modify: `lib/roguelike/screens/class_select_screen.dart`
- Modify: `lib/roguelike/screens/relic_select_screen.dart`
- Modify: `lib/roguelike/screens/run_map_screen.dart`

이 태스크에서는 실제 비주얼보다 **내비게이션 흐름**이 목표다.

**Step 1: MainMenuScreen**

```dart
// lib/roguelike/screens/main_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('MATCH FANTASY',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                color: Colors.white)),
            const SizedBox(height: 48),
            FilledButton(
              onPressed: () => context.push('/class'),
              child: const Text('새 게임 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: ClassSelectScreen**

```dart
// lib/roguelike/screens/class_select_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/data/classes_data.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';

class ClassSelectScreen extends StatefulWidget {
  const ClassSelectScreen({super.key});

  @override
  State<ClassSelectScreen> createState() => _ClassSelectScreenState();
}

class _ClassSelectScreenState extends State<ClassSelectScreen> {
  PlayerClass? _selected;

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<MetaState>();
    final available = allClasses
        .where((c) => meta.unlockedClassIds.contains(c.id.name))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('클래스 선택')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: available.length,
              itemBuilder: (ctx, i) {
                final cls = available[i];
                final isSelected = _selected?.id == cls.id;
                return Card(
                  color: isSelected
                      ? Theme.of(ctx).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    title: Text(cls.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(cls.passiveDescription),
                    onTap: () => setState(() => _selected = cls),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      context.read<RunState>().selectedClass = _selected;
                      context.push('/relic');
                    },
              child: const Text('선택'),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 3: RelicSelectScreen**

```dart
// lib/roguelike/screens/relic_select_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/models/run_map.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class RelicSelectScreen extends StatefulWidget {
  const RelicSelectScreen({super.key});

  @override
  State<RelicSelectScreen> createState() => _RelicSelectScreenState();
}

class _RelicSelectScreenState extends State<RelicSelectScreen> {
  Relic? _selected;

  @override
  Widget build(BuildContext context) {
    final runState = context.watch<RunState>();
    final cls = runState.selectedClass!;
    final options = cls.startingRelicIds.map(relicById).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('시작 유물 선택')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: options.length,
              itemBuilder: (ctx, i) {
                final relic = options[i];
                final isSelected = _selected?.id == relic.id;
                return Card(
                  color: isSelected
                      ? Theme.of(ctx).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    title: Text(relic.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(relic.description),
                    onTap: () => setState(() => _selected = relic),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      final map = RunMap.generate(
                        seed: DateTime.now().millisecondsSinceEpoch,
                        actRows: 5,
                      );
                      context.read<RunState>().startRun(
                        playerClass: cls,
                        startingRelic: _selected!,
                        runMap: map,
                      );
                      context.go('/map');
                    },
              child: const Text('런 시작'),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: RunMapScreen (뼈대)**

```dart
// lib/roguelike/screens/run_map_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/roguelike/models/map_node.dart';

class RunMapScreen extends StatelessWidget {
  const RunMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunState>();
    final available = run.map?.availableNodes ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Act ${run.actNumber}  HP: ${run.health}/${run.maxHealth}  G: ${run.gold}'),
        automaticallyImplyLeading: false,
      ),
      body: available.isEmpty
          ? const Center(child: Text('Act 클리어!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: available.length,
              itemBuilder: (ctx, i) {
                final node = available[i];
                return Card(
                  child: ListTile(
                    leading: Text(_nodeEmoji(node.type),
                      style: const TextStyle(fontSize: 24)),
                    title: Text(_nodeLabel(node.type)),
                    subtitle: Text('Row ${node.row}, Col ${node.col}'),
                    onTap: () => _handleNodeTap(context, node, run),
                  ),
                );
              },
            ),
    );
  }

  void _handleNodeTap(BuildContext ctx, MapNode node, RunState run) {
    run.visitNode(node.id);
    switch (node.type) {
      case NodeType.combat:
      case NodeType.elite:
      case NodeType.boss:
        ctx.push('/combat'); // Phase 2에서 연결
        break;
      case NodeType.shop:
        ctx.push('/shop');
        break;
      case NodeType.event:
        ctx.push('/event');
        break;
      case NodeType.rest:
        ctx.push('/rest');
        break;
    }
  }

  String _nodeEmoji(NodeType t) => switch (t) {
    NodeType.combat => '⚔️',
    NodeType.elite  => '💀',
    NodeType.shop   => '🏪',
    NodeType.event  => '📜',
    NodeType.rest   => '😴',
    NodeType.boss   => '👑',
  };

  String _nodeLabel(NodeType t) => switch (t) {
    NodeType.combat => '전투',
    NodeType.elite  => '엘리트 전투',
    NodeType.shop   => '상점',
    NodeType.event  => '이벤트',
    NodeType.rest   => '휴식',
    NodeType.boss   => '보스',
  };
}
```

**Step 5: 분석 + 실행 확인**

```
flutter analyze --no-fatal-infos
flutter run -d windows
```

Expected: 메인 메뉴 → 클래스 선택 → 유물 선택 → 맵 화면 노드 목록까지 내비게이션 동작.

**Step 6: Commit**

```
git add lib/roguelike/screens/
git commit -m "feat: add roguelike screen shells with navigation flow"
```

---

## Phase 2 — 전투 연동

---

### Task 8: Flame 전투를 라우트로 분리

**Files:**
- Create: `lib/roguelike/screens/combat_screen.dart`
- Modify: `lib/roguelike/router.dart`
- Modify: `lib/game/match_fantasy_game.dart`

**Step 1: CombatScreen 생성**

```dart
// lib/roguelike/screens/combat_screen.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/game/match_fantasy_game.dart';
import 'package:match_fantasy/game/ui/game_hud_overlay.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  late final MatchFantasyGame _game;

  @override
  void initState() {
    super.initState();
    final run = context.read<RunState>();
    _game = MatchFantasyGame(runState: run);
    _game.onCombatEnd = _onCombatEnd;
  }

  @override
  void dispose() {
    _game.disposeHud();
    super.dispose();
  }

  void _onCombatEnd({
    required bool victory,
    required int hpRemaining,
    required int goldEarned,
    required int kills,
  }) {
    final run = context.read<RunState>();
    run.heal(hpRemaining - run.health); // HP 동기화
    run.earnGold(goldEarned);
    if (!victory || run.isDead) {
      // 런 종료
      context.read<RunState>().endRun();
      context.go('/');
    } else {
      context.go('/upgrade');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<MatchFantasyGame>(
      game: _game,
      overlayBuilderMap: {
        MatchFantasyGame.hudOverlayId:
          (ctx, game) => GameHudOverlay(game: game),
      },
      initialActiveOverlays: const [MatchFantasyGame.hudOverlayId],
    );
  }
}
```

**Step 2: MatchFantasyGame에 RunState 연결 파라미터 추가**

`MatchFantasyGame` 생성자에 `RunState? runState` 파라미터 추가. `onCombatEnd` 콜백 추가. 게임 오버 시 콜백 호출.

```dart
// lib/game/match_fantasy_game.dart (수정 부분)
class MatchFantasyGame extends FlameGame with TapCallbacks, DragCallbacks {
  MatchFantasyGame({math.Random? random, this.runState})
    : _random = random ?? math.Random() {
    resetSession();
  }

  final RunState? runState;
  void Function({
    required bool victory,
    required int hpRemaining,
    required int goldEarned,
    required int kills,
  })? onCombatEnd;

  int _killCount = 0; // 전투 중 처치 수 추적
```

게임 오버 처리 코드에서 `onCombatEnd?.call(...)` 호출.
`resetSession()`에서 RunState의 HP를 읽어 `resources.health`에 반영.

**Step 3: router.dart에 /combat 추가**

```dart
GoRoute(path: '/combat', builder: (ctx, state) => const CombatScreen()),
```

**Step 4: 분석**

```
flutter analyze --no-fatal-infos
```

**Step 5: Commit**

```
git add lib/roguelike/screens/combat_screen.dart lib/roguelike/router.dart lib/game/match_fantasy_game.dart
git commit -m "feat: wire Flame combat as a routed screen with RunState integration"
```

---

### Task 9: UpgradeScreen (카드 선택)

**Files:**
- Modify: `lib/roguelike/screens/upgrade_screen.dart`

```dart
// lib/roguelike/screens/upgrade_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});
  @override State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  late final List<UpgradeCard> _choices;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final pool = List<UpgradeCard>.of(allCards)..shuffle(rng);
    _choices = pool.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunState>();
    return Scaffold(
      appBar: AppBar(title: const Text('업그레이드 선택'), automaticallyImplyLeading: false),
      body: Column(
        children: [
          ..._choices.map((card) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: ListTile(
                title: Text(card.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(card.description),
                trailing: run.cards.length >= RunState.maxCards
                    ? const Text('덱 가득', style: TextStyle(color: Colors.red))
                    : null,
                onTap: () {
                  context.read<RunState>().addCard(card);
                  context.go('/map');
                },
              ),
            ),
          )),
          TextButton(
            onPressed: () => context.go('/map'),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
    );
  }
}
```

**Commit:**

```
git add lib/roguelike/screens/upgrade_screen.dart
git commit -m "feat: add card upgrade selection screen"
```

---

## Phase 3 — 상점·이벤트·휴식

---

### Task 10: ShopScreen

**Files:**
- Modify: `lib/roguelike/screens/shop_screen.dart`

상점 슬롯: 랜덤 카드 3장 + 유물 2개 + HP 회복 + 카드 제거. 가격은 lucky_coin 유물 여부에 따라 10% 할인.

구현 패턴은 UpgradeScreen과 동일 (랜덤 풀에서 뽑아 ListTile 표시, 골드 차감, 구매 완료 후 `/map`으로).

**Commit:**
```
git commit -m "feat: add shop screen"
```

---

### Task 11: EventScreen & RestScreen

**Files:**
- Modify: `lib/roguelike/screens/event_screen.dart`
- Modify: `lib/roguelike/screens/rest_screen.dart`

**EventScreen:** `allEvents`에서 랜덤 1개 선택, 선택지 버튼 표시, `EventOutcome`에 따라 RunState 수정 후 `/map`으로.

**RestScreen:** 두 버튼 — "HP 30% 회복" / "카드 업그레이드(랜덤 카드 1장 description에 '(강화)' 추가)".

**Commit:**
```
git commit -m "feat: add event and rest screens"
```

---

## Phase 4 — 유물·클래스 효과 실제 적용

---

### Task 12: RelicEffectApplier

**Files:**
- Create: `lib/roguelike/systems/relic_effect_applier.dart`
- Modify: `lib/game/systems/combat_resolver.dart`
- Modify: `lib/game/match_fantasy_game.dart`

**Step 1: RelicEffectApplier 생성**

```dart
// lib/roguelike/systems/relic_effect_applier.dart
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/game/systems/combat_resolver.dart';

class RelicEffectApplier {
  /// 전투 시작 시 RunState 유물 효과 적용
  static void applyOnCombatStart(RunState run, SessionResources resources) {
    for (final relic in run.relics) {
      switch (relic.effect.tag) {
        case RelicEffectTag.startHp:
          resources.heal(relic.effect.value.toInt());
          break;
        case RelicEffectTag.startMana:
          resources.addMana(relic.effect.value.toInt());
          break;
        default:
          break;
      }
    }
  }

  /// 버스트 데미지 배율 합산
  static double burstDamageMultiplier(RunState run) {
    double mult = 1.0;
    for (final relic in run.relics) {
      if (relic.effect.tag == RelicEffectTag.burstDamage) {
        mult += relic.effect.value;
      }
    }
    return mult;
  }

  /// 몬스터 처치 시 추가 효과
  static void applyOnKill(RunState run, SessionResources resources) {
    for (final relic in run.relics) {
      if (relic.effect.tag == RelicEffectTag.onKillMana) {
        resources.addMana(relic.effect.value.toInt());
      }
      if (relic.effect.tag == RelicEffectTag.onKillShield) {
        resources.addShield(relic.effect.value.toInt());
      }
    }
  }
}
```

**Step 2: CombatResolver.resolveClear에 multiplier 파라미터 추가**

`resolveClear`에 `burstDamageMultiplier: double = 1.0` 파라미터 추가, 버스트 데미지 계산 시 곱해줌.

**Step 3: MatchFantasyGame에서 적용**

`_applyBoardResult`에서 `RelicEffectApplier.burstDamageMultiplier(runState!)`를 읽어 `CombatResolver.resolveClear`에 전달. `onCombatStart`에서 `RelicEffectApplier.applyOnCombatStart` 호출.

**Commit:**
```
git commit -m "feat: implement relic effects (startHp, burstDamage, onKill)"
```

---

### Task 13: 클래스 패시브 효과

**Files:**
- Create: `lib/roguelike/systems/class_passive_applier.dart`

클래스 ID별 분기로 해당 원소 버스트 데미지, 마나 회복, 실드 증가 등 처리. `RelicEffectApplier`와 동일한 패턴으로 `MatchFantasyGame`에서 호출.

**Commit:**
```
git commit -m "feat: implement class passive effects"
```

---

## Phase 5 — 메타 진행 UI

---

### Task 14: 업적 추적 연결

**Files:**
- Modify: `lib/roguelike/state/meta_state.dart`
- Modify: `lib/roguelike/screens/combat_screen.dart`

`onCombatEnd` 콜백에서 `meta.incrementAchievement` 호출. 조건 달성 시 자동 해금 확인 로직 추가.

```dart
// meta_state.dart 추가
void checkAchievements() {
  if (!unlockedClassIds.contains(PlayerClassId.bloomWarden.name) &&
      (achievementProgress['act1_boss_clear'] ?? 0) >= 1) {
    unlockClass(PlayerClassId.bloomWarden.name);
  }
  // 나머지 조건도 동일 패턴
}
```

**Commit:**
```
git commit -m "feat: wire achievement tracking and auto-unlock"
```

---

### Task 15: 메인 메뉴 — 해금 트리 UI

**Files:**
- Modify: `lib/roguelike/screens/main_menu_screen.dart`

현재 런 골드, 해금 가능한 항목(Tier별), 구매 버튼 표시. `MetaState.spendCurrency` 호출 후 해당 클래스/유물 해금.

**Commit:**
```
git commit -m "feat: add meta unlock tree to main menu"
```

---

### Task 16: 최종 분석 & 정리

```
flutter analyze --no-fatal-infos
flutter test
```

Expected: 모든 테스트 PASS, 분석 이슈 0.

```
git add .
git commit -m "feat: complete roguelike system integration"
```

---

## 주의사항

- `MatchFantasyGame`의 `runState`가 null일 때 (기존 단독 실행 경로)는 기존 동작 유지
- `RunMap.nextNodeIds`는 `List<String>`이지만 `MapNode` 생성자에서 `const []`로 초기화되므로 수정 시 새 리스트로 교체 필요
- Phase 4 유물 효과 중 `phoenixRevive`, `manaOnTick`, `randomBuffDebuff`는 게임 루프(`update`)에서 처리 필요 — `MatchFantasyGame.update(dt)`에 별도 `_tickRelicEffects(dt)` 메서드 추가
