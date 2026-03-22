import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/game_difficulty.dart';
import 'package:match_fantasy/game/models/item_type.dart';

class HudState {
  const HudState({
    required this.health,
    required this.maxHealth,
    required this.shield,
    required this.mana,
    required this.maxMana,
    required this.score,
    required this.wave,
    required this.monstersOnField,
    required this.statusText,
    required this.isGameOver,
    required this.isMeteorReady,
    required this.elementCharges,
    required this.itemCharges,
    required this.timeStopRemaining,
    required this.armedItem,
    required this.difficulty,
    required this.comboCount,
  });

  final int health;
  final int maxHealth;
  final int shield;
  final int mana;
  final int maxMana;
  final int score;
  final int wave;
  final int monstersOnField;
  final String statusText;
  final bool isGameOver;
  final bool isMeteorReady;
  final Map<BlockType, int> elementCharges;
  final Map<ItemType, int> itemCharges;
  final double timeStopRemaining;
  final ItemType? armedItem;
  final GameDifficulty difficulty;
  final int comboCount;
}
