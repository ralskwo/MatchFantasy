import 'dart:math';

import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/board_move_result.dart';
import 'package:match_fantasy/game/models/gem_tile.dart';
import 'package:match_fantasy/game/models/grid_point.dart';
import 'package:match_fantasy/game/models/hint_move.dart';

class BoardEngine {
  BoardEngine({required this.rows, required this.columns, Random? random})
    : _random = random ?? Random() {
    reshuffle();
  }

  BoardEngine.fromRows(List<List<GemTile>> rowsData, {Random? random})
    : rows = rowsData.length,
      columns = rowsData.first.length,
      _random = random ?? Random() {
    _cells = rowsData
        .map(
          (List<GemTile> row) =>
              row.map<GemTile?>((GemTile tile) => tile).toList(growable: false),
        )
        .toList(growable: false);
    _nextTileId =
        rowsData
            .expand((List<GemTile> row) => row)
            .fold<int>(
              0,
              (int current, GemTile tile) => max(current, tile.id),
            ) +
        1;
  }

  final int rows;
  final int columns;
  final Random _random;
  int _nextTileId = 1;
  late List<List<GemTile?>> _cells;

  GemTile tileAt(int row, int column) => _cells[row][column]!;

  List<List<GemTile>> snapshot() {
    return List<List<GemTile>>.unmodifiable(
      _cells.map(
        (List<GemTile?> row) =>
            List<GemTile>.unmodifiable(row.map((GemTile? tile) => tile!)),
      ),
    );
  }

  void reshuffle() {
    do {
      _cells = List<List<GemTile?>>.generate(
        rows,
        (_) => List<GemTile?>.filled(columns, null, growable: false),
        growable: false,
      );
      for (int row = 0; row < rows; row++) {
        for (int column = 0; column < columns; column++) {
          _cells[row][column] = _pickTileFor(_cells, row, column);
        }
      }
    } while (_findMatches().isNotEmpty || !hasAvailableMove());
  }

  void rerollValues() {
    for (int row = 0; row < rows; row++) {
      for (int column = 0; column < columns; column++) {
        final GemTile tile = _cells[row][column]!;
        _cells[row][column] = tile.copyWith(power: _randomPower());
      }
    }
  }

  GemTile rerollValueAt(GridPoint point) {
    final GemTile tile = _cells[point.row][point.column]!;
    final int nextPower = _randomPower(excluding: tile.power);
    final GemTile updated = tile.copyWith(power: nextPower);
    _cells[point.row][point.column] = updated;
    return updated;
  }

  HintMove? findSuggestedMove() {
    for (int row = 0; row < rows; row++) {
      for (int column = 0; column < columns; column++) {
        final GridPoint origin = GridPoint(row, column);
        if (column + 1 < columns &&
            _swapCreatesMatch(origin, GridPoint(row, column + 1))) {
          return HintMove(first: origin, second: GridPoint(row, column + 1));
        }
        if (row + 1 < rows &&
            _swapCreatesMatch(origin, GridPoint(row + 1, column))) {
          return HintMove(first: origin, second: GridPoint(row + 1, column));
        }
      }
    }
    return null;
  }

  bool hasAvailableMove() {
    return findSuggestedMove() != null;
  }

  BoardMoveResult trySwap(GridPoint first, GridPoint second) {
    if (!first.isAdjacentTo(second)) {
      return const BoardMoveResult(isValid: false);
    }

    final List<List<GemTile>> initialBoard = snapshot();
    _swap(first, second);
    final List<_MatchGroup> matchGroups = _findMatchGroups();
    final Set<GridPoint> matches = _collectMatchCells(matchGroups);
    if (matches.isEmpty) {
      _swap(first, second);
      return const BoardMoveResult(isValid: false);
    }

    final List<List<GemTile>> beforeBoard = snapshot();
    return _resolveClears(
      matches,
      initialBoard: initialBoard,
      beforeBoard: beforeBoard,
      initialGroups: matchGroups,
    );
  }

