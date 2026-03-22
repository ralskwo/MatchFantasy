enum CardKind { passive, active }

class UpgradeCard {
  const UpgradeCard({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    this.usesPerCombat = 0,
    required this.effect,
  });

  final String id;
  final String name;
  final String description;
  final CardKind kind;
  final int usesPerCombat;
  final CardEffect effect;
}

enum CardEffectTag {
  extraClear,
  specialChance,
  burstDamage,
  elementSynergyDamage,
  activeElementClear,
  activeShield,
  activeTimeStop,
  activeBoardRefresh,
  manaOnKill,
  hpOnKill,
}

class CardEffect {
  const CardEffect({required this.tag, this.value = 0.0});
  final CardEffectTag tag;
  final double value;
}
