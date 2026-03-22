import 'dart:math';
import 'package:match_fantasy/roguelike/models/map_node.dart';

class RunMap {
  RunMap({required this.nodes, required this.startNodeId});

  final Map<String, MapNode> nodes;
  final String startNodeId;

  void visitNode(String nodeId) {
    final node = nodes[nodeId];
    if (node == null) return;
    node.isVisited = true;
    for (final nextId in node.nextNodeIds) {
      nodes[nextId]?.isAvailable = true;
    }
  }

  List<MapNode> get availableNodes =>
      nodes.values.where((n) => n.isAvailable && !n.isVisited).toList();

  static RunMap generate({required int seed, required int actRows}) {
    final rng = Random(seed);
    final nodes = <String, MapNode>{};

    for (int row = 0; row < actRows; row++) {
      final nodeCols = row == actRows - 1 ? 1 : (2 + rng.nextInt(2));
      for (int col = 0; col < nodeCols; col++) {
        final id = 'n_${row}_$col';
        final type = row == actRows - 1
            ? NodeType.boss
            : _pickNodeType(rng, row);
        nodes[id] = MapNode(
          id: id,
          type: type,
          row: row,
          col: col,
        );
      }
    }

    for (int row = 0; row < actRows - 1; row++) {
      final currentRowNodes = nodes.values.where((n) => n.row == row).toList();
      final nextRowNodes = nodes.values.where((n) => n.row == row + 1).toList();
      for (final node in currentRowNodes) {
        final next = nextRowNodes[rng.nextInt(nextRowNodes.length)];
        if (!node.nextNodeIds.contains(next.id)) {
          node.nextNodeIds.add(next.id);
        }
      }
    }

    // Mark all row-0 nodes as available so player can pick their entry point
    final row0Nodes = nodes.values.where((n) => n.row == 0).toList();
    for (final n in row0Nodes) {
      n.isAvailable = true;
    }
    final startNode = row0Nodes.first;

    return RunMap(nodes: nodes, startNodeId: startNode.id);
  }

  Map<String, dynamic> toJson() => {
        'startNodeId': startNodeId,
        'nodes': nodes.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory RunMap.fromJson(Map<String, dynamic> j) => RunMap(
        startNodeId: j['startNodeId'] as String,
        nodes: (j['nodes'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, MapNode.fromJson(v as Map<String, dynamic>)),
        ),
      );

  static NodeType _pickNodeType(Random rng, int row) {
    final roll = rng.nextDouble();
    if (roll < 0.50) return NodeType.combat;
    if (roll < 0.60) return NodeType.elite;
    if (roll < 0.75) return NodeType.shop;
    if (roll < 0.90) return NodeType.event;
    return NodeType.rest;
  }
}