  BoardMoveResult explodeAt(GridPoint center, {int radius = 1}) {
    final List<List<GemTile>> initialBoard = snapshot();
    final Set<GridPoint> affected = <GridPoint>{};
    for (int row = center.row - radius; row <= center.row + radius; row++) {
      for (
        int column = center.column - radius;
        column <= center.column + radius;
        column++
      ) {
        if (row < 0 || row >= rows || column < 0 || column >= columns) {
          continue;
        }
        affected.add(GridPoint(row, column));
      }
    }

    if (affected.isEmpty) {
      return const BoardMoveResult(isValid: false);
    }

    return _resolveClears(
      affected,
      initialBoard: initialBoard,
      beforeBoard: initialBoard,
    );
  }

  bool _swapCreatesMatch(GridPoint first, GridPoint second) {
    _swap(first, second);
    final bool hasMatch = _findMatchGroups().isNotEmpty;
    _swap(first, second);
    return hasMatch;
  }

  void _swap(GridPoint first, GridPoint second) {
    final GemTile? cache = _cells[first.row][first.column];
    _cells[first.row][first.column] = _cells[second.row][second.column];
    _cells[second.row][second.column] = cache;
  }

  Set<GridPoint> _findMatches() {
    return _collectMatchCells(_findMatchGroups());
  }

  List<_MatchGroup> _findMatchGroups() {
    final List<_MatchGroup> groups = <_MatchGroup>[];

    for (int row = 0; row < rows; row++) {
      int runStart = 0;
      while (runStart < columns) {
        final GemTile? tile = _cells[row][runStart];
        if (tile == null) {
          runStart++;
          continue;
        }
        int runEnd = runStart + 1;
        while (runEnd < columns && _cells[row][runEnd]?.type == tile.type) {
          runEnd++;
        }
        if (runEnd - runStart >= 3) {
          groups.add(
            _MatchGroup(
              type: tile.type,
              cells: List<GridPoint>.generate(
                runEnd - runStart,
                (int index) => GridPoint(row, runStart + index),
                growable: false,
              ),
            ),
          );
        }
        runStart = runEnd;
      }
    }

    for (int column = 0; column < columns; column++) {
      int runStart = 0;
      while (runStart < rows) {
        final GemTile? tile = _cells[runStart][column];
        if (tile == null) {
          runStart++;
          continue;
        }
        int runEnd = runStart + 1;
        while (runEnd < rows && _cells[runEnd][column]?.type == tile.type) {
          runEnd++;
        }
        if (runEnd - runStart >= 3) {
          groups.add(
            _MatchGroup(
              type: tile.type,
              cells: List<GridPoint>.generate(
                runEnd - runStart,
                (int index) => GridPoint(runStart + index, column),
                growable: false,
              ),
            ),
          );
        }
        runStart = runEnd;
      }
    }

    return groups;
  }

  Set<GridPoint> _collectMatchCells(Iterable<_MatchGroup> groups) {
    final Set<GridPoint> matches = <GridPoint>{};
    for (final _MatchGroup group in groups) {
      matches.addAll(group.cells);
    }
    return matches;
  }

  List<MatchBonus> _bonusesForGroups(List<_MatchGroup> groups) {
    final List<MatchBonus> bonuses = <MatchBonus>[];
    for (final _MatchGroup group in groups) {
      if (group.cells.length < 4) {
        continue;
      }

      int powerTotal = 0;
      int starCount = 0;
      for (final GridPoint cell in group.cells) {
        final GemTile? tile = _cells[cell.row][cell.column];
        if (tile == null) {
          continue;
        }
        powerTotal += tile.power;
        if (tile.isStar) {
          starCount++;
        }
      }

      bonuses.add(
        MatchBonus(
          element: group.type,
          bonusType: group.cells.length >= 5
              ? MatchBonusType.nova
              : MatchBonusType.lineBlast,
          size: group.cells.length,
          powerTotal: powerTotal,
          starCount: starCount,
        ),
      );
    }
    return bonuses;
  }

