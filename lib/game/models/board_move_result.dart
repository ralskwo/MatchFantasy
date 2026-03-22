import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/gem_tile.dart';

class ElementClearSummary {
  const ElementClearSummary({
    this.count = 0,
    this.powerTotal = 0,
    this.starCount = 0,
  });

  final int count;
  final int powerTotal;
  final int starCount;

  ElementClearSummary addTile(GemTile tile) {
    return ElementClearSummary(
      count: count + 1,
      powerTotal: powerTotal + tile.power,
      starCount: starCount + (tile.isStar ? 1 : 0),
    );
  }
}

enum MatchBonusType { lineBlast, nova }

class MatchBonus {
  const MatchBonus({
    required this.element,
    required this.bonusType,
    required this.size,
    required this.powerTotal,
    this.starCount = 0,
  });

  final BlockType element;
  final MatchBonusType bonusType;
  final int size;
  final int powerTotal;
  final int starCount;
}

class BoardMoveResult {
  const BoardMoveResult({
    required this.isValid,
    this.clearedByType = const <BlockType, ElementClearSummary>{},
    this.matchBonuses = const <MatchBonus>[],
    this.comboDepth = 0,
    this.clearedTiles = 0,
    this.clearedPower = 0,
    this.initialBoard = const <List<GemTile>>[],
    this.beforeBoard = const <List<GemTile>>[],
    this.afterBoard = const <List<GemTile>>[],
    this.cascadeBoards = const <List<List<GemTile>>>[],
  });

  final bool isValid;
  final Map<BlockType, ElementClearSummary> clearedByType;
  final List<MatchBonus> matchBonuses;
  final int comboDepth;
  final int clearedTiles;
  final int clearedPower;
  final List<List<GemTile>> initialBoard;
  final List<List<GemTile>> beforeBoard;
  final List<List<GemTile>> afterBoard;
  /// Board state after each cascade step (clear → collapse → refill).
  /// cascadeBoards[0] is state after first clear, cascadeBoards[1] after second, etc.
  final List<List<List<GemTile>>> cascadeBoards;
}
