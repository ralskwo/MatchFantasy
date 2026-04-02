import 'dart:math';

import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/data/reward_metadata_data.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/models/reward_offer.dart';
import 'package:match_fantasy/roguelike/models/shop_offer.dart';
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class RewardOfferPicker {
  const RewardOfferPicker();

  List<RewardOffer> buildRewardChoices(
    RunState runState, {
    required Random random,
  }) {
    final cardCandidates = _availableCards(runState);
    final relicCandidates = _availableRelics(runState);

    final cardPicks = _pickUnique(
      _weightedCards(cardCandidates),
      count: relicCandidates.isEmpty ? 2 : 1,
      random: random,
    );

    final rewards = <RewardOffer>[
      RewardOffer.card(cardId: cardPicks[0].id),
      if (relicCandidates.isNotEmpty)
        RewardOffer.relic(
          relicId: _pickUnique(
            _weightedRelics(relicCandidates),
            count: 1,
            random: random,
          ).first.id,
        )
      else
        RewardOffer.card(cardId: cardPicks[1].id),
      RewardOffer.gold(
        goldAmount: 18 + random.nextInt(17) + ((runState.actNumber - 1) * 4),
      ),
    ];
    rewards.shuffle(random);
    return rewards;
  }

  List<ShopOffer> buildShopOffers(
    RunState runState, {
    required Random random,
  }) {
    final cardOffers = _pickUnique(
      _weightedCards(_availableCards(runState)),
      count: 3,
      random: random,
    ).map((card) {
      final metadata = rewardMetadataForCard(card);
      return ShopOffer.card(
        cardId: card.id,
        basePrice: metadata.basePrice,
        isHalfPriceSale: _rollSale(random),
      );
    });

    final relicOffers = _pickUnique(
      _weightedRelics(_availableRelics(runState)),
      count: 2,
      random: random,
    ).map((relic) {
      final metadata = rewardMetadataForRelic(relic);
      return ShopOffer.relic(
        relicId: relic.id,
        basePrice: metadata.basePrice,
        isHalfPriceSale: _rollSale(random),
      );
    });

    return <ShopOffer>[
      ...cardOffers,
      ...relicOffers,
      const ShopOffer.heal(basePrice: 50, healAmount: 15),
      const ShopOffer.removeCard(basePrice: 60),
    ];
  }

  List<UpgradeCard> _availableCards(RunState runState) {
    final ownedIds = runState.cards.map((card) => card.id).toSet();
    final available = allCards.where((card) => !ownedIds.contains(card.id)).toList();
    return available.isNotEmpty ? available : List<UpgradeCard>.of(allCards);
  }

  List<Relic> _availableRelics(RunState runState) {
    final ownedIds = runState.relics.map((relic) => relic.id).toSet();
    final available = allRelics
        .where((relic) => relic.rarity != RelicRarity.boss)
        .where((relic) => !ownedIds.contains(relic.id))
        .toList();
    return available.isNotEmpty
        ? available
        : allRelics.where((relic) => relic.rarity != RelicRarity.boss).toList();
  }

  List<_WeightedCandidate<UpgradeCard>> _weightedCards(List<UpgradeCard> cards) {
    return <_WeightedCandidate<UpgradeCard>>[
      for (final card in cards)
        _WeightedCandidate(
          value: card,
          weight: rewardMetadataForCard(card).weight,
        ),
    ];
  }

  List<_WeightedCandidate<Relic>> _weightedRelics(List<Relic> relics) {
    return <_WeightedCandidate<Relic>>[
      for (final relic in relics)
        _WeightedCandidate(
          value: relic,
          weight: rewardMetadataForRelic(relic).weight,
        ),
    ];
  }

  List<T> _pickUnique<T>(
    List<_WeightedCandidate<T>> source, {
    required int count,
    required Random random,
  }) {
    final remaining = List<_WeightedCandidate<T>>.of(source);
    final picked = <T>[];
    final targetCount = min(count, remaining.length);
    while (picked.length < targetCount && remaining.isNotEmpty) {
      final selected = _pickOne(remaining, random);
      picked.add(selected.value);
      remaining.remove(selected);
    }
    return picked;
  }

  _WeightedCandidate<T> _pickOne<T>(
    List<_WeightedCandidate<T>> candidates,
    Random random,
  ) {
    final totalWeight = candidates.fold<int>(
      0,
      (sum, candidate) => sum + candidate.weight,
    );
    var roll = random.nextInt(totalWeight);
    for (final candidate in candidates) {
      if (roll < candidate.weight) {
        return candidate;
      }
      roll -= candidate.weight;
    }
    return candidates.last;
  }

  bool _rollSale(Random random) => random.nextDouble() < 0.12;
}

class _WeightedCandidate<T> {
  const _WeightedCandidate({
    required this.value,
    required this.weight,
  });

  final T value;
  final int weight;
}
