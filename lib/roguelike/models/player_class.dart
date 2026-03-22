import 'package:match_fantasy/game/models/block_type.dart';

enum PlayerClassId {
  emberKnight,
  tideSage,
  bloomWarden,
  sparkTrickster,
  umbraReaper,
}

class PlayerClass {
  const PlayerClass({
    required this.id,
    required this.name,
    required this.element,
    required this.passiveDescription,
    required this.startingRelicIds,
  });

  final PlayerClassId id;
  final String name;
  final BlockType element;
  final String passiveDescription;
  final List<String> startingRelicIds;
}
