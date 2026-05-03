import 'dart:math' as math;

import 'package:match_fantasy/game/models/battle_presentation_event.dart';
import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/board_move_result.dart';
import 'package:match_fantasy/game/models/combat_cue.dart';
import 'package:match_fantasy/game/models/gem_tile.dart';

class BattlePresentationPlanner {
  const BattlePresentationPlanner();

  static const List<int> _durationPattern = <int>[220, 280, 340, 400, 460];
  static const List<double> _arcHeightPattern = <double>[
    0.24,
    0.36,
    0.30,
    0.42,
    0.34,
  ];
  static const List<double> _arcBiasPattern = <double>[
    -0.28,
    0.0,
    0.28,
    -0.22,
    0.22,
  ];

  List<BattlePresentationEvent> build({
    required BoardMoveResult move,
    required List<CombatCue> cues,
    required int comboCount,
    GemSpecialKind? synergyKindA,
    GemSpecialKind? synergyKindB,
  }) {
    final List<BattlePresentationEvent> events = <BattlePresentationEvent>[
      BoardAnimationPresentationEvent(move: move),
      BoardFeedbackPresentationEvent(move: move),
    ];

    if (comboCount >= 3) {
      events.add(
        ComboBannerPresentationEvent(
          comboCount: comboCount,
          delayMs: 60,
        ),
      );
    }

    if (synergyKindA != null && synergyKindB != null) {
      final BlockType? primaryElement = move.matchBonuses.isNotEmpty
          ? move.matchBonuses.first.element
          : null;
      final BlockType? secondaryElement = move.matchBonuses.length >= 2
          ? move.matchBonuses[1].element
          : primaryElement;
      events.add(
        SynergyBannerPresentationEvent(
          firstKind: synergyKindA,
          secondKind: synergyKindB,
          primaryElement: primaryElement,
          secondaryElement: secondaryElement,
        ),
      );
    }

    var burstCueIndex = 0;
    for (final CombatCue cue in cues) {
      switch (cue.kind) {
        case CombatCueKind.elementBurst:
          events.add(
            CombatCuePresentationEvent(
              cue: cue,
              delayMs: burstCueIndex == 0 ? 0 : 40,
            ),
          );
          events.add(
            ProjectileVolleyPresentationEvent(
              projectiles: _projectilesForCue(
                cue,
                comboCount: comboCount,
                offsetSeed: burstCueIndex,
              ),
            ),
          );
          burstCueIndex++;
          break;
        case CombatCueKind.lineBlast:
        case CombatCueKind.nova:
        case CombatCueKind.meteor:
          events.add(CombatCuePresentationEvent(cue: cue));
          break;
      }
    }

    return events;
  }

  List<PresentationProjectile> _projectilesForCue(
    CombatCue cue, {
    required int comboCount,
    required int offsetSeed,
  }) {
    final int projectileCount = math.max(1, math.min(cue.burstCount, 3));
    final int trailingMagnitude = cue.magnitude;

    return List<PresentationProjectile>.generate(projectileCount, (int index) {
      final int patternIndex =
          (offsetSeed + index) % _durationPattern.length;
      return PresentationProjectile(
        element: cue.element!,
        travelDurationMs: _durationPattern[patternIndex],
        arcHeightFactor:
            _arcHeightPattern[patternIndex] + ((projectileCount - 1) * 0.03),
        arcBias: _arcBiasPattern[patternIndex],
        impactMagnitude: index == projectileCount - 1 ? trailingMagnitude : 0,
        comboCount: comboCount,
        starBoost: cue.starBoost,
        showImpactLabel: index == projectileCount - 1,
      );
    });
  }
}
