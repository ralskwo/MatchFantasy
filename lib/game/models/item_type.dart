enum ItemType { timeStone, sageStone, spiritDust, moonStone, sunStone }

extension ItemTypeMetadata on ItemType {
  String get label => switch (this) {
    ItemType.timeStone => 'Time Stone',
    ItemType.sageStone => 'Sage Stone',
    ItemType.spiritDust => 'Spirit Dust',
    ItemType.moonStone => 'Moon Stone',
    ItemType.sunStone => 'Sun Stone',
  };

  String get shortLabel => switch (this) {
    ItemType.timeStone => 'Time',
    ItemType.sageStone => 'Reload',
    ItemType.spiritDust => 'Hint',
    ItemType.moonStone => 'Numbers',
    ItemType.sunStone => 'Burst',
  };

  String get helperText => switch (this) {
    ItemType.timeStone => 'Stop monsters for a moment',
    ItemType.sageStone => 'Reload the whole board',
    ItemType.spiritDust => 'Reveal a valid swap',
    ItemType.moonStone => 'Tap a gem to reroll its number',
    ItemType.sunStone => 'Tap a gem to explode nearby blocks',
  };
}
