import 'package:match_fantasy/game/models/block_type.dart';

enum CombatCueKind { elementBurst, lineBlast, nova, meteor }

class CombatCue {
  const CombatCue({
    required this.kind,
    this.element,
    this.magnitude = 0,
    this.burstCount = 1,
    this.starBoost = false,
  });

  final CombatCueKind kind;
  final BlockType? element;
  final int magnitude;
  final int burstCount;
  final bool starBoost;
}
