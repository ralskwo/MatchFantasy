import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:match_fantasy/roguelike/data/classes_data.dart';
import 'package:match_fantasy/roguelike/data/relics_data.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:flutter/foundation.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
import 'package:match_fantasy/roguelike/models/reward_offer.dart';
import 'package:match_fantasy/roguelike/models/shop_offer.dart';
import 'package:match_fantasy/roguelike/models/upgrade_card.dart';
import 'package:match_fantasy/roguelike/models/run_map.dart';

class RunState extends ChangeNotifier {
  static const int maxCards = 10;

  PlayerClass? selectedClass;
  List<Relic> relics = [];
  List<UpgradeCard> cards = [];
  RunMap? map;
  String? currentNodeId;
  int health = 30;
  int maxHealth = 30;
  int gold = 0;
  int actNumber = 1;
  bool isActive = false;
  bool temporaryShopDiscount = false;
  int totalKills = 0;
  int maxCombo = 0;
  List<RewardOffer> pendingRewards = <RewardOffer>[];
  String? pendingShopNodeId;
  List<ShopOffer> pendingShopOffers = <ShopOffer>[];

  void setSelectedClass(PlayerClass cls) {
    selectedClass = cls;
    notifyListeners();
  }

  void startRun({
    required PlayerClass playerClass,
    required Relic startingRelic,
    required RunMap runMap,
  }) {
    selectedClass = playerClass;
    relics = [startingRelic];
    cards = [];
    map = runMap;
    currentNodeId = runMap.startNodeId;
    maxHealth = 30;
    health = maxHealth;
    gold = 20;
    actNumber = 1;
    isActive = true;
    temporaryShopDiscount = false;
    totalKills = 0;
    maxCombo = 0;
    pendingRewards = <RewardOffer>[];
    pendingShopNodeId = null;
    pendingShopOffers = <ShopOffer>[];
    notifyListeners();
  }

  void addRelic(Relic relic) {
    relics.add(relic);
    notifyListeners();
  }

  void addCard(UpgradeCard card) {
    if (cards.length < maxCards) {
      cards.add(card);
      notifyListeners();
    }
  }

  void removeCard(String cardId) {
    cards.removeWhere((c) => c.id == cardId);
    notifyListeners();
  }

  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
    notifyListeners();
  }

  void takeDamage(int amount) {
    health = (health - amount).clamp(0, maxHealth);
    notifyListeners();
  }

  void spendGold(int amount) {
    gold = (gold - amount).clamp(0, 9999);
    notifyListeners();
  }

  void earnGold(int amount) {
    gold += amount;
    notifyListeners();
  }

  void visitNode(String nodeId) {
    map?.visitNode(nodeId);
    currentNodeId = nodeId;
    notifyListeners();
  }

  void advanceAct() {
    actNumber += 1;
    currentNodeId = null;
    final seed = DateTime.now().millisecondsSinceEpoch;
    map = RunMap.generate(seed: seed, actRows: 5);
    notifyListeners();
    unawaited(save());
  }

  void endRun() {
    isActive = false;
    unawaited(clearSave());
    notifyListeners();
  }

  void recordCombatResult({required int kills, required int maxComboReached}) {
    totalKills += kills;
    if (maxComboReached > maxCombo) maxCombo = maxComboReached;
    notifyListeners();
  }

  void applyShopDiscount() {
    temporaryShopDiscount = true;
    notifyListeners();
  }

  void clearShopDiscount() {
    temporaryShopDiscount = false;
    notifyListeners();
  }

  void setPendingRewards(List<RewardOffer> rewards) {
    pendingRewards = List<RewardOffer>.of(rewards);
    notifyListeners();
  }

  void clearPendingRewards() {
    pendingRewards = <RewardOffer>[];
    notifyListeners();
  }

  void setShopOffersForNode(String nodeId, List<ShopOffer> offers) {
    pendingShopNodeId = nodeId;
    pendingShopOffers = List<ShopOffer>.of(offers);
    notifyListeners();
  }

  void clearPendingShopOffers() {
    pendingShopNodeId = null;
    pendingShopOffers = <ShopOffer>[];
    notifyListeners();
  }

  void markShopOfferPurchased(String offerId) {
    pendingShopOffers = pendingShopOffers
        .map((offer) => offer.id == offerId
            ? offer.copyWith(isPurchased: true)
            : offer)
        .toList();
    notifyListeners();
  }

  bool get isDead => health <= 0;
  bool hasRelic(String id) => relics.any((r) => r.id == id);

  static const String _saveKey = 'run_save_v1';

  Map<String, dynamic> toSaveJson() => {
    'classId': selectedClass!.id.name,
    'relicIds': relics.map((r) => r.id).toList(),
    'cardIds': cards.map((c) => c.id).toList(),
    'map': map!.toJson(),
    'currentNodeId': currentNodeId,
    'health': health,
    'maxHealth': maxHealth,
    'gold': gold,
    'actNumber': actNumber,
    'isActive': isActive,
    'temporaryShopDiscount': temporaryShopDiscount,
    'totalKills': totalKills,
    'maxCombo': maxCombo,
    'pendingRewards': <Map<String, dynamic>>[
      for (final reward in pendingRewards) reward.toJson(),
    ],
    'pendingShopNodeId': pendingShopNodeId,
    'pendingShopOffers': <Map<String, dynamic>>[
      for (final offer in pendingShopOffers) offer.toJson(),
    ],
  };

  void fromSaveJson(Map<String, dynamic> j) {
    final classId = PlayerClassId.values.byName(j['classId'] as String);
    selectedClass = allClasses.firstWhere((c) => c.id == classId);
    relics = (j['relicIds'] as List).map((id) => relicById(id as String)).toList();
    cards = (j['cardIds'] as List).map((id) => cardById(id as String)).toList();
    map = RunMap.fromJson(j['map'] as Map<String, dynamic>);
    currentNodeId = j['currentNodeId'] as String?;
    health = j['health'] as int;
    maxHealth = j['maxHealth'] as int;
    gold = j['gold'] as int;
    actNumber = j['actNumber'] as int;
    isActive = j['isActive'] as bool;
    temporaryShopDiscount = (j['temporaryShopDiscount'] as bool?) ?? false;
    totalKills = (j['totalKills'] as int?) ?? 0;
    maxCombo = (j['maxCombo'] as int?) ?? 0;
    pendingRewards = <RewardOffer>[
      for (final reward in j['pendingRewards'] as List<dynamic>? ?? const <dynamic>[])
        RewardOffer.fromJson(reward as Map<String, dynamic>),
    ];
    pendingShopNodeId = j['pendingShopNodeId'] as String?;
    pendingShopOffers = <ShopOffer>[
      for (final offer in j['pendingShopOffers'] as List<dynamic>? ?? const <dynamic>[])
        ShopOffer.fromJson(offer as Map<String, dynamic>),
    ];
    notifyListeners();
  }

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> save() async {
    if (!isActive) return;
    final prefs = await _getPrefs();
    await prefs.setString(_saveKey, jsonEncode(toSaveJson()));
  }

  Future<void> tryLoadSave() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_saveKey);
    if (raw == null) return;
    try {
      fromSaveJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_saveKey);
    }
  }

  Future<void> clearSave() async {
    final prefs = await _getPrefs();
    await prefs.remove(_saveKey);
  }
}
