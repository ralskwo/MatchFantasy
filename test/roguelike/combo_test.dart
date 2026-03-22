import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/game/match_fantasy_game.dart';

void main() {
  group('Combo multiplier', () {
    test('no combo = base multiplier 1.0', () {
      final game = MatchFantasyGame(random: Random(42));
      // _comboCount is 0 at start, no runState → 1.0 + 0 * 0.10 = 1.0
      expect(game.testBurstMultiplier(), 1.0);
    });
  });
}
