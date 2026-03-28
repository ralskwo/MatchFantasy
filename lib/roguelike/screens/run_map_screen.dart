import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/roguelike/models/map_node.dart';

class RunMapScreen extends StatelessWidget {
  const RunMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunState>();
    final available = run.map?.availableNodes ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Act ${run.actNumber}  HP: ${run.health}/${run.maxHealth}  G: ${run.gold}'),
        automaticallyImplyLeading: false,
      ),
      body: available.isEmpty
          ? const Center(child: Text('Act 클리어!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: available.length,
              itemBuilder: (ctx, i) {
                final node = available[i];
                return Card(
                  child: ListTile(
                    leading: Text(_nodeEmoji(node.type),
                      style: const TextStyle(fontSize: 24)),
                    title: Text(_nodeLabel(node.type)),
                    subtitle: Text('Row ${node.row}, Col ${node.col}'),
                    onTap: () => _handleNodeTap(context, node, run),
                  ),
                );
              },
            ),
    );
  }

  void _handleNodeTap(BuildContext ctx, MapNode node, RunState run) {
    run.visitNode(node.id);
    switch (node.type) {
      case NodeType.combat:
      case NodeType.elite:
      case NodeType.boss:
        ctx.push('/combat');
        break;
      case NodeType.shop:
        ctx.push('/shop');
        break;
      case NodeType.event:
        ctx.push('/event');
        break;
      case NodeType.rest:
        ctx.push('/rest');
        break;
      case NodeType.reward:
        ctx.push('/reward');
        break;
    }
  }

  String _nodeEmoji(NodeType t) => switch (t) {
    NodeType.combat => '⚔️',
    NodeType.elite  => '💀',
    NodeType.shop   => '🏪',
    NodeType.event  => '📜',
    NodeType.rest   => '😴',
    NodeType.boss   => '👑',
    NodeType.reward => '🎁',
  };

  String _nodeLabel(NodeType t) => switch (t) {
    NodeType.combat => '전투',
    NodeType.elite  => '엘리트 전투',
    NodeType.shop   => '상점',
    NodeType.event  => '이벤트',
    NodeType.rest   => '휴식',
    NodeType.boss   => '보스',
    NodeType.reward => '보상',
  };
}
