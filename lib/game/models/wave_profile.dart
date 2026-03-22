import 'package:match_fantasy/game/models/monster_state.dart';

enum BossPattern { none, shockwave, rally, reinforce }

class MonsterSpawnRule {
  const MonsterSpawnRule({
    required this.kind,
    required this.weight,
    this.healthBonus = 0,
    this.speedBonus = 0,
  });

  final MonsterKind kind;
  final double weight;
  final double healthBonus;
  final double speedBonus;
}

class WaveProfile {
  const WaveProfile({
    required this.label,
    required this.durationSeconds,
    required this.spawnInterval,
    required this.packSize,
    required this.spawns,
    this.guaranteedBoss = false,
    this.bossPattern = BossPattern.none,
    this.bossSkillInterval = 0,
  });

  final String label;
  final double durationSeconds;
  final double spawnInterval;
  final int packSize;
  final List<MonsterSpawnRule> spawns;
  final bool guaranteedBoss;
  final BossPattern bossPattern;
  final double bossSkillInterval;
}

const List<WaveProfile> defaultWaveProfiles = <WaveProfile>[
  WaveProfile(
    label: 'Scout Rush',
    durationSeconds: 22,
    spawnInterval: 2.0,
    packSize: 1,
    spawns: <MonsterSpawnRule>[
      MonsterSpawnRule(kind: MonsterKind.grunt, weight: 0.65),
      MonsterSpawnRule(kind: MonsterKind.runner, weight: 0.35),
    ],
  ),
  WaveProfile(
    label: 'Split Raiders',
    durationSeconds: 24,
    spawnInterval: 1.65,
    packSize: 1,
    spawns: <MonsterSpawnRule>[
      MonsterSpawnRule(kind: MonsterKind.grunt, weight: 0.4),
      MonsterSpawnRule(kind: MonsterKind.runner, weight: 0.45),
      MonsterSpawnRule(kind: MonsterKind.brute, weight: 0.15),
    ],
  ),
  WaveProfile(
    label: 'Iron Push',
    durationSeconds: 24,
    spawnInterval: 1.45,
    packSize: 1,
    spawns: <MonsterSpawnRule>[
      MonsterSpawnRule(kind: MonsterKind.grunt, weight: 0.35),
      MonsterSpawnRule(kind: MonsterKind.runner, weight: 0.3),
      MonsterSpawnRule(kind: MonsterKind.brute, weight: 0.35),
    ],
  ),
  WaveProfile(
    label: 'Boss Shockwave',
    durationSeconds: 26,
    spawnInterval: 2.0,
    packSize: 1,
    spawns: <MonsterSpawnRule>[
      MonsterSpawnRule(kind: MonsterKind.runner, weight: 0.55),
      MonsterSpawnRule(kind: MonsterKind.brute, weight: 0.45),
    ],
    guaranteedBoss: true,
    bossPattern: BossPattern.shockwave,
    bossSkillInterval: 6.5,
  ),
  WaveProfile(
    label: 'Boss Rally',
    durationSeconds: 26,
    spawnInterval: 1.65,
    packSize: 1,
    spawns: <MonsterSpawnRule>[
      MonsterSpawnRule(kind: MonsterKind.grunt, weight: 0.35),
      MonsterSpawnRule(kind: MonsterKind.runner, weight: 0.4),
      MonsterSpawnRule(kind: MonsterKind.brute, weight: 0.25),
    ],
    guaranteedBoss: true,
    bossPattern: BossPattern.rally,
    bossSkillInterval: 7.0,
  ),
  WaveProfile(
    label: 'Boss Reinforce',
    durationSeconds: 28,
    spawnInterval: 1.6,
    packSize: 1,
    spawns: <MonsterSpawnRule>[
      MonsterSpawnRule(kind: MonsterKind.runner, weight: 0.5),
      MonsterSpawnRule(kind: MonsterKind.brute, weight: 0.3),
      MonsterSpawnRule(kind: MonsterKind.grunt, weight: 0.2),
    ],
    guaranteedBoss: true,
    bossPattern: BossPattern.reinforce,
    bossSkillInterval: 7.5,
  ),
];
