import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final List<_ShopItem> _items;
  final Set<int> _purchased = {};

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _items = _buildShopItems(rng);
  }

  List<_ShopItem> _buildShopItems(Random rng) {
    final items = <_ShopItem>[];
    // 3 cards
    final cardPool = List<UpgradeCard>.of(allCards)..shuffle(rng);
    for (final card in cardPool.take(3)) {
      items.add(_ShopItem(
        label: card.name,
        description: card.description,
        basePrice: 40 + rng.nextInt(31), // 40-70
        onBuy: (run) => run.addCard(card),
      ));
    }
    // 2 relics (common + uncommon pool)
    final relicPool = [
      ...relicsByRarity(RelicRarity.common),
      ...relicsByRarity(RelicRarity.uncommon),
    ]..shuffle(rng);
    for (final relic in relicPool.take(2)) {
      items.add(_ShopItem(
        label: relic.name,
        description: relic.description,
        basePrice: 80 + rng.nextInt(51), // 80-130
        onBuy: (run) => run.addRelic(relic),
      ));
    }
    // HP recovery
    items.add(_ShopItem(
      label: 'HP 회복',
      description: '+15 HP',
      basePrice: 50,
      onBuy: (run) => run.heal(15),
    ));
    // Card removal
    items.add(_ShopItem(
      label: '카드 제거',
      description: '덱에서 카드 1장 삭제',
      basePrice: 60,
      onBuy: (run) {
        if (run.cards.isNotEmpty) {
          run.removeCard(run.cards.last.id);
        }
      },
    ));
    return items;
  }

  int _price(RunState run, int basePrice) {
    if (run.hasRelic('lucky_coin')) {
      return (basePrice * 0.9).round();
    }
    return basePrice;
  }

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('상점  💰 ${run.gold}G'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final item = _items[i];
                final price = _price(run, item.basePrice);
                final bought = _purchased.contains(i);
                final canAfford = run.gold >= price;
                return Card(
                  child: ListTile(
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: bought ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Text(item.description),
                    trailing: Text(
                      bought ? '구매완료' : '$price G',
                      style: TextStyle(
                        color: bought
                            ? Colors.grey
                            : (canAfford ? Colors.amber : Colors.red),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: (bought || !canAfford)
                        ? null
                        : () {
                            context.read<RunState>().spendGold(price);
                            item.onBuy(context.read<RunState>());
                            setState(() => _purchased.add(i));
                          },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () async {
                context.read<MetaState>().incrementAchievement('shop_visits');
                await context.read<RunState>().save();
                if (context.mounted) context.go('/map');
              },
              child: const Text('상점 나가기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItem {
  const _ShopItem({
    required this.label,
    required this.description,
    required this.basePrice,
    required this.onBuy,
  });
  final String label;
  final String description;
  final int basePrice;
  final void Function(RunState run) onBuy;
}