  Map<GridPoint, GemSpecialKind> _specialsForGroups(List<_MatchGroup> groups) {
    final Map<GridPoint, GemSpecialKind> planned =
        <GridPoint, GemSpecialKind>{};
    final Set<GridPoint> claimed = <GridPoint>{};
    final List<_MatchGroup> candidates =
        groups.where((_MatchGroup group) => group.cells.length >= 4).toList()
          ..sort(
            (_MatchGroup a, _MatchGroup b) =>
                b.cells.length.compareTo(a.cells.length),
          );

    for (final _MatchGroup group in candidates) {
      final GridPoint? anchor = _pickSpecialAnchor(group, claimed);
      if (anchor == null) {
        continue;
      }
      final GemSpecialKind next = group.cells.length >= 5
          ? GemSpecialKind.nova
          : GemSpecialKind.line;
      final GemSpecialKind? existing = planned[anchor];
      planned[anchor] = _mergeSpecialKinds(existing, next);
      claimed.add(anchor);
    }
    return planned;
  }

  GridPoint? _pickSpecialAnchor(_MatchGroup group, Set<GridPoint> claimed) {
    if (group.cells.isEmpty) {
      return null;
    }

    final GridPoint pivot = group.cells[group.cells.length ~/ 2];
    final List<GridPoint> ordered = List<GridPoint>.of(group.cells)
      ..sort((GridPoint a, GridPoint b) {
        final GemTile? tileA = _cells[a.row][a.column];
        final GemTile? tileB = _cells[b.row][b.column];
        final int claimedCompare =
            (claimed.contains(a) ? 1 : 0) - (claimed.contains(b) ? 1 : 0);
        if (claimedCompare != 0) {
          return claimedCompare;
        }
        final int specialCompare =
            ((tileA?.isSpecial ?? false) ? 1 : 0) -
            ((tileB?.isSpecial ?? false) ? 1 : 0);
        if (specialCompare != 0) {
          return specialCompare;
        }
        final int distanceCompare =
            ((a.row - pivot.row).abs() + (a.column - pivot.column).abs())
                .compareTo(
                  (b.row - pivot.row).abs() + (b.column - pivot.column).abs(),
                );
        if (distanceCompare != 0) {
          return distanceCompare;
        }
        final int rowCompare = a.row.compareTo(b.row);
        return rowCompare != 0 ? rowCompare : a.column.compareTo(b.column);
      });

    for (final GridPoint cell in ordered) {
      final GemTile? tile = _cells[cell.row][cell.column];
      if (tile == null || tile.isSpecial || claimed.contains(cell)) {
        continue;
      }
      return cell;
    }

    return null;
  }

  GemSpecialKind _mergeSpecialKinds(
    GemSpecialKind? current,
    GemSpecialKind next,
  ) {
    if (current == GemSpecialKind.nova || next == GemSpecialKind.nova) {
      return GemSpecialKind.nova;
    }
    return GemSpecialKind.line;
  }

  _SpecialActivation _resolveSpecialActivations(
    Set<GridPoint> current,
    Set<GridPoint> protectedCells,
  ) {
    final Set<GridPoint> expanded = Set<GridPoint>.of(current);
    final Set<GridPoint> processed = <GridPoint>{};
    final List<MatchBonus> bonuses = <MatchBonus>[];

    bool changed;
    do {
      changed = false;
      for (final GridPoint cell in List<GridPoint>.of(expanded)) {
        if (protectedCells.contains(cell) || processed.contains(cell)) {
          continue;
        }
        final GemTile? tile = _cells[cell.row][cell.column];
        if (tile == null || tile.special == null) {
          continue;
        }

        processed.add(cell);
        bonuses.add(
          MatchBonus(
            element: tile.type,
            bonusType: tile.special == GemSpecialKind.nova
                ? MatchBonusType.nova
                : MatchBonusType.lineBlast,
            size: tile.special == GemSpecialKind.nova ? 5 : 4,
            powerTotal:
                tile.power + (tile.special == GemSpecialKind.nova ? 10 : 6),
            starCount: tile.isStar ? 1 : 0,
          ),
        );

        for (final GridPoint extra in _specialTargets(cell, tile)) {
          if (protectedCells.contains(extra)) {
            continue;
          }
          if (expanded.add(extra)) {
            changed = true;
          }
        }
      }
    } while (changed);

    return _SpecialActivation(clears: expanded, bonuses: bonuses);
  }

