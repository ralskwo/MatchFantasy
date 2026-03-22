import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';

const List<PlayerClass> allClasses = [
  PlayerClass(
    id: PlayerClassId.emberKnight,
    name: 'Ember Knight',
    element: BlockType.ember,
    passiveDescription: 'Ember 버스트 데미지 +30%',
    startingRelicIds: ['flame_seal', 'mana_crystal', 'lucky_coin'],
  ),
  PlayerClass(
    id: PlayerClassId.tideSage,
    name: 'Tide Sage',
    element: BlockType.tide,
    passiveDescription: 'Tide 매치 시 마나 2배 회복',
    startingRelicIds: ['tidal_stone', 'worn_helmet', 'mana_crystal'],
  ),
  PlayerClass(
    id: PlayerClassId.bloomWarden,
    name: 'Bloom Warden',
    element: BlockType.bloom,
    passiveDescription: 'Bloom 버스트 시 실드 +3 추가 부여',
    startingRelicIds: ['life_seed', 'fragment_armor', 'worn_helmet'],
  ),
  PlayerClass(
    id: PlayerClassId.sparkTrickster,
    name: 'Spark Trickster',
    element: BlockType.spark,
    passiveDescription: 'Spark 슬로우 효과 지속 2배',
    startingRelicIds: ['lightning_feather', 'mana_crystal', 'lucky_coin'],
  ),
  PlayerClass(
    id: PlayerClassId.umbraReaper,
    name: 'Umbra Reaper',
    element: BlockType.umbra,
    passiveDescription: 'Umbra AOE 범위 +1칸',
    startingRelicIds: ['dark_scythe', 'fragment_armor', 'worn_helmet'],
  ),
];
