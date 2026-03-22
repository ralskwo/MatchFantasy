import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/models/run_map.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class RelicSelectScreen extends StatefulWidget {
  const RelicSelectScreen({super.key});

  @override
  State<RelicSelectScreen> createState() => _RelicSelectScreenState();
}

class _RelicSelectScreenState extends State<RelicSelectScreen> {
  Relic? _selected;

  @override
  Widget build(BuildContext context) {
    final runState = context.watch<RunState>();
    final cls = runState.selectedClass!;
    final options = cls.startingRelicIds.map(relicById).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('시작 유물 선택')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: options.length,
              itemBuilder: (ctx, i) {
                final relic = options[i];
                final isSelected = _selected?.id == relic.id;
                return Card(
                  color: isSelected
                      ? Theme.of(ctx).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    title: Text(relic.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(relic.description),
                    onTap: () => setState(() => _selected = relic),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      final map = RunMap.generate(
                        seed: DateTime.now().millisecondsSinceEpoch,
                        actRows: 5,
                      );
                      context.read<RunState>().startRun(
                        playerClass: cls,
                        startingRelic: _selected!,
                        runMap: map,
                      );
                      context.go('/map');
                    },
              child: const Text('런 시작'),
            ),
          ),
        ],
      ),
    );
  }
}
