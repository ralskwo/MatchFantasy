import 'package:flutter_test/flutter_test.dart';
import 'package:match_fantasy/game/models/battle_presentation_event.dart';
import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/board_move_result.dart';
import 'package:match_fantasy/game/models/combat_cue.dart';
import 'package:match_fantasy/game/models/gem_tile.dart';
import 'package:match_fantasy/game/systems/battle_presentation_planner.dart';

void main() {
  test('planner emits combo banner and projectile volley for burst cues', () {
    const BattlePresentationPlanner planner = BattlePresentationPlanner();

    final List<BattlePresentationEvent> plan = planner.build(
      move: const BoardMoveResult(isValid: true),
      cues: const <CombatCue>[
        CombatCue(
          kind: CombatCueKind.elementBurst,
          element: BlockType.ember,
          magnitude: 28,
          burstCount: 2,
        ),
        CombatCue(
          kind: CombatCueKind.lineBlast,
          element: BlockType.tide,
          magnitude: 18,
        ),
      ],
      comboCount: 3,
      synergyKindA: GemSpecialKind.line,
      synergyKindB: GemSpecialKind.nova,
    );

    expect(plan.first, isA<BoardAnimationPresentationEvent>());
    expect(plan[1], isA<BoardFeedbackPresentationEvent>());
    expect(
      plan.whereType<ComboBannerPresentationEvent>().single.comboCount,
      3,
    );

    final ProjectileVolleyPresentationEvent volley = plan
        .whereType<ProjectileVolleyPresentationEvent>()
        .single;
    expect(volley.projectiles, hasLength(2));
    expect(
      volley.projectiles.last.showImpactLabel,
      isTrue,
    );
    expect(
      plan.whereType<SynergyBannerPresentationEvent>(),
      isNotEmpty,
    );
    expect(
      plan.whereType<CombatCuePresentationEvent>().length,
      2,
    );
  });
}
