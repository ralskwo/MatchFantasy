import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<MetaState>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text('MATCH FANTASY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              Text('런 골드: ${meta.currency}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.amber)),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.push('/class'),
                child: const Text('새 게임 시작'),
              ),
              const SizedBox(height: 32),
              const Text('해금 트리',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    _UnlockTile(
                      tier: 'Tier 1',
                      cost: 50,
                      label: 'Tide Sage + Common 유물 3종',
                      unlocked: meta.unlockedClassIds.contains(
                          PlayerClassId.tideSage.name),
                      canAfford: meta.currency >= 50,
                      onUnlock: () {
                        context.read<MetaState>()
                          ..spendCurrency(50)
                          ..unlockClass(PlayerClassId.tideSage.name)
                          ..unlockRelic('tidal_stone')
                          ..unlockRelic('life_seed')
                          ..unlockRelic('lightning_feather');
                      },
                    ),
                    _UnlockTile(
                      tier: 'Tier 2',
                      cost: 120,
                      label: 'Spark Trickster + Uncommon 유물 3종',
                      unlocked: meta.unlockedClassIds.contains(
                          PlayerClassId.sparkTrickster.name),
                      canAfford: meta.currency >= 120 && meta.unlockedClassIds.contains(PlayerClassId.tideSage.name),
                      onUnlock: () {
                        context.read<MetaState>()
                          ..spendCurrency(120)
                          ..unlockClass(PlayerClassId.sparkTrickster.name)
                          ..unlockRelic('twin_element_stone')
                          ..unlockRelic('hourglass')
                          ..unlockRelic('shield_core');
                      },
                    ),
                    _UnlockTile(
                      tier: 'Tier 3',
                      cost: 250,
                      label: 'Umbra Reaper + Boss Relic + 시작 골드 +20',
                      unlocked: meta.unlockedClassIds.contains(
                          PlayerClassId.umbraReaper.name),
                      canAfford: meta.currency >= 250 && meta.unlockedClassIds.contains(PlayerClassId.sparkTrickster.name),
                      onUnlock: () {
                        context.read<MetaState>()
                          ..spendCurrency(250)
                          ..unlockClass(PlayerClassId.umbraReaper.name)
                          ..unlockRelic('kings_seal')
                          ..unlockRelic('phoenix_feather')
                          ..unlockRelic('chaos_dice');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockTile extends StatelessWidget {
  const _UnlockTile({
    required this.tier,
    required this.cost,
    required this.label,
    required this.unlocked,
    required this.canAfford,
    required this.onUnlock,
  });

  final String tier;
  final int cost;
  final String label;
  final bool unlocked;
  final bool canAfford;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(tier,
          style: const TextStyle(fontWeight: FontWeight.bold)),
        title: Text(label),
        subtitle: Text(unlocked ? '해금됨' : '$cost 골드'),
        trailing: unlocked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : FilledButton(
                onPressed: canAfford ? onUnlock : null,
                child: Text('$cost G'),
              ),
      ),
    );
  }
}
