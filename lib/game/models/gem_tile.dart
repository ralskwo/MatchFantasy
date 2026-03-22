import 'package:match_fantasy/game/models/block_type.dart';

enum GemSpecialKind { line, nova }

extension GemSpecialKindMetadata on GemSpecialKind {
  String get marker => switch (this) {
    GemSpecialKind.line => 'L',
    GemSpecialKind.nova => 'N',
  };
}

class GemTile {
  const GemTile({
    this.id = 0,
    required this.type,
    required this.power,
    this.isStar = false,
    this.special,
  });

  final int id;
  final BlockType type;
  final int power;
  final bool isStar;
  final GemSpecialKind? special;

  bool get isSpecial => special != null;

  GemTile copyWith({
    int? id,
    BlockType? type,
    int? power,
    bool? isStar,
    GemSpecialKind? special,
    bool clearSpecial = false,
  }) {
    return GemTile(
      id: id ?? this.id,
      type: type ?? this.type,
      power: power ?? this.power,
      isStar: isStar ?? this.isStar,
      special: clearSpecial ? null : (special ?? this.special),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GemTile &&
        other.id == id &&
        other.type == type &&
        other.power == power &&
        other.isStar == isStar &&
        other.special == special;
  }

  @override
  int get hashCode => Object.hash(id, type, power, isStar, special);
}
