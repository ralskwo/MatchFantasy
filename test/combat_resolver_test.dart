import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/board_move_result.dart';
import 'package:match_fantasy/game/models/combat_cue.dart';
import 'package:match_fantasy/game/models/monster_state.dart';
import 'package:match_fantasy/game/models/wave_profile.dart';
import 'package:match_fantasy/game/systems/combat_resolver.dart';
import 'package:match_fantasy/game/systems/wave_controller.dart';

void main() {
  test('line blast bonus damages the front monster and emits a cue', () {
    final WaveController wave = _testWave();
    final MonsterState grunt = MonsterState(
      id: 1,
      kind: MonsterKind.grunt,
      lane: 1,
      maxHealth: MonsterKind.grunt.baseHealth,
      speed: MonsterKind.grunt.speed,
    )..progress = 0.7;
    wave.monsters.add(grunt);

    final CombatSummary summary = CombatResolver.resolveClear(
      move: const BoardMoveResult(
        isValid: true,
        clearedByType: <BlockType, ElementClearSummary>{
          BlockType.ember: ElementClearSummary(count: 4, powerTotal: 8),
        },
        matchBonuses: <MatchBonus>[
          MatchBonus(
            element: BlockType.ember,
            bonusType: MatchBonusType.lineBlast,
            size: 4,
            powerTotal: 8,
          ),
        ],
        clearedTiles: 4,
        clearedPower: 8,
      ),
      wave: wave,
      resources: SessionResources(maxHealth: 30, maxMana: 100),
      elementCharges: <BlockType, int>{
        for (final BlockType type in BlockType.values) type: 0,
      },
      sourceLabel: 'Match',
    );

    expect(
      summary.cues.any((CombatCue cue) => cue.kind == CombatCueKind.lineBlast),
      isTrue,
    );
    expect(summary.statusText, contains('Ember line 24'));
    expect(grunt.health, closeTo(12, 0.001));
  });

  test('nova bonus can wipe multiple monsters', () {
    final WaveController wave = _testWave();
    wave.monsters.addAll(<MonsterState>[
      MonsterState(
        id: 1,
        kind: MonsterKind.grunt,
        lane: 0,
        maxHealth: MonsterKind.grunt.baseHealth,
        speed: MonsterKind.grunt.speed,
      ),
      MonsterState(
        id: 2,
        kind: MonsterKind.grunt,
        lane: 2,
        maxHealth: MonsterKind.grunt.baseHealth,
        speed: MonsterKind.grunt.speed,
      ),
    ]);

    final CombatSummary summary = CombatResolver.resolveClear(
      move: const BoardMoveResult(
        isValid: true,
        matchBonuses: <MatchBonus>[
          MatchBonus(
            element: BlockType.umbra,
            bonusType: MatchBonusType.nova,
            size: 5,
            powerTotal: 15,
          ),
        ],
        clearedTiles: 5,
        clearedPower: 15,
      ),
      wave: wave,
      resources: SessionResources(maxHealth: 30, maxMana: 100),
      elementCharges: <BlockType, int>{
        for (final BlockType type in BlockType.values) type: 0,
      },
      sourceLabel: 'Match',
    );

    expect(
      summary.cues.any((CombatCue cue) => cue.kind == CombatCueKind.nova),
      isTrue,
    );
    expect(summary.defeatedMonsters, 2);
    expect(wave.monsters, isEmpty);
  });
}

WaveController _testWave() {
  return WaveController(
    random: Random(1),
    profiles: const <WaveProfile>[
      WaveProfile(
        label: 'Combat Test',
        durationSeconds: 10,
        spawnInterval: 99,
        packSize: 0,
        spawns: <MonsterSpawnRule>[
          MonsterSpawnRule(kind: MonsterKind.grunt, weight: 1),
        ],
      ),
    ],
  );
}
