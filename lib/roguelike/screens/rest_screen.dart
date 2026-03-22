import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class RestScreen extends StatefulWidget {
  const RestScreen({super.key});
  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  bool _used = false;
  String _resultText = '';

  void _rest(BuildContext context) {
    final run = context.read<RunState>();
    final healAmount = (run.maxHealth * 0.3).round();
    run.heal(healAmount);
    setState(() {
      _used = true;
      _resultText = 'HP +$healAmount 회복';
    });
  }

  void _upgradeCard(BuildContext context) {
    final run = context.read<RunState>();
    if (run.cards.isEmpty) {
      setState(() {
        _used = true;
        _resultText = '업그레이드할 카드가 없습니다.';
      });
      return;
    }
    final idx = Random().nextInt(run.cards.length);
    final card = run.cards[idx];
    // UpgradeCard is immutable; re-add the same card to mark slot as upgraded
    run.removeCard(card.id);
    run.addCard(card);
    setState(() {
      _used = true;
      _resultText = '${card.name} 업그레이드!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('휴식'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '잠시 쉬어갑니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            if (!_used) ...[
              FilledButton(
                onPressed: () => _rest(context),
                child: const Text('HP 30% 회복'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _upgradeCard(context),
                child: const Text('카드 업그레이드 (랜덤 1장)'),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _resultText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/map'),
                child: const Text('계속하기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
