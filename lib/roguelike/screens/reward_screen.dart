import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

enum _RewardKind { card, relic, gold }

class _Reward {
  const _Reward({required this.kind, this.card, this.relic, this.goldAmount = 0});
  final _RewardKind kind;
  final UpgradeCard? card;
  final Relic? relic;
  final int goldAmount;

  String get title => switch (kind) {
        _RewardKind.card => card!.name,
        _RewardKind.relic => relic!.name,
        _RewardKind.gold => '골드 +$goldAmount',
      };

  String get subtitle => switch (kind) {
        _RewardKind.card => card!.description,
        _RewardKind.relic => relic!.description,
        _RewardKind.gold => '골드를 즉시 획득합니다.',
      };

  IconData get icon => switch (kind) {
        _RewardKind.card => Icons.style,
        _RewardKind.relic => Icons.auto_awesome,
        _RewardKind.gold => Icons.monetization_on,
      };

  Color get color => switch (kind) {
        _RewardKind.card => const Color(0xFF4BD0D1),
        _RewardKind.relic => const Color(0xFFFFD166),
        _RewardKind.gold => const Color(0xFFFFA500),
      };
}

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  late final List<_Reward> _choices;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final run = context.read<RunState>();
    _choices = _buildChoices(rng, run);
  }

  List<_Reward> _buildChoices(Random rng, RunState run) {
    final choices = <_Reward>[];

    // 카드 1개
    final cardPool = List<UpgradeCard>.of(allCards)..shuffle(rng);
    final ownedIds = run.cards.map((c) => c.id).toSet();
    final cardChoice = cardPool.firstWhere(
      (c) => !ownedIds.contains(c.id),
      orElse: () => cardPool.first,
    );
    choices.add(_Reward(kind: _RewardKind.card, card: cardChoice));

    // 릴릭 1개 (보유하지 않은 것)
    final relicPool = List<Relic>.of(allRelics)
      ..removeWhere((r) => run.hasRelic(r.id))
      ..shuffle(rng);
    if (relicPool.isNotEmpty) {
      choices.add(_Reward(kind: _RewardKind.relic, relic: relicPool.first));
    }

    // 골드 (15~30)
    final goldAmount = 15 + rng.nextInt(16);
    choices.add(_Reward(kind: _RewardKind.gold, goldAmount: goldAmount));

    choices.shuffle(rng);
    return choices;
  }

  Future<void> _select(_Reward reward) async {
    final run = context.read<RunState>();
    switch (reward.kind) {
      case _RewardKind.card:
        run.addCard(reward.card!);
      case _RewardKind.relic:
        run.addRelic(reward.relic!);
      case _RewardKind.gold:
        run.earnGold(reward.goldAmount);
    }
    await run.save();
    if (mounted) context.go('/map');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보상 선택'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '전투 승리! 보상을 하나 선택하세요.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ..._choices.map(
              (reward) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RewardCard(reward: reward, onSelect: () => _select(reward)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await context.read<RunState>().save();
                if (context.mounted) context.go('/map');
              },
              child: const Text('건너뛰기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.reward, required this.onSelect});
  final _Reward reward;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: reward.color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: reward.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(reward.icon, color: reward.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reward.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: reward.color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
