import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/game/models/monster_state.dart';
import 'package:match_fantasy/game/models/wave_profile.dart';
import 'package:match_fantasy/game/systems/wave_controller.dart';

void main() {
  test('wave controller advances through data-driven profiles', () {
    final WaveController wave = WaveController(
      random: Random(1),
      profiles: const <WaveProfile>[
        WaveProfile(
          label: 'Opening',
          durationSeconds: 1,
          spawnInterval: 99,
          packSize: 0,
          spawns: <MonsterSpawnRule>[
            MonsterSpawnRule(kind: MonsterKind.grunt, weight: 1),
          ],
        ),
        WaveProfile(
          label: 'Boss Test',
          durationSeconds: 10,
          spawnInterval: 99,
          packSize: 0,
          spawns: <MonsterSpawnRule>[
            MonsterSpawnRule(kind: MonsterKind.grunt, weight: 1),
          ],
          guaranteedBoss: true,
          bossPattern: BossPattern.shockwave,
          bossSkillInterval: 0.5,
        ),
      ],
    );

    final WaveTickResult advance = wave.update(1.1);

    expect(wave.waveNumber, 2);
    expect(wave.profile.label, 'Boss Test');
    expect(
      wave.monsters.any((MonsterState m) => m.kind == MonsterKind.boss),
      isTrue,
    );
    expect(advance.messages, contains('Wave 2 - Boss Test'));
  });

  test('boss shockwave pattern deals direct barrier damage', () {
    final WaveController wave = WaveController(
      random: Random(2),
      profiles: const <WaveProfile>[
        WaveProfile(
          label: 'Boss Test',
          durationSeconds: 10,
          spawnInterval: 99,
          packSize: 0,
          spawns: <MonsterSpawnRule>[
            MonsterSpawnRule(kind: MonsterKind.grunt, weight: 1),
          ],
          guaranteedBoss: true,
          bossPattern: BossPattern.shockwave,
          bossSkillInterval: 0.5,
        ),
      ],
    );

    final WaveTickResult tick = wave.update(0.6);

    expect(tick.breachDamage, greaterThanOrEqualTo(1));
    expect(tick.messages, contains('Boss shockwave hit the barrier.'));
  });

  test('boss rally pattern applies haste to monsters', () {
    final WaveController wave = WaveController(
      random: Random(3),
      profiles: const <WaveProfile>[
        WaveProfile(
          label: 'Rally Test',
          durationSeconds: 10,
          spawnInterval: 0.2,
          packSize: 1,
          spawns: <MonsterSpawnRule>[
            MonsterSpawnRule(kind: MonsterKind.grunt, weight: 1),
          ],
          guaranteedBoss: true,
          bossPattern: BossPattern.rally,
          bossSkillInterval: 0.3,
        ),
      ],
    );

    wave.update(0.25);
    final WaveTickResult tick = wave.update(0.15);

    expect(tick.messages, contains('Boss rally hastened the wave.'));
    expect(wave.monsters.any((MonsterState m) => m.hasteFactor > 1), isTrue);
  });

  test('runner gains a burst of speed mid-lane', () {
    final WaveController wave = WaveController(
      random: Random(4),
      profiles: const <WaveProfile>[
        WaveProfile(
          label: 'Runner Test',
          durationSeconds: 10,
          spawnInterval: 99,
          packSize: 0,
          spawns: <MonsterSpawnRule>[
            MonsterSpawnRule(kind: MonsterKind.runner, weight: 1),
          ],
        ),
      ],
    );

    final MonsterState runner = MonsterState(
      id: 999,
      kind: MonsterKind.runner,
      lane: 1,
      maxHealth: MonsterKind.runner.baseHealth,
      speed: MonsterKind.runner.speed,
    )..progress = 0.5;
    wave.monsters.add(runner);

    wave.update(0.1);

    expect(runner.rushTriggered, isTrue);
    expect(runner.hasteFactor, greaterThan(1));
    expect(runner.progress, greaterThan(0.5));
  });

  test('brute resists part of incoming damage', () {
    final WaveController wave = WaveController(
      random: Random(5),
      profiles: const <WaveProfile>[
        WaveProfile(
          label: 'Brute Test',
          durationSeconds: 10,
          spawnInterval: 99,
          packSize: 0,
          spawns: <MonsterSpawnRule>[
            MonsterSpawnRule(kind: MonsterKind.brute, weight: 1),
          ],
        ),
      ],
    );

    final MonsterState brute = MonsterState(
      id: 1000,
      kind: MonsterKind.brute,
      lane: 0,
      maxHealth: MonsterKind.brute.baseHealth,
      speed: MonsterKind.brute.speed,
    );
    wave.monsters.add(brute);

    wave.damageFrontMonster(10);

    expect(
      brute.health,
      closeTo(
        brute.maxHealth - (10 * MonsterKind.brute.damageTakenMultiplier),
        0.001,
      ),
    );
  });

  test('difficulty modifiers change spawn health and timing', () {
    final WaveController wave = WaveController(
      random: Random(6),
      healthMultiplier: 1.2,
      speedMultiplier: 1.1,
      spawnIntervalMultiplier: 0.8,
      profiles: const <WaveProfile>[
        WaveProfile(
          label: 'Scaled',
          durationSeconds: 10,
          spawnInterval: 1,
          packSize: 1,
          spawns: <MonsterSpawnRule>[
            MonsterSpawnRule(kind: MonsterKind.grunt, weight: 1),
          ],
        ),
      ],
    );

    wave.update(0.79);
    expect(wave.monsters, isEmpty);

    wave.update(0.02);
    expect(wave.monsters.length, 1);
    expect(
      wave.monsters.first.maxHealth,
      closeTo((MonsterKind.grunt.baseHealth + 3) * 1.2, 0.001),
    );
    expect(
      wave.monsters.first.speed,
      closeTo((MonsterKind.grunt.speed + 0) * 1.1, 0.001),
    );
  });
}
