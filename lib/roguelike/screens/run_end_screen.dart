import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class RunEndScreen extends StatelessWidget {
  const RunEndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunState>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '런 종료',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Act ${run.actNumber} 도달',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _StatCard(
                icon: Icons.whatshot,
                color: Colors.orange,
                label: '총 처치 수',
                value: '${run.totalKills}',
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.bolt,
                color: Colors.amber,
                label: '최대 콤보',
                value: run.maxCombo > 0 ? '${run.maxCombo}x' : '—',
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.style,
                color: Colors.blue,
                label: '수집한 카드',
                value: '${run.cards.length}장',
              ),
              if (run.cards.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: run.cards
                      .map((c) => Chip(
                            label: Text(
                              c.name,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () {
                  run.endRun();
                  context.go('/');
                },
                child: const Text('다시 시작'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
