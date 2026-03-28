import 'package:match_fantasy/game/models/block_type.dart';

enum MonsterKind { grunt, runner, brute, boss }

extension MonsterKindStats on MonsterKind {
  String get label => switch (this) {
    MonsterKind.grunt => 'Grunt',
    MonsterKind.runner => 'Runner',
    MonsterKind.brute => 'Brute',
    MonsterKind.boss => 'Boss',
  };

  double get baseHealth => switch (this) {
    MonsterKind.grunt => 36,
    MonsterKind.runner => 28,
    MonsterKind.brute => 78,
    MonsterKind.boss => 180,
  };

  double get speed => switch (this) {
    MonsterKind.grunt => 0.11,
    MonsterKind.runner => 0.17,
    MonsterKind.brute => 0.09,
    MonsterKind.boss => 0.065,
  };

  int get breachDamage => switch (this) {
    MonsterKind.grunt => 2,
    MonsterKind.runner => 2,
    MonsterKind.brute => 3,
    MonsterKind.boss => 5,
  };

  double get scale => switch (this) {
    MonsterKind.grunt => 1.0,
    MonsterKind.runner => 0.9,
    MonsterKind.brute => 1.15,
    MonsterKind.boss => 1.3,
  };

  double get damageTakenMultiplier => switch (this) {
    MonsterKind.grunt => 1.0,
    MonsterKind.runner => 1.0,
    MonsterKind.brute => 0.72,
    MonsterKind.boss => 0.84,
  };

  bool get isArmored => switch (this) {
    MonsterKind.grunt => false,
    MonsterKind.runner => false,
    MonsterKind.brute => true,
    MonsterKind.boss => true,
  };

  String get glyph => switch (this) {
    MonsterKind.grunt => 'G',
    MonsterKind.runner => 'R',
    MonsterKind.brute => 'B',
    MonsterKind.boss => 'X',
  };
}

extension MonsterKindAffinity on MonsterKind {
  BlockType? get weakTo => switch (this) {
    MonsterKind.grunt  => BlockType.ember,
    MonsterKind.runner => BlockType.spark,
    MonsterKind.brute  => BlockType.tide,
    MonsterKind.boss   => null,
  };

  BlockType? get resistTo => switch (this) {
    MonsterKind.grunt  => BlockType.umbra,
    MonsterKind.runner => BlockType.bloom,
    MonsterKind.brute  => BlockType.ember,
    MonsterKind.boss   => null,
  };
}

class MonsterState {
  MonsterState({
    required this.id,
    required this.kind,
    required this.lane,
    required this.maxHealth,
    required this.speed,
  }) : health = maxHealth;

  final int id;
  final MonsterKind kind;
  final int lane;
  final double maxHealth;
  final double speed;
  double health;
  double progress = 0;
  double slowFactor = 1;
  double slowTimer = 0;
  double hasteFactor = 1;
  double hasteTimer = 0;
  bool rushTriggered = false;
  double hitFlashTimer = 0.0;

  bool get isAlive => health > 0;
  double get healthRatio => health <= 0 ? 0 : health / maxHealth;

  void applyDamage(double amount) {
    health -= amount * kind.damageTakenMultiplier;
  }
}
