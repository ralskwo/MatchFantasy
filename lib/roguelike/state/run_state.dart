import 'package:flutter/foundation.dart';
import 'package:match_fantasy/roguelike/models/player_class.dart';
import 'package:match_fantasy/roguelike/models/relic.dart';
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

  void endRun() {
    isActive = false;
    notifyListeners();
  }

  bool get isDead => health <= 0;
  bool hasRelic(String id) => relics.any((r) => r.id == id);
}
