import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/models/reward_metadata.dart';
import 'package:match_fantasy/roguelike/models/reward_rarity.dart';
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';

const Map<String, RewardMetadata> _cardMetadata = <String, RewardMetadata>{
  'extra_clear': RewardMetadata(
    id: 'extra_clear',
    rarity: RewardRarity.common,
    isActive: false,
  ),
  'special_chance': RewardMetadata(
    id: 'special_chance',
    rarity: RewardRarity.common,
    isActive: false,
  ),
  'burst_boost': RewardMetadata(
    id: 'burst_boost',
    rarity: RewardRarity.common,
    isActive: false,
  ),
  'element_synergy': RewardMetadata(
    id: 'element_synergy',
    rarity: RewardRarity.uncommon,
    isActive: false,
  ),
  'mana_on_kill': RewardMetadata(
    id: 'mana_on_kill',
    rarity: RewardRarity.common,
    isActive: false,
  ),
  'hp_on_kill': RewardMetadata(
    id: 'hp_on_kill',
    rarity: RewardRarity.common,
    isActive: false,
  ),
  'ember_chain': RewardMetadata(
    id: 'ember_chain',
    rarity: RewardRarity.uncommon,
    isActive: false,
  ),
  'tide_leech': RewardMetadata(
    id: 'tide_leech',
    rarity: RewardRarity.uncommon,
    isActive: false,
  ),
  'bloom_fortress': RewardMetadata(
    id: 'bloom_fortress',
    rarity: RewardRarity.uncommon,
    isActive: false,
  ),
  'spark_overload': RewardMetadata(
    id: 'spark_overload',
    rarity: RewardRarity.rare,
    isActive: false,
  ),
  'umbra_reap': RewardMetadata(
    id: 'umbra_reap',
    rarity: RewardRarity.rare,
    isActive: false,
  ),
  'element_burst': RewardMetadata(
    id: 'element_burst',
    rarity: RewardRarity.rare,
    isActive: true,
  ),
  'shield_charge': RewardMetadata(
    id: 'shield_charge',
    rarity: RewardRarity.uncommon,
    isActive: true,
  ),
  'time_slip': RewardMetadata(
    id: 'time_slip',
    rarity: RewardRarity.epic,
    isActive: true,
  ),
  'board_refresh': RewardMetadata(
    id: 'board_refresh',
    rarity: RewardRarity.rare,
    isActive: true,
  ),
};

RewardMetadata rewardMetadataForCard(UpgradeCard card) {
  return _cardMetadata[card.id] ??
      (throw ArgumentError.value(card.id, 'card.id', 'Unknown card metadata'));
}

RewardMetadata rewardMetadataByCardId(String cardId) {
  return _cardMetadata[cardId] ??
      (throw ArgumentError.value(cardId, 'cardId', 'Unknown card metadata'));
}

RewardMetadata rewardMetadataForRelic(Relic relic) {
  final rarity = switch (relic.rarity) {
    RelicRarity.common => RewardRarity.common,
    RelicRarity.uncommon => RewardRarity.uncommon,
    RelicRarity.rare => RewardRarity.rare,
    RelicRarity.boss => RewardRarity.epic,
  };
  return RewardMetadata(
    id: relic.id,
    rarity: rarity,
    isActive: false,
  );
}
