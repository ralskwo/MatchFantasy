import 'dart:math';

import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/board_move_result.dart';
import 'package:match_fantasy/game/models/combat_cue.dart';
import 'package:match_fantasy/game/systems/wave_controller.dart';

class SessionResources {
  SessionResources({required this.maxHealth, required this.maxMana})
    : health = maxHealth,
      shield = 0,
      mana = 0;

  final int maxHealth;
  final int maxMana;
  int health;
  int shield;
  int mana;

  void applyDamage(int amount) {
    final int absorbed = min(shield, amount);
    shield -= absorbed;
    health = max(0, health - (amount - absorbed));
  }

  void heal(int amount) {
    health = min(maxHealth, health + amount);
  }

  void addShield(int amount) {
    shield = min(40, shield + amount);
  }

  void addMana(int amount) {
    mana = min(maxMana, mana + amount);
  }

  bool spendMana(int amount) {
    if (mana < amount) {
      return false;
    }
    mana -= amount;
    return true;
  }
}

class CombatSummary {
  const CombatSummary({
    required this.statusText,
    required this.scoreDelta,
    required this.defeatedMonsters,
    this.cues = const <CombatCue>[],
  });

  final String statusText;
  final int scoreDelta;
  final int defeatedMonsters;
  final List<CombatCue> cues;
}

class CombatResolver {
  static CombatSummary resolveClear({
    required BoardMoveResult move,
    required WaveController wave,
    required SessionResources resources,
    required Map<BlockType, int> elementCharges,
    String? sourceLabel,
    double burstDamageMultiplier = 1.0,
  }) {
    if (!move.isValid) {
      return const CombatSummary(
        statusText: 'That action did not clear any gems.',
        scoreDelta: 0,
        defeatedMonsters: 0,
      );
    }

    final List<String> fragments = <String>[];
    final List<CombatCue> cues = <CombatCue>[];
    int defeated = 0;
    int burstCount = 0;
    int bonusScore = 0;

    for (final MapEntry<BlockType, ElementClearSummary> entry
        in move.clearedByType.entries) {
      final BlockType type = entry.key;
      final ElementClearSummary clear = entry.value;
      final int buffered = (elementCharges[type] ?? 0) + clear.powerTotal;
      final int bursts = buffered ~/ 10;
      elementCharges[type] = buffered % 10;

      if (bursts == 0) {
        fragments.add('${type.label} ${elementCharges[type]}/10');
        continue;
      }

      burstCount += bursts;
      final int starBonus = clear.starCount > 0 ? (clear.starCount * 4) + 2 : 0;
      final int damage = ((clear.powerTotal + starBonus) * bursts * burstDamageMultiplier).round().clamp(
        1,
        9999,
      );
      cues.add(
        CombatCue(
          kind: CombatCueKind.elementBurst,
          element: type,
          magnitude: damage,
          burstCount: bursts,
          starBoost: clear.starCount > 0,
        ),
      );

      switch (type) {
        case BlockType.ember:
          defeated += wave.damageFrontMonster(damage.toDouble());
          fragments.add('Ember burst $damage');
          break;
        case BlockType.tide:
          defeated += wave.damageAll(max(4, damage * 0.7).roundToDouble());
          resources.addMana(2 * bursts);
          fragments.add('Tide burst $damage');
          break;
        case BlockType.bloom:
          defeated += wave.damageFrontMonster(damage.toDouble());
          resources.heal(3 * bursts);
          resources.addShield(2 * bursts);
          fragments.add('Bloom burst $damage');
          break;
        case BlockType.spark:
          defeated += wave.damageFrontMonster(damage.toDouble());
          wave.applySlowToAll(factor: 0.5, duration: 2.4 + (0.4 * bursts));
          fragments.add('Spark burst $damage');
          break;
        case BlockType.umbra:
          defeated += wave.damageAll(damage.toDouble());
          fragments.add('Void burst $damage');
          break;
      }

      if (clear.starCount > 0) {
        fragments.add('Star +$starBonus');
      }
    }

    for (final MatchBonus bonus in move.matchBonuses) {
      final _ResolvedMatchBonus resolved = _resolveMatchBonus(
        bonus: bonus,
        wave: wave,
        resources: resources,
      );
      bonusScore += switch (bonus.bonusType) {
        MatchBonusType.lineBlast => 45 + (bonus.powerTotal * 2),
        MatchBonusType.nova => 90 + (bonus.powerTotal * 3),
      };
      defeated += resolved.defeated;
      fragments.add(resolved.fragment);
      cues.add(
        CombatCue(
          kind: switch (bonus.bonusType) {
            MatchBonusType.lineBlast => CombatCueKind.lineBlast,
            MatchBonusType.nova => CombatCueKind.nova,
          },
          element: bonus.element,
          magnitude: resolved.magnitude,
          starBoost: bonus.starCount > 0,
        ),
      );
    }

    if (move.comboDepth > 1) {
      fragments.add('${move.comboDepth}x combo');
    }
    if (defeated > 0) {
      fragments.add('$defeated down');
    }

    final String prefix = sourceLabel == null ? '' : '$sourceLabel - ';
    final String statusText = fragments.isEmpty
        ? '${prefix}Stored ${move.clearedPower} points.'
        : '$prefix${fragments.join(' - ')}';

    final int score =
        (move.clearedPower * 4) +
        (move.clearedTiles * 8) +
        (burstCount * 40) +
        bonusScore +
        (defeated * 25);

    return CombatSummary(
      statusText: statusText,
      scoreDelta: score,
      defeatedMonsters: defeated,
      cues: cues,
    );
  }

