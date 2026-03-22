import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
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
            id: 'c$i',
            name: 'Card $i',
            kind: CardKind.passive,
            description: '',
            effect: CardEffect(tag: CardEffectTag.burstDamage)));
      }
      expect(state.cards.length, RunState.maxCards);
      state.addCard(UpgradeCard(
          id: 'overflow',
          name: 'Over',
          kind: CardKind.passive,
          description: '',
          effect: CardEffect(tag: CardEffectTag.burstDamage)));
      expect(state.cards.length, RunState.maxCards);
    });
  });
}
