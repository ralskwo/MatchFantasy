import 'package:match_fantasy/roguelike/models/upgrade_card.dart';

const List<UpgradeCard> allCards = [
  // Passive
  UpgradeCard(
    id: 'extra_clear',
    name: '연쇄 클리어',
    kind: CardKind.passive,
    description: '3매치 시 인접 타일 1개 추가 클리어',
    effect: CardEffect(tag: CardEffectTag.extraClear, value: 1),
  ),
  UpgradeCard(
    id: 'special_chance',
    name: '스페셜 기회',
    kind: CardKind.passive,
    description: '스페셜 젬 생성 확률 +15%',
    effect: CardEffect(tag: CardEffectTag.specialChance, value: 0.15),
  ),
  UpgradeCard(
    id: 'burst_boost',
    name: '버스트 증폭',
    kind: CardKind.passive,
    description: '버스트 데미지 +10%',
    effect: CardEffect(tag: CardEffectTag.burstDamage, value: 0.10),
  ),
  UpgradeCard(
    id: 'element_synergy',
    name: '원소 시너지',
    kind: CardKind.passive,
    description: 'Ember+Tide 연속 버스트 시 데미지 +20%',
    effect: CardEffect(tag: CardEffectTag.elementSynergyDamage, value: 0.20),
  ),
  UpgradeCard(
    id: 'mana_on_kill',
    name: '마나 약탈',
    kind: CardKind.passive,
    description: '몬스터 처치 시 마나 +2',
    effect: CardEffect(tag: CardEffectTag.manaOnKill, value: 2),
  ),
  UpgradeCard(
    id: 'hp_on_kill',
    name: '생명 흡수',
    kind: CardKind.passive,
    description: '몬스터 처치 시 HP +1 (최대치 초과 불가)',
    effect: CardEffect(tag: CardEffectTag.hpOnKill, value: 1),
  ),

  // Active
  UpgradeCard(
    id: 'element_burst',
    name: '원소 폭발',
    kind: CardKind.active,
    description: '보드의 특정 원소 타일 전부 클리어',
    usesPerCombat: 1,
    effect: CardEffect(tag: CardEffectTag.activeElementClear),
  ),
  UpgradeCard(
    id: 'shield_charge',
    name: '보호막 충전',
    kind: CardKind.active,
    description: '실드 +8 즉시',
    usesPerCombat: 2,
    effect: CardEffect(tag: CardEffectTag.activeShield, value: 8),
  ),
  UpgradeCard(
    id: 'time_slip',
    name: '타임 슬립',
    kind: CardKind.active,
    description: '3초간 몬스터 정지',
    usesPerCombat: 1,
    effect: CardEffect(tag: CardEffectTag.activeTimeStop, value: 3),
  ),
  UpgradeCard(
    id: 'board_refresh',
    name: '보드 리프레시',
    kind: CardKind.active,
    description: '전체 보드 새로고침',
    usesPerCombat: 1,
    effect: CardEffect(tag: CardEffectTag.activeBoardRefresh),
  ),
];

UpgradeCard cardById(String id) =>
    allCards.firstWhere((c) => c.id == id);
