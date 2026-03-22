import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/data/events_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});
  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late final GameEvent _event;
  bool _resolved = false;
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _event = allEvents[rng.nextInt(allEvents.length)];
  }

  void _chooseOption(BuildContext context, EventChoice choice) {
    final run = context.read<RunState>();
    final outcome = choice.effect;
    String result = choice.description;

    switch (outcome.type) {
      case EventOutcomeType.gainGold:
        if (outcome.value > 0) run.earnGold(outcome.value);
        break;
      case EventOutcomeType.loseHp:
        if (outcome.value < 0) run.takeDamage(-outcome.value);
        break;
      case EventOutcomeType.gainRelic:
        final relics = relicsByRarity(RelicRarity.uncommon);
        if (relics.isNotEmpty) {
          final relic = relics[Random().nextInt(relics.length)];
          run.addRelic(relic);
          result = '${relic.name} 획득!';
        }
        if (outcome.value < 0) run.takeDamage(-outcome.value);
        break;
      case EventOutcomeType.gainCards:
        if (outcome.value < 0) run.spendGold(-outcome.value);
        final pool = List.of(allCards)..shuffle(Random());
        for (final card in pool.take(outcome.cardCount)) {
          run.addCard(card);
        }
        result = '카드 ${outcome.cardCount}장 획득!';
        break;
      case EventOutcomeType.gainGoldLoseHp:
        if (outcome.value < 0) run.takeDamage(-outcome.value);
        result = '효과 적용됨';
        break;
    }

    setState(() {
      _resolved = true;
      _resultText = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_event.title),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _event.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            if (!_resolved) ...[
              ..._event.choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: () => _chooseOption(context, choice),
                    child: Column(
                      children: [
                        Text(
                          choice.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          choice.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
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
