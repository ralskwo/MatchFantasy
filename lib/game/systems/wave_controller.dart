import 'dart:math';

import 'package:match_fantasy/game/models/monster_state.dart';
import 'package:match_fantasy/game/models/wave_event.dart';
import 'package:match_fantasy/game/models/wave_profile.dart';

class WaveTickResult {
  const WaveTickResult({
    required this.breachDamage,
    this.events = const <WaveEvent>[],
  });

  final int breachDamage;
  final List<WaveEvent> events;

  List<String> get messages =>
      events.map((WaveEvent event) => event.message).toList(growable: false);
}

class WaveController {
  WaveController({
    Random? random,
    this.laneCount = 3,
    List<WaveProfile>? profiles,
    this.healthMultiplier = 1,
    this.speedMultiplier = 1,
    this.spawnIntervalMultiplier = 1,
  }) : _random = random ?? Random(),
       _profiles = profiles ?? defaultWaveProfiles {
    reset();
  }

  final Random _random;
  final int laneCount;
  final List<WaveProfile> _profiles;
  final double healthMultiplier;
  final double speedMultiplier;
  final double spawnIntervalMultiplier;
  final List<MonsterState> monsters = <MonsterState>[];

  int waveNumber = 1;

  int _nextMonsterId = 1;
  int _profileIndex = 0;
  int _loop = 0;
  double _timeInWave = 0;
  double _spawnTimer = 0;
  double _bossSkillTimer = 0;

  WaveProfile get profile => _profiles[_profileIndex];

  void reset() {
    monsters.clear();
    waveNumber = 1;
    _nextMonsterId = 1;
    _profileIndex = 0;
    _loop = 0;
    _timeInWave = 0;
    _startCurrentWave();
  }

  WaveTickResult update(double dt) {
    final List<WaveEvent> events = <WaveEvent>[];
    _timeInWave += dt;

    while (_timeInWave >= profile.durationSeconds) {
      _timeInWave -= profile.durationSeconds;
      events.addAll(_advanceWave());
    }

    _spawnTimer -= dt;
    while (_spawnTimer <= 0) {
      _spawnPack();
      _spawnTimer += _effectiveSpawnInterval;
    }

    int breachDamage = 0;
    if (_hasLivingBoss && profile.bossPattern != BossPattern.none) {
      _bossSkillTimer -= dt;
      while (_bossSkillTimer <= 0) {
        breachDamage += _triggerBossPattern(events);
        _bossSkillTimer += max(1, profile.bossSkillInterval);
      }
    }

    for (int index = monsters.length - 1; index >= 0; index--) {
      final MonsterState monster = monsters[index];
      if (monster.slowTimer > 0) {
        monster.slowTimer = max(0, monster.slowTimer - dt);
        if (monster.slowTimer == 0) {
          monster.slowFactor = 1;
        }
      }
      if (monster.hasteTimer > 0) {
        monster.hasteTimer = max(0, monster.hasteTimer - dt);
        if (monster.hasteTimer == 0) {
          monster.hasteFactor = 1;
        }
      }
      if (monster.kind == MonsterKind.runner &&
          !monster.rushTriggered &&
          monster.progress >= 0.48) {
        monster.rushTriggered = true;
        monster.hasteFactor = max(monster.hasteFactor, 1.65);
        monster.hasteTimer = max(monster.hasteTimer, 1.1);
      }

      monster.progress +=
          dt * monster.speed * monster.slowFactor * monster.hasteFactor;

      if (monster.progress >= 1) {
        breachDamage += monster.kind.breachDamage;
        monsters.removeAt(index);
      }
    }

    return WaveTickResult(breachDamage: breachDamage, events: events);
  }

  int damageFrontMonster(double amount) {
    final MonsterState? target = _frontMonster();
    if (target == null) {
      return 0;
    }
    target.applyDamage(amount);
    target.hitFlashTimer = 0.12;
    return _purgeDefeated();
  }

  int damageAll(double amount) {
    if (monsters.isEmpty) {
      return 0;
    }
    for (final MonsterState monster in monsters) {
      monster.applyDamage(amount);
      monster.hitFlashTimer = 0.12;
    }
    return _purgeDefeated();
  }

  void applySlowToAll({required double factor, required double duration}) {
    for (final MonsterState monster in monsters) {
      monster.slowFactor = min(monster.slowFactor, factor);
      monster.slowTimer = max(monster.slowTimer, duration);
    }
  }

  void applyHasteToAll({required double factor, required double duration}) {
    for (final MonsterState monster in monsters) {
      monster.hasteFactor = max(monster.hasteFactor, factor);
      monster.hasteTimer = max(monster.hasteTimer, duration);
    }
  }

  MonsterKind? get frontMonsterKind => _frontMonster()?.kind;

