import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';
import 'package:match_fantasy/roguelike/models/map_node.dart';
import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';

void main() {
  group('PlayerClass', () {
    test('has required fields', () {
      const cls = PlayerClass(
        id: PlayerClassId.emberKnight,
        name: 'Ember Knight',
        element: BlockType.ember,
        passiveDescription: 'Ember 버스트 데미지 +30%',
        startingRelicIds: ['flame_seal', 'mana_crystal', 'lucky_coin'],
      );
      expect(cls.id, PlayerClassId.emberKnight);
      expect(cls.startingRelicIds.length, 3);
    });
  });

  group('MapNode', () {
    test('starts not visited and not available', () {
      final node = MapNode(id: 'n1', type: NodeType.combat, row: 0, col: 0);
      expect(node.isVisited, false);
      expect(node.isAvailable, false);
    });
  });

  group('Relics', () {
    test('ancient_grid_stone has boardExpand tag', () {
      final relic = relicById('ancient_grid_stone');
      expect(relic.effect.tag, RelicEffectTag.boardExpand);
    });
  });
}
