import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/data/classes_data.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';

class ClassSelectScreen extends StatefulWidget {
  const ClassSelectScreen({super.key});

  @override
  State<ClassSelectScreen> createState() => _ClassSelectScreenState();
}

class _ClassSelectScreenState extends State<ClassSelectScreen> {
  PlayerClass? _selected;

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<MetaState>();
    final available = allClasses
        .where((c) => meta.unlockedClassIds.contains(c.id.name))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('클래스 선택')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: available.length,
              itemBuilder: (ctx, i) {
                final cls = available[i];
                final isSelected = _selected?.id == cls.id;
                return Card(
                  color: isSelected
                      ? Theme.of(ctx).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    title: Text(cls.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(cls.passiveDescription),
                    onTap: () => setState(() => _selected = cls),
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
                      context.read<RunState>().setSelectedClass(_selected!);
                      context.push('/relic');
                    },
              child: const Text('선택'),
            ),
          ),
        ],
      ),
    );
  }
}
