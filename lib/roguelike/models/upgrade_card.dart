enum CardKind { passive, active }

class UpgradeCard {
  const UpgradeCard({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    this.usesPerCombat = 0,
    this.rechargeThreshold = 15,
    required this.effect,
  });

  final String id;
  final String name;
  final String description;
  final CardKind kind;
  final int usesPerCombat;
  // 타일 해소 몇 개마다 사용 횟수 1회 회복 (0 = 재충전 불가)
  final int rechargeThreshold;
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
  // 원소 특화 패시브 (Phase 2-C)
  emberChain,       // Ember 버스트 후 다음 Spark 버스트 데미지 +30%
  tideLeech,        // Tide AOE 처치 시 HP +1
  bloomFortress,    // Shield 최대치 +15
  sparkOverload,    // Spark 슬로우 적용 중 단일 타겟 데미지 +40%
  umbraReap,        // Umbra 버스트 처치 시 Mana +5
}

class CardEffect {
  const CardEffect({required this.tag, this.value = 0.0});
  final CardEffectTag tag;
  final double value;
}
