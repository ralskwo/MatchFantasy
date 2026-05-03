import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/board_move_result.dart';
import 'package:match_fantasy/game/models/combat_cue.dart';
import 'package:match_fantasy/game/models/gem_tile.dart';

sealed class BattlePresentationEvent {
  const BattlePresentationEvent({this.delayMs = 0});

  final int delayMs;
}

final class BoardAnimationPresentationEvent extends BattlePresentationEvent {
  const BoardAnimationPresentationEvent({
    required this.move,
    super.delayMs,
  });

  final BoardMoveResult move;
}

final class BoardFeedbackPresentationEvent extends BattlePresentationEvent {
  const BoardFeedbackPresentationEvent({
    required this.move,
    super.delayMs,
  });

  final BoardMoveResult move;
}

final class CombatCuePresentationEvent extends BattlePresentationEvent {
  const CombatCuePresentationEvent({
    required this.cue,
    super.delayMs,
  });

  final CombatCue cue;
}

final class ProjectileVolleyPresentationEvent extends BattlePresentationEvent {
  const ProjectileVolleyPresentationEvent({
    required this.projectiles,
    super.delayMs,
  });

  final List<PresentationProjectile> projectiles;
}

final class ComboBannerPresentationEvent extends BattlePresentationEvent {
  const ComboBannerPresentationEvent({
    required this.comboCount,
    super.delayMs,
  });

  final int comboCount;
}

final class SynergyBannerPresentationEvent extends BattlePresentationEvent {
  const SynergyBannerPresentationEvent({
    required this.firstKind,
    required this.secondKind,
    this.primaryElement,
    this.secondaryElement,
    super.delayMs,
  });

  final GemSpecialKind firstKind;
  final GemSpecialKind secondKind;
  final BlockType? primaryElement;
  final BlockType? secondaryElement;
}

final class PresentationProjectile {
  const PresentationProjectile({
    required this.element,
    required this.travelDurationMs,
    required this.arcHeightFactor,
    required this.arcBias,
    required this.impactMagnitude,
    required this.comboCount,
    required this.starBoost,
    required this.showImpactLabel,
  });

  final BlockType element;
  final int travelDurationMs;
  final double arcHeightFactor;
  final double arcBias;
  final int impactMagnitude;
  final int comboCount;
  final bool starBoost;
  final bool showImpactLabel;
}