  static CombatSummary castMeteor({
    required WaveController wave,
    required SessionResources resources,
    required int manaCost,
  }) {
    if (!resources.spendMana(manaCost)) {
      return const CombatSummary(
        statusText: 'Need more mana for Meteor.',
        scoreDelta: 0,
        defeatedMonsters: 0,
      );
    }

    final int defeated = wave.damageAll(42);
    return CombatSummary(
      statusText: defeated > 0
          ? 'Meteor crushed $defeated monsters.'
          : 'Meteor scorched the front line.',
      scoreDelta: 90 + (defeated * 35),
      defeatedMonsters: defeated,
      cues: const <CombatCue>[
        CombatCue(kind: CombatCueKind.meteor, magnitude: 42),
      ],
    );
  }

  static _ResolvedMatchBonus _resolveMatchBonus({
    required MatchBonus bonus,
    required WaveController wave,
    required SessionResources resources,
  }) {
    final bool isNova = bonus.bonusType == MatchBonusType.nova;
    final int starPower = bonus.starCount * (isNova ? 5 : 3);
    final int basePower =
        bonus.powerTotal +
        (isNova ? 14 + (bonus.size * 4) : 8 + (bonus.size * 2)) +
        starPower;

    int magnitude = basePower;
    int defeated = 0;
    switch (bonus.element) {
      case BlockType.ember:
        magnitude = isNova ? max(18, (basePower * 0.85).round()) : basePower;
        defeated += isNova
            ? wave.damageAll(magnitude.toDouble())
            : wave.damageFrontMonster(magnitude.toDouble());
        break;
      case BlockType.tide:
        magnitude = isNova
            ? max(16, (basePower * 0.8).round())
            : max(10, (basePower * 0.65).round());
        defeated += wave.damageAll(magnitude.toDouble());
        resources.addMana(isNova ? 4 : 2);
        break;
      case BlockType.bloom:
        magnitude = isNova
            ? max(12, (basePower * 0.55).round())
            : max(10, (basePower * 0.85).round());
        defeated += isNova
            ? wave.damageAll(magnitude.toDouble())
            : wave.damageFrontMonster(magnitude.toDouble());
        resources.heal(isNova ? 6 : 3);
        resources.addShield(isNova ? 5 : 3);
        break;
      case BlockType.spark:
        magnitude = isNova ? max(14, (basePower * 0.68).round()) : basePower;
        defeated += isNova
            ? wave.damageAll(magnitude.toDouble())
            : wave.damageFrontMonster(magnitude.toDouble());
        wave.applySlowToAll(
          factor: isNova ? 0.46 : 0.68,
          duration: isNova ? 2.8 : 1.9,
        );
        break;
      case BlockType.umbra:
        magnitude = isNova ? basePower : max(12, (basePower * 0.8).round());
        defeated += wave.damageAll(magnitude.toDouble());
        break;
    }

    final String bonusName = switch (bonus.bonusType) {
      MatchBonusType.lineBlast => 'line',
      MatchBonusType.nova => 'nova',
    };
    final String starSuffix = bonus.starCount > 0 ? ' star' : '';
    return _ResolvedMatchBonus(
      magnitude: magnitude,
      defeated: defeated,
      fragment: '${bonus.element.label} $bonusName $magnitude$starSuffix',
    );
  }
}

class _ResolvedMatchBonus {
  const _ResolvedMatchBonus({
    required this.magnitude,
    required this.defeated,
    required this.fragment,
  });

  final int magnitude;
  final int defeated;
  final String fragment;
}
