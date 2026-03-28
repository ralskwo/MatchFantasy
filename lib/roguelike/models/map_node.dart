enum NodeType { combat, elite, shop, event, rest, boss, reward }

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'row': row,
        'col': col,
        'isAvailable': isAvailable,
        'isVisited': isVisited,
        'nextNodeIds': nextNodeIds,
      };

  factory MapNode.fromJson(Map<String, dynamic> j) => MapNode(
        id: j['id'] as String,
        type: NodeType.values.byName(j['type'] as String),
        row: j['row'] as int,
        col: j['col'] as int,
        isAvailable: j['isAvailable'] as bool,
        isVisited: j['isVisited'] as bool,
        nextNodeIds: List<String>.from(j['nextNodeIds'] as List),
      );
}
