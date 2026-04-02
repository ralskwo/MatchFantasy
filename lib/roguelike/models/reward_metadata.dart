import 'package:match_fantasy/roguelike/models/reward_rarity.dart';

class RewardMetadata {
  const RewardMetadata({
    required this.id,
    required this.rarity,
    required this.isActive,
  });

  final String id;
  final RewardRarity rarity;
  final bool isActive;

  int get weight => rarity.weight;

  int get basePrice => rarity.basePrice + (isActive ? 14 : 0);

  String get rarityLabel => rarity.label;
}
