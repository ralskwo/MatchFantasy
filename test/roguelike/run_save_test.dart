import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/roguelike/models/map_node.dart';
import 'package:match_fantasy/roguelike/models/run_map.dart';

void main() {
  group('MapNode serialization', () {
    test('toJson / fromJson round-trip preserves all fields', () {
      final node = MapNode(
        id: 'n_0_0',
        type: NodeType.combat,
        row: 0,
        col: 0,
        isAvailable: true,
        isVisited: false,
        nextNodeIds: ['n_1_0', 'n_1_1'],
      );
      final json = node.toJson();
      final restored = MapNode.fromJson(json);
      expect(restored.id, node.id);
      expect(restored.type, node.type);
      expect(restored.row, node.row);
      expect(restored.col, node.col);
      expect(restored.isAvailable, node.isAvailable);
      expect(restored.isVisited, node.isVisited);
      expect(restored.nextNodeIds, node.nextNodeIds);
    });
  });

  group('RunMap serialization', () {
    test('toJson / fromJson round-trip preserves nodes and startNodeId', () {
      final original = RunMap.generate(seed: 42, actRows: 4);
      final json = original.toJson();
      final restored = RunMap.fromJson(json);
      expect(restored.startNodeId, original.startNodeId);
      expect(restored.nodes.length, original.nodes.length);
      for (final entry in original.nodes.entries) {
        final r = restored.nodes[entry.key]!;
        expect(r.id, entry.value.id);
        expect(r.type, entry.value.type);
        expect(r.row, entry.value.row);
        expect(r.col, entry.value.col);
        expect(r.isAvailable, entry.value.isAvailable);
        expect(r.isVisited, entry.value.isVisited);
        expect(r.nextNodeIds, entry.value.nextNodeIds);
      }
    });
  });
}
