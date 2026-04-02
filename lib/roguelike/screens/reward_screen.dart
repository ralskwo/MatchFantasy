import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/data/reward_metadata_data.dart';
import 'package:match_fantasy/roguelike/models/reward_offer.dart';
import 'package:match_fantasy/roguelike/systems/reward_offer_picker.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:provider/provider.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  static const RewardOfferPicker _offerPicker = RewardOfferPicker();

  late final List<RewardOffer> _choices;

  @override
  void initState() {
    super.initState();
    final run = context.read<RunState>();
    if (run.pendingRewards.isNotEmpty) {
      _choices = List<RewardOffer>.of(run.pendingRewards);
      return;
    }

    _choices = _offerPicker.buildRewardChoices(
      run,
      random: Random(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      run.setPendingRewards(_choices);
      unawaited(run.save());
    });
  }

  Future<void> _select(RewardOffer reward) async {
    final run = context.read<RunState>();
    switch (reward.kind) {
      case RewardOfferKind.card:
        run.addCard(cardById(reward.cardId!));
      case RewardOfferKind.relic:
        run.addRelic(relicById(reward.relicId!));
      case RewardOfferKind.gold:
        run.earnGold(reward.goldAmount);
    }
    run.clearPendingRewards();
    await run.save();
    if (mounted) context.go('/map');
  }

  Future<void> _skip() async {
    final run = context.read<RunState>();
    run.clearPendingRewards();
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
          children: <Widget>[
            const Text(
              '전투 승리! 보상을 하나 선택하세요.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ..._choices.map(
              (reward) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RewardCard(
                  reward: reward,
                  onSelect: () => _select(reward),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _skip,
              child: const Text('건너뛰기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.onSelect,
  });

  final RewardOffer reward;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final visual = _RewardVisual.fromOffer(reward);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: visual.color.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon, color: visual.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            visual.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (visual.badgeText != null) ...<Widget>[
                          const SizedBox(width: 8),
                          _RarityBadge(
                            label: visual.badgeText!,
                            color: visual.color,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      visual.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: visual.color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({
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
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
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

class _RewardVisual {
  const _RewardVisual({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badgeText,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badgeText;

  factory _RewardVisual.fromOffer(RewardOffer offer) {
    switch (offer.kind) {
      case RewardOfferKind.card:
        final card = cardById(offer.cardId!);
        final metadata = rewardMetadataByCardId(card.id);
        return _RewardVisual(
          title: card.name,
          subtitle: card.description,
          icon: card.kind.name == 'active' ? Icons.flash_on : Icons.style,
          color: const Color(0xFF4BD0D1),
          badgeText: metadata.rarityLabel,
        );
      case RewardOfferKind.relic:
        final relic = relicById(offer.relicId!);
        final metadata = rewardMetadataForRelic(relic);
        return _RewardVisual(
          title: relic.name,
          subtitle: relic.description,
          icon: Icons.auto_awesome,
          color: const Color(0xFFFFD166),
          badgeText: metadata.rarityLabel,
        );
      case RewardOfferKind.gold:
        return _RewardVisual(
          title: '골드 +${offer.goldAmount}',
          subtitle: '즉시 골드를 획득합니다.',
          icon: Icons.monetization_on,
          color: const Color(0xFFFFA500),
        );
    }
  }
}