  Set<GridPoint> _specialTargets(GridPoint origin, GemTile tile) {
    final Set<GridPoint> affected = <GridPoint>{origin};
    switch (tile.special) {
      case GemSpecialKind.line:
        for (int row = 0; row < rows; row++) {
          affected.add(GridPoint(row, origin.column));
        }
        for (int column = 0; column < columns; column++) {
          affected.add(GridPoint(origin.row, column));
        }
        break;
      case GemSpecialKind.nova:
        for (int row = 0; row < rows; row++) {
          for (int column = 0; column < columns; column++) {
            final GemTile? other = _cells[row][column];
            if (other != null && other.type == tile.type) {
              affected.add(GridPoint(row, column));
            }
          }
        }
        break;
      case null:
        break;
    }
    return affected;
  }

  Map<BlockType, ElementClearSummary> _clearMatches(Set<GridPoint> matches) {
    final Map<BlockType, ElementClearSummary> cleared =
        <BlockType, ElementClearSummary>{};
    for (final GridPoint cell in matches) {
      final GemTile? tile = _cells[cell.row][cell.column];
      if (tile == null) {
        continue;
      }
      final ElementClearSummary current =
          cleared[tile.type] ?? const ElementClearSummary();
      cleared[tile.type] = current.addTile(tile);
      _cells[cell.row][cell.column] = null;
    }
    return cleared;
  }

  BoardMoveResult _resolveClears(
    Set<GridPoint> clears, {
    required List<List<GemTile>> initialBoard,
    required List<List<GemTile>> beforeBoard,
    List<_MatchGroup> initialGroups = const <_MatchGroup>[],
  }) {
    final Map<BlockType, ElementClearSummary> clearedByType =
        <BlockType, ElementClearSummary>{};
    final List<MatchBonus> matchBonuses = <MatchBonus>[];
    final List<List<List<GemTile>>> cascadeBoards = <List<List<GemTile>>>[];
    int comboDepth = 0;
    Set<GridPoint> current = clears;
    List<_MatchGroup> currentGroups = List<_MatchGroup>.of(initialGroups);

    while (current.isNotEmpty) {
      comboDepth++;
      final Map<GridPoint, GemSpecialKind> pendingSpecials =
          currentGroups.isEmpty
          ? <GridPoint, GemSpecialKind>{}
          : _specialsForGroups(currentGroups);
      final _SpecialActivation activation = _resolveSpecialActivations(
        current,
        pendingSpecials.keys.toSet(),
      );
      final Set<GridPoint> activeClears = Set<GridPoint>.of(activation.clears)
        ..removeAll(pendingSpecials.keys);
      if (currentGroups.isNotEmpty) {
        matchBonuses.addAll(_bonusesForGroups(currentGroups));
      }
      matchBonuses.addAll(activation.bonuses);
      final Map<BlockType, ElementClearSummary> removed = _clearMatches(
        activeClears,
      );
      for (final MapEntry<BlockType, ElementClearSummary> entry
          in removed.entries) {
        final ElementClearSummary existing =
            clearedByType[entry.key] ?? const ElementClearSummary();
        clearedByType[entry.key] = ElementClearSummary(
          count: existing.count + entry.value.count,
          powerTotal: existing.powerTotal + entry.value.powerTotal,
          starCount: existing.starCount + entry.value.starCount,
        );
      }
      _applySpecials(pendingSpecials);
      _collapseColumns();
      _refillBoard();
      // Capture state after each cascade step for per-step animation.
      cascadeBoards.add(snapshot());
      currentGroups = _findMatchGroups();
      current = _collectMatchCells(currentGroups);
    }

    if (!hasAvailableMove()) {
      reshuffle();
    }

    final int clearedTiles = clearedByType.values.fold<int>(
      0,
      (int total, ElementClearSummary value) => total + value.count,
    );
    final int clearedPower = clearedByType.values.fold<int>(
      0,
      (int total, ElementClearSummary value) => total + value.powerTotal,
    );
    final List<List<GemTile>> afterBoard = snapshot();

    return BoardMoveResult(
      isValid: true,
      clearedByType: clearedByType,
      matchBonuses: matchBonuses,
      comboDepth: comboDepth,
      clearedTiles: clearedTiles,
      clearedPower: clearedPower,
      initialBoard: initialBoard,
      beforeBoard: beforeBoard,
      afterBoard: afterBoard,
      cascadeBoards: cascadeBoards,
    );
  }

