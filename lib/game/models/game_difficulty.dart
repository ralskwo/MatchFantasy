enum GameDifficulty { story, normal, heroic }

extension GameDifficultyMetadata on GameDifficulty {
  String get label => switch (this) {
    GameDifficulty.story => 'Story',
    GameDifficulty.normal => 'Normal',
    GameDifficulty.heroic => 'Heroic',
  };

  String get helperText => switch (this) {
    GameDifficulty.story => 'Forgiving waves and more health',
    GameDifficulty.normal => 'Baseline wave pressure',
    GameDifficulty.heroic => 'Faster, tougher, denser waves',
  };

  int get maxHealth => switch (this) {
    GameDifficulty.story => 36,
    GameDifficulty.normal => 30,
    GameDifficulty.heroic => 26,
  };

  double get waveHealthMultiplier => switch (this) {
    GameDifficulty.story => 0.88,
    GameDifficulty.normal => 1.0,
    GameDifficulty.heroic => 1.18,
  };

  double get waveSpeedMultiplier => switch (this) {
    GameDifficulty.story => 0.9,
    GameDifficulty.normal => 1.0,
    GameDifficulty.heroic => 1.12,
  };

  double get spawnIntervalMultiplier => switch (this) {
    GameDifficulty.story => 1.16,
    GameDifficulty.normal => 1.0,
    GameDifficulty.heroic => 0.88,
  };

  int get itemStock => switch (this) {
    GameDifficulty.story => 2,
    GameDifficulty.normal => 1,
    GameDifficulty.heroic => 1,
  };
}
