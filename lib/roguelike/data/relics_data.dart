import 'package:match_fantasy/roguelike/models/relic.dart';

const List<Relic> allRelics = [
  // Common
  Relic(
    id: 'worn_helmet',
    name: '낡은 투구',
    rarity: RelicRarity.common,
    description: '전투 시작 HP +3',
    effect: RelicEffect(tag: RelicEffectTag.startHp, value: 3),
  ),
  Relic(
    id: 'mana_crystal',
    name: '마나 결정',
    rarity: RelicRarity.common,
    description: '매치 5회마다 마나 +5',
    effect: RelicEffect(tag: RelicEffectTag.manaOnMatch, value: 5),
  ),
  Relic(
    id: 'lucky_coin',
    name: '행운의 동전',
    rarity: RelicRarity.common,
    description: '상점 가격 -10%',
    effect: RelicEffect(tag: RelicEffectTag.shopDiscount, value: 0.10),
  ),
  Relic(
    id: 'flame_seal',
    name: '불꽃 인장',
    rarity: RelicRarity.common,
    description: 'Ember 버스트 데미지 +15%',
    effect: RelicEffect(tag: RelicEffectTag.burstDamage, value: 0.15),
  ),
  Relic(
    id: 'tidal_stone',
    name: '조류석',
    rarity: RelicRarity.common,
    description: '메테오 마나 비용 -10',
    effect: RelicEffect(tag: RelicEffectTag.meteorCostReduction, value: 10),
  ),
  Relic(
    id: 'life_seed',
    name: '생명의 씨앗',
    rarity: RelicRarity.common,
    description: '전투 시작 HP +5',
    effect: RelicEffect(tag: RelicEffectTag.startHp, value: 5),
  ),
  Relic(
    id: 'lightning_feather',
    name: '번개 깃털',
    rarity: RelicRarity.common,
    description: 'Spark 슬로우 지속 +0.5초',
    effect: RelicEffect(tag: RelicEffectTag.slowDuration, value: 0.5),
  ),
  Relic(
    id: 'dark_scythe',
    name: '어둠의 낫',
    rarity: RelicRarity.common,
    description: '몬스터 처치 시 마나 +3',
    effect: RelicEffect(tag: RelicEffectTag.onKillMana, value: 3),
  ),
  Relic(
    id: 'fragment_armor',
    name: '파편 갑옷',
    rarity: RelicRarity.common,
    description: '몬스터 처치마다 실드 +1',
    effect: RelicEffect(tag: RelicEffectTag.onKillShield, value: 1),
  ),

  // Uncommon
  Relic(
    id: 'twin_element_stone',
    name: '쌍둥이 원소석',
    rarity: RelicRarity.uncommon,
    description: '2가지 원소 동시 버스트 시 데미지 +25%',
    effect: RelicEffect(tag: RelicEffectTag.burstDamage, value: 0.25),
  ),
  Relic(
    id: 'hourglass',
    name: '모래시계',
    rarity: RelicRarity.uncommon,
    description: '메테오 발동 시 3초 몬스터 정지',
    effect: RelicEffect(tag: RelicEffectTag.meteorCostReduction, value: 0),
  ),
  Relic(
    id: 'shield_core',
    name: '보호 핵',
    rarity: RelicRarity.uncommon,
    description: 'Bloom 버스트 시 실드 +5',
    effect: RelicEffect(tag: RelicEffectTag.shieldOnBurst, value: 5),
  ),

  // Rare
  Relic(
    id: 'phoenix_feather',
    name: '피닉스 깃털',
    rarity: RelicRarity.rare,
    description: '런 중 1회 HP 1에서 부활, 절반 회복',
    effect: RelicEffect(tag: RelicEffectTag.phoenixRevive, value: 1),
  ),
  Relic(
    id: 'element_resonance',
    name: '원소 공명',
    rarity: RelicRarity.rare,
    description: '보드에 같은 원소 4개 이상 시 매 초 마나 +1',
    effect: RelicEffect(tag: RelicEffectTag.manaOnTick, value: 1),
  ),
  Relic(
    id: 'chaos_dice',
    name: '혼돈의 주사위',
    rarity: RelicRarity.rare,
    description: '매 웨이브 시작 시 랜덤 버프/디버프',
    effect: RelicEffect(tag: RelicEffectTag.randomBuffDebuff, value: 0),
  ),
  Relic(
    id: 'ancient_grid_stone',
    name: '고대의 격자석',
    rarity: RelicRarity.rare,
    description: '매치 보드가 6×6 → 7×7로 확장됩니다.',
    effect: RelicEffect(tag: RelicEffectTag.boardExpand, value: 1),
  ),

  // Boss
  Relic(
    id: 'kings_seal',
    name: '왕의 인장',
    rarity: RelicRarity.boss,
    description: '모든 원소 버스트 데미지 +15%',
    effect: RelicEffect(tag: RelicEffectTag.burstDamage, value: 0.15),
  ),
  Relic(
    id: 'heart_of_time',
    name: '시간의 심장',
    rarity: RelicRarity.boss,
    description: '메테오 발동마다 최전방 몬스터 즉사',
    effect: RelicEffect(tag: RelicEffectTag.onKillMana, value: 0),
  ),
  Relic(
    id: 'void_core',
    name: '공허의 핵',
    rarity: RelicRarity.boss,
    description: 'Umbra 버스트 시 처치 수만큼 마나 회복',
    effect: RelicEffect(tag: RelicEffectTag.onKillMana, value: 0),
  ),
];

Relic relicById(String id) =>
    allRelics.firstWhere((r) => r.id == id);

List<Relic> relicsByRarity(RelicRarity rarity) =>
    allRelics.where((r) => r.rarity == rarity).toList();
