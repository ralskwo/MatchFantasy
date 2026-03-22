import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/monster_state.dart';

extension BlockTypeAssetPath on BlockType {
  String get iconAsset => switch (this) {
    BlockType.ember => 'assets/icons/elements/ember.png',
    BlockType.tide => 'assets/icons/elements/tide.png',
    BlockType.bloom => 'assets/icons/elements/bloom.png',
    BlockType.spark => 'assets/icons/elements/spark.png',
    BlockType.umbra => 'assets/icons/elements/umbra.png',
  };
}

extension MonsterKindAssetPath on MonsterKind {
  String get iconAsset => switch (this) {
    MonsterKind.grunt => 'assets/icons/enemies/grunt.png',
    MonsterKind.runner => 'assets/icons/enemies/runner.png',
    MonsterKind.brute => 'assets/icons/enemies/brute.png',
    MonsterKind.boss => 'assets/icons/enemies/boss.png',
  };
}
