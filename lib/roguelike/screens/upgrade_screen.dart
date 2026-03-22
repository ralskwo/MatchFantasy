import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});
  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  late final List<UpgradeCard> _choices;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final pool = List<UpgradeCard>.of(allCards)..shuffle(rng);
    _choices = pool.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('업그레이드 선택'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          ..._choices.map((card) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: ListTile(
                title: Text(card.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(card.description),
                trailing: run.cards.length >= RunState.maxCards
                    ? const Text('덱 가득',
                        style: TextStyle(color: Colors.red))
                    : null,
                onTap: () {
                  context.read<RunState>().addCard(card);
                  context.go('/map');
                },
              ),
            ),
          )),
          TextButton(
            onPressed: () => context.go('/map'),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
    );
  }
}
