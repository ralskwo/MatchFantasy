import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:match_fantasy/game/models/layout_mode.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';

class MetaState extends ChangeNotifier {
  static const _key = 'meta_state_v1';

  int currency = 0;
  Set<String> unlockedClassIds = {PlayerClassId.emberKnight.name};
  Set<String> unlockedRelicIds = {
    'worn_helmet',
    'mana_crystal',
    'lucky_coin',
    'flame_seal',
    'fragment_armor',
  };
  Map<String, int> achievementProgress = {};
  Map<String, int> highScores = {};
  int totalRuns = 0;
  int totalKills = 0;
  LayoutMode layoutMode = LayoutMode.portrait;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      notifyListeners();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_toJson()));
  }

  void addCurrency(int amount) {
    currency += amount;
    save();
    notifyListeners();
  }

  void spendCurrency(int amount) {
    currency = (currency - amount).clamp(0, 999999);
    save();
    notifyListeners();
  }

  void unlockClass(String id) {
    unlockedClassIds.add(id);
    save();
    notifyListeners();
  }

  void unlockRelic(String id) {
    unlockedRelicIds.add(id);
    save();
    notifyListeners();
  }

  void incrementAchievement(String key, {int by = 1}) {
    achievementProgress[key] = (achievementProgress[key] ?? 0) + by;
    save();
    notifyListeners();
  }

  void resetAchievement(String key) {
    achievementProgress[key] = 0;
    save();
    notifyListeners();
  }

  void checkAchievements() {
    // 첫 걸음: Act 1 보스 클리어 → Bloom Warden 해금
    if (!unlockedClassIds.contains(PlayerClassId.bloomWarden.name) &&
        (achievementProgress['act1_boss_clear'] ?? 0) >= 1) {
      unlockClass(PlayerClassId.bloomWarden.name);
    }
    // 대학살: 몬스터 200마리 처치 → 혼돈의 주사위 해금
    if (!unlockedRelicIds.contains('chaos_dice') &&
        (achievementProgress['total_kills'] ?? 0) >= 200) {
      unlockRelic('chaos_dice');
    }
    // 탐욕: 상점 3번 → 생명의 씨앗 해금
    if (!unlockedRelicIds.contains('life_seed') &&
        (achievementProgress['shop_visits'] ?? 0) >= 3) {
      unlockRelic('life_seed');
    }
  }

  void recordRunEnd({
    required int nodesCleared,
    required int kills,
    required int hpLeft,
    required bool act3Cleared,
  }) {
    totalRuns++;
    totalKills += kills;
    int earned = nodesCleared * 5 + kills * 1 + hpLeft * 2;
    if (act3Cleared) earned += 100;
    addCurrency(earned);
    save();
    notifyListeners();
  }

  void setLayoutMode(LayoutMode mode) {
    layoutMode = mode;
    save();
    notifyListeners();
  }

  Map<String, dynamic> _toJson() => {
        'currency': currency,
        'unlockedClassIds': unlockedClassIds.toList(),
        'unlockedRelicIds': unlockedRelicIds.toList(),
        'achievementProgress': achievementProgress,
        'highScores': highScores,
        'totalRuns': totalRuns,
        'totalKills': totalKills,
        'layoutMode': layoutMode.name,
      };

  void _fromJson(Map<String, dynamic> j) {
    currency = j['currency'] as int? ?? 0;
    unlockedClassIds =
        Set<String>.from(j['unlockedClassIds'] as List? ?? []);
    unlockedRelicIds =
        Set<String>.from(j['unlockedRelicIds'] as List? ?? []);
    achievementProgress =
        Map<String, int>.from(j['achievementProgress'] as Map? ?? {});
    highScores = Map<String, int>.from(j['highScores'] as Map? ?? {});
    totalRuns = j['totalRuns'] as int? ?? 0;
    totalKills = j['totalKills'] as int? ?? 0;
    layoutMode = LayoutMode.values.firstWhere(
      (m) => m.name == (j['layoutMode'] as String? ?? 'portrait'),
      orElse: () => LayoutMode.portrait,
    );
  }
}
