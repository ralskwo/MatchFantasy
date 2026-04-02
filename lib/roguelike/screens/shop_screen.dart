import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/data/reward_metadata_data.dart';
import 'package:match_fantasy/roguelike/models/shop_offer.dart';
import 'package:match_fantasy/roguelike/systems/reward_offer_picker.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:provider/provider.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const RewardOfferPicker _offerPicker = RewardOfferPicker();

  late final List<ShopOffer> _seedOffers;

  @override
  void initState() {
    super.initState();
    final run = context.read<RunState>();
    final nodeId = run.currentNodeId;
    if (nodeId != null &&
        run.pendingShopNodeId == nodeId &&
        run.pendingShopOffers.isNotEmpty) {
      _seedOffers = List<ShopOffer>.of(run.pendingShopOffers);
      return;
    }

    _seedOffers = _offerPicker.buildShopOffers(
      run,
      random: Random(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || nodeId == null) return;
      run.setShopOffersForNode(nodeId, _seedOffers);
      unawaited(run.save());
    });
  }

  int _price(RunState run, ShopOffer offer, {bool ignoreSale = false}) {
    final basePrice =
        ignoreSale ? offer.basePrice : offer.priceBeforeRunDiscounts;
    double multiplier = 1.0;
    if (run.temporaryShopDiscount) multiplier *= 0.5;
    if (run.hasRelic('lucky_coin')) multiplier *= 0.9;
    return (basePrice * multiplier).round();
  }

  bool _canUseOffer(RunState run, ShopOffer offer) {
    if (offer.isPurchased) return false;
    switch (offer.kind) {
      case ShopOfferKind.card:
        return run.cards.length < RunState.maxCards;
      case ShopOfferKind.relic:
        return true;
      case ShopOfferKind.heal:
        return run.health < run.maxHealth;
      case ShopOfferKind.removeCard:
        return run.cards.isNotEmpty;
    }
  }

  void _applyOffer(RunState run, ShopOffer offer) {
    switch (offer.kind) {
      case ShopOfferKind.card:
        run.addCard(cardById(offer.cardId!));
      case ShopOfferKind.relic:
        run.addRelic(relicById(offer.relicId!));
      case ShopOfferKind.heal:
        run.heal(offer.healAmount);
      case ShopOfferKind.removeCard:
        run.removeCard(run.cards.last.id);
    }
  }

  Future<void> _leaveShop() async {
    final run = context.read<RunState>();
    context.read<MetaState>().incrementAchievement('shop_visits');
    run.clearShopDiscount();
    run.clearPendingShopOffers();
    await run.save();
    if (mounted) context.go('/map');
  }

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunState>();
    final offers = run.pendingShopNodeId == run.currentNodeId &&
            run.pendingShopOffers.isNotEmpty
        ? run.pendingShopOffers
        : _seedOffers;
    final hasSale = offers.any((offer) => offer.isHalfPriceSale);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          run.temporaryShopDiscount
              ? '상점 할인 중  ${run.gold}G'
              : '상점  ${run.gold}G',
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: <Widget>[
          if (hasSale)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFD166).withValues(alpha: 0.55),
                ),
              ),
              child: const Text(
                '오늘의 특가 상품이 있습니다.',
                style: TextStyle(
                  color: Color(0xFFFFD166),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                final price = _price(run, offer);
                final originalPrice = offer.isHalfPriceSale
                    ? _price(run, offer, ignoreSale: true)
                    : null;
                final canUse = _canUseOffer(run, offer);
                final canAfford = run.gold >= price;
                final visual = _ShopOfferVisual.fromOffer(offer);

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            visual.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: offer.isPurchased ? Colors.grey : null,
                            ),
                          ),
                        ),
                        if (visual.badgeText != null)
                          _OfferChip(
                            label: visual.badgeText!,
                            color: visual.color,
                          ),
                        if (offer.isHalfPriceSale) ...<Widget>[
                          const SizedBox(width: 8),
                          const _OfferChip(
                            label: 'SALE',
                            color: Color(0xFFFFA500),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(visual.subtitle),
                    ),
                    trailing: SizedBox(
                      width: 84,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          if (offer.isPurchased)
                            const Text(
                              '구매 완료',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else ...<Widget>[
                            if (originalPrice != null)
                              Text(
                                '$originalPrice G',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              '$price G',
                              style: TextStyle(
                                color: canAfford && canUse
                                    ? Colors.amber
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    onTap: (!canAfford || !canUse || offer.isPurchased)
                        ? null
                        : () {
                            final run = context.read<RunState>();
                            run.spendGold(price);
                            _applyOffer(run, offer);
                            run.markShopOfferPurchased(offer.id);
                            unawaited(run.save());
                          },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _leaveShop,
              child: const Text('상점 나가기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferChip extends StatelessWidget {
  const _OfferChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ShopOfferVisual {
  const _ShopOfferVisual({
    required this.title,
    required this.subtitle,
    required this.color,
    this.badgeText,
  });

  final String title;
  final String subtitle;
  final Color color;
  final String? badgeText;

  factory _ShopOfferVisual.fromOffer(ShopOffer offer) {
    switch (offer.kind) {
      case ShopOfferKind.card:
        final card = cardById(offer.cardId!);
        final metadata = rewardMetadataByCardId(card.id);
        return _ShopOfferVisual(
          title: card.name,
          subtitle: card.description,
          color: const Color(0xFF4BD0D1),
          badgeText: metadata.rarityLabel,
        );
      case ShopOfferKind.relic:
        final relic = relicById(offer.relicId!);
        final metadata = rewardMetadataForRelic(relic);
        return _ShopOfferVisual(
          title: relic.name,
          subtitle: relic.description,
          color: const Color(0xFFFFD166),
          badgeText: metadata.rarityLabel,
        );
      case ShopOfferKind.heal:
        return _ShopOfferVisual(
          title: '치유',
          subtitle: '+${offer.healAmount} HP 회복',
          color: const Color(0xFF6ED39C),
        );
      case ShopOfferKind.removeCard:
        return const _ShopOfferVisual(
          title: '카드 제거',
          subtitle: '덱에서 카드 1장을 제거합니다.',
          color: Color(0xFFFF9F6E),
        );
    }
  }
}
