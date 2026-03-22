enum NodeType { combat, elite, shop, event, rest, boss }

class MapNode {
  MapNode({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
    this.isVisited = false,
    this.isAvailable = false,
    List<String>? nextNodeIds,
  }) : nextNodeIds = nextNodeIds ?? [];

  final String id;
  final NodeType type;
  final int row;
  final int col;
  bool isVisited;
  bool isAvailable;
  final List<String> nextNodeIds;
}
