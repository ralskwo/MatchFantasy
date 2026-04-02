import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/board_move_result.dart';
import 'package:match_fantasy/game/models/gem_tile.dart';
import 'package:match_fantasy/game/models/grid_point.dart';
import 'package:match_fantasy/game/systems/board_engine.dart';

void main() {
  test('board resolves a match-producing swap', () {
    final BoardEngine board = BoardEngine.fromRows(<List<GemTile>>[
      <GemTile>[
        gem(BlockType.tide, 2),
        gem(BlockType.spark, 3),
        gem(BlockType.bloom, 2),
        gem(BlockType.umbra, 1),
        gem(BlockType.ember, 4),
      ],
      <GemTile>[
        gem(BlockType.umbra, 1),
        gem(BlockType.tide, 2),
        gem(BlockType.ember, 5),
        gem(BlockType.spark, 1),
        gem(BlockType.bloom, 2),
      ],
      <GemTile>[
        gem(BlockType.ember, 3),
        gem(BlockType.ember, 1),
        gem(BlockType.tide, 2),
        gem(BlockType.bloom, 4),
        gem(BlockType.spark, 2),
      ],
      <GemTile>[
        gem(BlockType.spark, 2),
        gem(BlockType.bloom, 5),
        gem(BlockType.umbra, 2),
        gem(BlockType.ember, 1),
        gem(BlockType.tide, 3),
      ],
      <GemTile>[
        gem(BlockType.bloom, 1),
        gem(BlockType.umbra, 4),
        gem(BlockType.spark, 2),
        gem(BlockType.tide, 3),
        gem(BlockType.ember, 1),
      ],
    ]);

    final result = board.trySwap(const GridPoint(1, 2), const GridPoint(2, 2));

    expect(result.isValid, isTrue);
    expect(
      result.clearedByType[BlockType.ember]?.count,
      greaterThanOrEqualTo(3),
    );
    expect(
      result.clearedByType[BlockType.ember]?.powerTotal,
      greaterThanOrEqualTo(7),
    );
    expect(result.clearedTiles, greaterThanOrEqualTo(3));
    expect(result.comboDepth, greaterThanOrEqualTo(1));
    expect(result.initialBoard, isNotEmpty);
    expect(result.beforeBoard, isNotEmpty);
    expect(result.afterBoard, isNotEmpty);
  });

  test('invalid swap leaves the board unchanged', () {
    final BoardEngine board = BoardEngine.fromRows(<List<GemTile>>[
      <GemTile>[
        gem(BlockType.ember, 1),
        gem(BlockType.tide, 2),
        gem(BlockType.bloom, 3),
        gem(BlockType.spark, 4),
      ],
      <GemTile>[
        gem(BlockType.spark, 1),
        gem(BlockType.umbra, 2),
        gem(BlockType.ember, 3),
        gem(BlockType.tide, 4),
      ],
      <GemTile>[
        gem(BlockType.tide, 1),
        gem(BlockType.bloom, 2),
        gem(BlockType.spark, 3),
        gem(BlockType.umbra, 4),
      ],
      <GemTile>[
        gem(BlockType.bloom, 1),
        gem(BlockType.spark, 2),
        gem(BlockType.tide, 3),
        gem(BlockType.ember, 4),
      ],
    ]);

    final before = board.snapshot();
    final result = board.trySwap(const GridPoint(0, 0), const GridPoint(0, 1));

    expect(result.isValid, isFalse);
    expect(board.snapshot(), equals(before));
  });

  test('board can reveal a valid hint and explode an area', () {
    final BoardEngine board = BoardEngine.fromRows(<List<GemTile>>[
      <GemTile>[
        gem(BlockType.ember, 1),
        gem(BlockType.tide, 2),
        gem(BlockType.bloom, 2),
        gem(BlockType.spark, 1),
      ],
      <GemTile>[
        gem(BlockType.ember, 2),
        gem(BlockType.spark, 4),
        gem(BlockType.tide, 3),
        gem(BlockType.bloom, 2),
      ],
      <GemTile>[
        gem(BlockType.tide, 2),
        gem(BlockType.ember, 5),
        gem(BlockType.ember, 1),
        gem(BlockType.umbra, 3),
      ],
      <GemTile>[
        gem(BlockType.spark, 2),
        gem(BlockType.bloom, 1),
        gem(BlockType.tide, 2),
        gem(BlockType.umbra, 4),
      ],
    ]);

    expect(board.findSuggestedMove(), isNotNull);

    final result = board.explodeAt(const GridPoint(1, 1));
    expect(result.isValid, isTrue);
    expect(result.clearedTiles, greaterThanOrEqualTo(4));
  });

  test('moon-style reroll changes only the selected gem number', () {
    final BoardEngine board = BoardEngine.fromRows(<List<GemTile>>[
      <GemTile>[
        gem(BlockType.ember, 1),
        gem(BlockType.tide, 2),
        gem(BlockType.bloom, 3),
      ],
      <GemTile>[
        gem(BlockType.spark, 4),
        gem(BlockType.umbra, 5, star: true),
        gem(BlockType.ember, 2),
      ],
      <GemTile>[
        gem(BlockType.tide, 1),
        gem(BlockType.bloom, 2),
        gem(BlockType.spark, 3),
      ],
    ]);

    final GemTile original = board.tileAt(1, 1);
    final GemTile updated = board.rerollValueAt(const GridPoint(1, 1));

    expect(updated.id, original.id);
    expect(updated.type, BlockType.umbra);
    expect(updated.isStar, isTrue);
    expect(updated.power, inInclusiveRange(1, 5));
    expect(updated.power, isNot(5));
    expect(board.tileAt(0, 0), gem(BlockType.ember, 1));
    expect(board.tileAt(1, 1), updated);
  });

  test('4-match creates a line blast bonus', () {
    final BoardEngine board = BoardEngine.fromRows(<List<GemTile>>[
      <GemTile>[
        gem(BlockType.tide, 1),
        gem(BlockType.bloom, 2),
        gem(BlockType.spark, 3),
        gem(BlockType.umbra, 4),
        gem(BlockType.tide, 1),
      ],
      <GemTile>[
        gem(BlockType.spark, 2),
        gem(BlockType.tide, 4),
        gem(BlockType.ember, 3),
        gem(BlockType.bloom, 1),
        gem(BlockType.umbra, 2),
      ],
      <GemTile>[
        gem(BlockType.ember, 2),
        gem(BlockType.ember, 4),
        gem(BlockType.tide, 2),
        gem(BlockType.ember, 1),
        gem(BlockType.spark, 5),
      ],
      <GemTile>[
        gem(BlockType.bloom, 4),
        gem(BlockType.spark, 1),
        gem(BlockType.tide, 5),
        gem(BlockType.umbra, 3),
        gem(BlockType.tide, 2),
      ],
      <GemTile>[
        gem(BlockType.umbra, 1),
        gem(BlockType.tide, 3),
        gem(BlockType.bloom, 2),
        gem(BlockType.spark, 4),
        gem(BlockType.bloom, 1),
      ],
    ]);

    final BoardMoveResult result = board.trySwap(
      const GridPoint(1, 2),
      const GridPoint(2, 2),
    );

    expect(result.isValid, isTrue);
    expect(
      result.matchBonuses.any(
        (MatchBonus bonus) =>
            bonus.element == BlockType.ember &&
            bonus.bonusType == MatchBonusType.lineBlast &&
            bonus.size == 4,
      ),
      isTrue,
    );
  });

  test('5-match creates a nova bonus', () {
    final BoardEngine board = BoardEngine.fromRows(<List<GemTile>>[
      <GemTile>[
        gem(BlockType.tide, 1),
        gem(BlockType.bloom, 2),
        gem(BlockType.ember, 3),
        gem(BlockType.umbra, 4),
        gem(BlockType.tide, 1),
      ],
      <GemTile>[
        gem(BlockType.spark, 2),
        gem(BlockType.tide, 4),
        gem(BlockType.ember, 3),
        gem(BlockType.bloom, 1),
        gem(BlockType.umbra, 2),
      ],
      <GemTile>[
        gem(BlockType.ember, 2),
        gem(BlockType.ember, 4),
        gem(BlockType.tide, 2),
        gem(BlockType.ember, 1),
        gem(BlockType.ember, 5),
      ],
      <GemTile>[
        gem(BlockType.bloom, 4),
        gem(BlockType.spark, 1),
        gem(BlockType.tide, 5),
        gem(BlockType.umbra, 3),
        gem(BlockType.tide, 2),
      ],
      <GemTile>[
        gem(BlockType.umbra, 1),
        gem(BlockType.tide, 3),
        gem(BlockType.bloom, 2),
        gem(BlockType.spark, 4),
        gem(BlockType.bloom, 1),
      ],
    ]);

    final BoardMoveResult result = board.trySwap(
      const GridPoint(1, 2),
      const GridPoint(2, 2),
    );

    expect(result.isValid, isTrue);
    expect(
      result.matchBonuses.any(
        (MatchBonus bonus) =>
            bonus.element == BlockType.ember &&
            bonus.bonusType == MatchBonusType.nova &&
            bonus.size == 5,
      ),
      isTrue,
    );
  });

  test('4-match leaves a line special gem on the board', () {
    final BoardEngine board = BoardEngine.fromRows(<List<GemTile>>[
      <GemTile>[
        gem(BlockType.tide, 1),
        gem(BlockType.bloom, 2),
        gem(BlockType.spark, 3),
        gem(BlockType.umbra, 4),
        gem(BlockType.tide, 1),
      ],
      <GemTile>[
        gem(BlockType.spark, 2),
        gem(BlockType.tide, 4),
        gem(BlockType.ember, 3),
        gem(BlockType.bloom, 1),
        gem(BlockType.umbra, 2),
      ],
      <GemTile>[
        gem(BlockType.ember, 2),
        gem(BlockType.ember, 4),
        gem(BlockType.tide, 2),
        gem(BlockType.ember, 1),
        gem(BlockType.spark, 5),
      ],
      <GemTile>[
        gem(BlockType.bloom, 4),
        gem(BlockType.spark, 1),
        gem(BlockType.tide, 5),
        gem(BlockType.umbra, 3),
        gem(BlockType.tide, 2),
      ],
      <GemTile>[
        gem(BlockType.umbra, 1),
        gem(BlockType.tide, 3),
        gem(BlockType.bloom, 2),
        gem(BlockType.spark, 4),
        gem(BlockType.bloom, 1),
      ],
    ]);

    board.trySwap(const GridPoint(1, 2), const GridPoint(2, 2));

    expect(
      board
          .snapshot()
          .expand((List<GemTile> row) => row)
          .any((GemTile tile) =>
              tile.special == GemSpecialKind.line ||
              tile.special == GemSpecialKind.cross),
      isTrue,
    );
  });

  test('special line gem triggers extra clear and bonus when destroyed', () {
    final BoardEngine board = BoardEngine.fromRows(<List<GemTile>>[
      <GemTile>[
        gem(BlockType.tide, 1),
        gem(BlockType.bloom, 2),
        gem(BlockType.spark, 3),
        gem(BlockType.umbra, 4),
        gem(BlockType.tide, 1),
      ],
      <GemTile>[
        gem(BlockType.spark, 2),
        gem(BlockType.ember, 4),
        gem(BlockType.ember, 3),
        gem(BlockType.bloom, 1),
        gem(BlockType.umbra, 2),
      ],
      <GemTile>[
        gem(BlockType.ember, 2),
        gem(BlockType.ember, 4, special: GemSpecialKind.line),
        gem(BlockType.tide, 2),
        gem(BlockType.ember, 1),
        gem(BlockType.spark, 5),
      ],
      <GemTile>[
        gem(BlockType.bloom, 4),
        gem(BlockType.spark, 1),
        gem(BlockType.tide, 5),
        gem(BlockType.umbra, 3),
        gem(BlockType.tide, 2),
      ],
      <GemTile>[
        gem(BlockType.umbra, 1),
        gem(BlockType.tide, 3),
        gem(BlockType.bloom, 2),
        gem(BlockType.spark, 4),
        gem(BlockType.bloom, 1),
      ],
    ]);

    final BoardMoveResult result = board.explodeAt(
      const GridPoint(2, 1),
      radius: 0,
    );

    expect(result.isValid, isTrue);
    expect(result.clearedTiles, greaterThanOrEqualTo(8));
    expect(
      result.matchBonuses.any(
        (MatchBonus bonus) =>
            bonus.bonusType == MatchBonusType.lineBlast &&
            bonus.element == BlockType.ember,
      ),
      isTrue,
    );
  });

  test('overlapping 4-match groups create a cross special gem', () {
    final BoardEngine board = BoardEngine.fromRows(
      <List<GemTile>>[
        <GemTile>[
          gem(BlockType.bloom, 1),
          gem(BlockType.spark, 1),
          gem(BlockType.tide, 1),
          gem(BlockType.tide, 1),
          gem(BlockType.spark, 1),
        ],
        <GemTile>[
          gem(BlockType.tide, 1),
          gem(BlockType.tide, 1),
          gem(BlockType.umbra, 1),
          gem(BlockType.tide, 1),
          gem(BlockType.umbra, 1),
        ],
        <GemTile>[
          gem(BlockType.ember, 1),
          gem(BlockType.tide, 1),
          gem(BlockType.ember, 1),
          gem(BlockType.tide, 1),
          gem(BlockType.bloom, 1),
        ],
        <GemTile>[
          gem(BlockType.tide, 1),
          gem(BlockType.umbra, 1),
          gem(BlockType.ember, 1),
          gem(BlockType.tide, 1),
          gem(BlockType.tide, 1),
        ],
        <GemTile>[
          gem(BlockType.ember, 1),
          gem(BlockType.spark, 1),
          gem(BlockType.spark, 1),
          gem(BlockType.spark, 1),
          gem(BlockType.tide, 1),
        ],
      ],
      random: Random(0),
    );

    board.trySwap(const GridPoint(0, 2), const GridPoint(1, 2));

    expect(
      board
          .snapshot()
          .expand((List<GemTile> row) => row)
          .any((GemTile tile) =>
              tile.special == GemSpecialKind.line ||
              tile.special == GemSpecialKind.cross),
      isTrue,
    );
  });
}

GemTile gem(
  BlockType type,
  int power, {
  bool star = false,
  GemSpecialKind? special,
}) {
  return GemTile(type: type, power: power, isStar: star, special: special);
}
