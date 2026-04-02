import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/models/reward_offer.dart';
import 'package:match_fantasy/roguelike/models/shop_offer.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/roguelike/systems/reward_offer_picker.dart';

void main() {
  group('RewardOfferPicker', () {
    const picker = RewardOfferPicker();

    test('buildRewardChoices returns card relic and gold options', () {
      final run = RunState()
        ..cards = [cardById('extra_clear')]
        ..relics = [relicById('flame_seal')];

      final choices = picker.buildRewardChoices(
        run,
        random: Random(7),
      );

      expect(choices, hasLength(3));
      expect(
        choices.where((choice) => choice.kind == RewardOfferKind.card),
        hasLength(1),
      );
      expect(
        choices.where((choice) => choice.kind == RewardOfferKind.relic),
        hasLength(1),
      );
      expect(
        choices.where((choice) => choice.kind == RewardOfferKind.gold),
        hasLength(1),
      );
      expect(
        choices.singleWhere((choice) => choice.kind == RewardOfferKind.card).cardId,
        isNot('extra_clear'),
      );
      expect(
        choices.singleWhere((choice) => choice.kind == RewardOfferKind.relic).relicId,
        isNot('flame_seal'),
      );
    });

    test('buildShopOffers returns unique item offers and fixed services', () {
      final run = RunState()
        ..cards = [cardById('extra_clear')]
        ..relics = [relicById('flame_seal')];

      final offers = picker.buildShopOffers(
        run,
        random: Random(19),
      );

      final cardOffers = offers.where((offer) => offer.kind == ShopOfferKind.card).toList();
      final relicOffers = offers.where((offer) => offer.kind == ShopOfferKind.relic).toList();
      final serviceKinds = offers
          .where((offer) => offer.kind == ShopOfferKind.heal || offer.kind == ShopOfferKind.removeCard)
          .map((offer) => offer.kind)
          .toSet();

      expect(cardOffers, hasLength(3));
      expect(relicOffers, hasLength(2));
      expect(serviceKinds, containsAll(<ShopOfferKind>[
        ShopOfferKind.heal,
        ShopOfferKind.removeCard,
      ]));
      expect(cardOffers.map((offer) => offer.cardId).toSet(), hasLength(3));
      expect(relicOffers.map((offer) => offer.relicId).toSet(), hasLength(2));
      expect(cardOffers.any((offer) => offer.cardId == 'extra_clear'), isFalse);
      expect(relicOffers.any((offer) => offer.relicId == 'flame_seal'), isFalse);
      expect(relicOffers.any((offer) => offer.relicId == 'kings_seal'), isFalse);
    });

    test('shop sale price is derived from the offer flag', () {
      const offer = ShopOffer.card(
        cardId: 'board_refresh',
        basePrice: 120,
        isHalfPriceSale: true,
      );

      expect(offer.priceBeforeRunDiscounts, 60);
    });
  });
}
