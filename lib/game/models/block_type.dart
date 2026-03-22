enum BlockType { ember, tide, bloom, spark, umbra }

extension BlockTypeMetadata on BlockType {
  String get label => switch (this) {
    BlockType.ember => 'Ember',
    BlockType.tide => 'Tide',
    BlockType.bloom => 'Bloom',
    BlockType.spark => 'Spark',
    BlockType.umbra => 'Void',
  };

  String get glyph => switch (this) {
    BlockType.ember => 'F',
    BlockType.tide => 'M',
    BlockType.bloom => 'H',
    BlockType.spark => 'S',
    BlockType.umbra => 'A',
  };
}
