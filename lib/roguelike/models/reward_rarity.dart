enum RewardRarity {
  common('Common', weight: 30, basePrice: 36),
  uncommon('Uncommon', weight: 18, basePrice: 58),
  rare('Rare', weight: 9, basePrice: 84),
  epic('Epic', weight: 4, basePrice: 120);

  const RewardRarity(
    this.label, {
    required this.weight,
    required this.basePrice,
  });

  final String label;
  final int weight;
  final int basePrice;
}