  void _collapseColumns() {
    for (int column = 0; column < columns; column++) {
      final List<GemTile?> remaining = <GemTile?>[];
      for (int row = 0; row < rows; row++) {
        final GemTile? tile = _cells[row][column];
        if (tile != null) {
          remaining.add(tile);
        }
      }

      final int emptyCount = rows - remaining.length;
      for (int row = 0; row < emptyCount; row++) {
        _cells[row][column] = null;
      }
      for (int index = 0; index < remaining.length; index++) {
        _cells[emptyCount + index][column] = remaining[index];
      }
    }
  }

  void _refillBoard() {
    for (int row = 0; row < rows; row++) {
      for (int column = 0; column < columns; column++) {
        if (_cells[row][column] == null) {
          _cells[row][column] = _pickTileFor(_cells, row, column);
        }
      }
    }
  }

  void _applySpecials(Map<GridPoint, GemSpecialKind> specials) {
    for (final MapEntry<GridPoint, GemSpecialKind> entry in specials.entries) {
      final GemTile? tile = _cells[entry.key.row][entry.key.column];
      if (tile == null) {
        continue;
      }
      _cells[entry.key.row][entry.key.column] = tile.copyWith(
        special: _mergeSpecialKinds(tile.special, entry.value),
      );
    }
  }

  GemTile _pickTileFor(List<List<GemTile?>> board, int row, int column) {
    final List<BlockType> candidates = List<BlockType>.of(BlockType.values);
    candidates.removeWhere((BlockType candidate) {
      final BlockType? leftA = column > 0 ? board[row][column - 1]?.type : null;
      final BlockType? leftB = column > 1 ? board[row][column - 2]?.type : null;
      final BlockType? upA = row > 0 ? board[row - 1][column]?.type : null;
      final BlockType? upB = row > 1 ? board[row - 2][column]?.type : null;
      return (leftA == candidate && leftB == candidate) ||
          (upA == candidate && upB == candidate);
    });

    final BlockType type;
    if (candidates.isEmpty) {
      type = BlockType.values[_random.nextInt(BlockType.values.length)];
    } else {
      type = candidates[_random.nextInt(candidates.length)];
    }

    return GemTile(
      id: _nextTileId++,
      type: type,
      power: _randomPower(),
      isStar: _random.nextDouble() < 0.08,
    );
  }

  int _randomPower({int? excluding}) {
    int value = _random.nextInt(5) + 1;
    if (excluding == null) {
      return value;
    }

    while (value == excluding) {
      value = _random.nextInt(5) + 1;
    }
    return value;
  }
}

class _MatchGroup {
  const _MatchGroup({required this.type, required this.cells});

  final BlockType type;
  final List<GridPoint> cells;
}

class _SpecialActivation {
  const _SpecialActivation({required this.clears, required this.bonuses});

  final Set<GridPoint> clears;
  final List<MatchBonus> bonuses;
}