  bool get hasAnySlowed =>
      monsters.any((MonsterState m) => m.slowTimer > 0);

  MonsterState? _frontMonster() {
    if (monsters.isEmpty) {
      return null;
    }
    MonsterState target = monsters.first;
    for (final MonsterState monster in monsters.skip(1)) {
      if (monster.progress > target.progress) {
        target = monster;
      }
    }
    return target;
  }

  int _purgeDefeated() {
    int defeated = 0;
    for (int index = monsters.length - 1; index >= 0; index--) {
      if (!monsters[index].isAlive) {
        monsters.removeAt(index);
        defeated++;
      }
    }
    return defeated;
  }

  List<WaveEvent> _advanceWave() {
    _profileIndex++;
    if (_profileIndex >= _profiles.length) {
      _profileIndex = 0;
      _loop++;
    }
    waveNumber = (_loop * _profiles.length) + _profileIndex + 1;
    return _startCurrentWave(includeAnnouncement: true);
  }

  List<WaveEvent> _startCurrentWave({bool includeAnnouncement = false}) {
    final List<WaveEvent> events = <WaveEvent>[];
    _spawnTimer = profile.spawnInterval;
    _spawnTimer = _effectiveSpawnInterval;
    _bossSkillTimer = profile.bossSkillInterval;
    if (includeAnnouncement) {
      events.add(
        WaveEvent(
          type: WaveEventType.waveStart,
          message: 'Wave $waveNumber - ${profile.label}',
        ),
      );
    }
    if (profile.guaranteedBoss) {
      _spawnMonster(const MonsterSpawnRule(kind: MonsterKind.boss, weight: 1));
      events.add(
        WaveEvent(
          type: WaveEventType.bossArrival,
          message: 'Boss entered: ${profile.label}',
        ),
      );
    }
    return events;
  }

  void _spawnPack() {
    if (profile.packSize <= 0 || profile.spawns.isEmpty) {
      return;
    }
    for (int count = 0; count < profile.packSize; count++) {
      _spawnMonster(_pickSpawnRule(profile.spawns));
    }
  }

  void _spawnMonster(MonsterSpawnRule rule) {
    final double tierHealth = (_loop * 12) + ((_profileIndex + 1) * 3);
    final double tierSpeed = min(
      0.12,
      (_loop * 0.012) + (_profileIndex * 0.004),
    );
    monsters.add(
      MonsterState(
        id: _nextMonsterId++,
        kind: rule.kind,
        lane: _random.nextInt(laneCount),
        maxHealth:
            (rule.kind.baseHealth + tierHealth + rule.healthBonus) *
            healthMultiplier,
        speed:
            (rule.kind.speed + tierSpeed + rule.speedBonus) * speedMultiplier,
      ),
    );
  }

  MonsterSpawnRule _pickSpawnRule(List<MonsterSpawnRule> rules) {
    final double totalWeight = rules.fold<double>(
      0,
      (double sum, MonsterSpawnRule rule) => sum + rule.weight,
    );
    double roll = _random.nextDouble() * totalWeight;
    for (final MonsterSpawnRule rule in rules) {
      roll -= rule.weight;
      if (roll <= 0) {
        return rule;
      }
    }
    return rules.last;
  }

  bool get _hasLivingBoss {
    return monsters.any(
      (MonsterState monster) => monster.kind == MonsterKind.boss,
    );
  }

  int _triggerBossPattern(List<WaveEvent> events) {
    switch (profile.bossPattern) {
      case BossPattern.none:
        return 0;
      case BossPattern.shockwave:
        final int damage = 1 + (_loop ~/ 2);
        events.add(
          const WaveEvent(
            type: WaveEventType.bossShockwave,
            message: 'Boss shockwave hit the barrier.',
          ),
        );
        return damage;
      case BossPattern.rally:
        applyHasteToAll(factor: 1.45, duration: 2.8);
        events.add(
          const WaveEvent(
            type: WaveEventType.bossRally,
            message: 'Boss rally hastened the wave.',
          ),
        );
        return 0;
      case BossPattern.reinforce:
        _spawnMonster(
          MonsterSpawnRule(
            kind: MonsterKind.runner,
            weight: 1,
            healthBonus: 8 + (_loop * 2),
            speedBonus: 0.025,
          ),
        );
        _spawnMonster(
          MonsterSpawnRule(
            kind: MonsterKind.brute,
            weight: 1,
            healthBonus: 12 + (_loop * 3),
            speedBonus: 0.01,
          ),
        );
        events.add(
          const WaveEvent(
            type: WaveEventType.bossReinforce,
            message: 'Boss summoned reinforcements.',
          ),
        );
        return 0;
    }
  }

  double get _effectiveSpawnInterval {
    return max(0.28, profile.spawnInterval * spawnIntervalMultiplier);
  }
}
