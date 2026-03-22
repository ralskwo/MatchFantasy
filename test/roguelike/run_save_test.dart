import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/roguelike/models/map_node.dart';
import 'package:match_fantasy/roguelike/models/run_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:match_fantasy/roguelike/data/classes_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

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

  group('RunState serialization', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('toSaveJson / fromSaveJson round-trip preserves run state', () {
      final run = RunState();
      run.startRun(
        playerClass: allClasses.first,
        startingRelic: relicById('flame_seal'),
        runMap: RunMap.generate(seed: 99, actRows: 4),
      );
      run.earnGold(50);
      run.takeDamage(5);

      final json = run.toSaveJson();
      final restored = RunState();
      restored.fromSaveJson(json);

      expect(restored.isActive, true);
      expect(restored.health, run.health);
      expect(restored.gold, run.gold);
      expect(restored.selectedClass?.id, run.selectedClass?.id);
      expect(restored.relics.map((r) => r.id), run.relics.map((r) => r.id));
      expect(restored.map?.startNodeId, run.map?.startNodeId);
      expect(restored.maxHealth, run.maxHealth);
      expect(restored.currentNodeId, run.currentNodeId);
      expect(restored.actNumber, run.actNumber);
      expect(restored.cards.map((c) => c.id), run.cards.map((c) => c.id));
    });

    test('endRun sets isActive false', () async {
      SharedPreferences.setMockInitialValues({});
      final run = RunState();
      run.startRun(
        playerClass: allClasses.first,
        startingRelic: relicById('flame_seal'),
        runMap: RunMap.generate(seed: 1, actRows: 4),
      );
      expect(run.isActive, true);
      run.endRun();
      expect(run.isActive, false);
    });

    test('endRun clears persisted save', () async {
      SharedPreferences.setMockInitialValues({});
      final run = RunState();
      run.startRun(
        playerClass: allClasses.first,
        startingRelic: relicById('flame_seal'),
        runMap: RunMap.generate(seed: 2, actRows: 4),
      );
      await run.save();
      final prefsBeforeEnd = await SharedPreferences.getInstance();
      expect(prefsBeforeEnd.getString('run_save_v1'), isNotNull);
      run.endRun();
      await Future.delayed(Duration.zero);
      final prefsAfterEnd = await SharedPreferences.getInstance();
      expect(prefsAfterEnd.getString('run_save_v1'), isNull);
    });
  });
}
