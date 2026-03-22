enum RelicRarity { common, uncommon, rare, boss }

class Relic {
  const Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.effect,
  });

  final String id;
  final String name;
  final String description;
  final RelicRarity rarity;
  final RelicEffect effect;
}

enum RelicEffectTag {
  startHp,
  startMana,
  startGold,
  burstDamage,
  manaOnMatch,
  shieldOnBurst,
  meteorCostReduction,
  slowDuration,
  shopDiscount,
  onKillMana,
  onKillShield,
  phoenixRevive,
  manaOnTick,
  randomBuffDebuff,
  boardExpand,
}

class RelicEffect {
  const RelicEffect({required this.tag, this.value = 0.0});
  final RelicEffectTag tag;
  final double value;
}
