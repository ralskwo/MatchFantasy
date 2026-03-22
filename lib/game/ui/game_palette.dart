import 'package:flutter/material.dart';
import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/monster_state.dart';

class GamePalette {
  static const Color backgroundTop = Color(0xFF06111F);
  static const Color backgroundBottom = Color(0xFF0A1F2F);
  static const Color accent = Color(0xFFFF8C42);
  static const Color secondaryAccent = Color(0xFF4BD0D1);
  static const Color boardTile = Color(0xFF13253B);
  static const Color boardTileBorder = Color(0xFF274566);
  static const Color battlefield = Color(0xFF0C1D30);
  static const Color battlefieldEdge = Color(0xFF284563);
  static const Color defenseLine = Color(0xFFFFD166);
  static const Color textPrimary = Color(0xFFF4F8FF);
  static const Color textMuted = Color(0xFF9AB3CC);

  static Color block(BlockType type) => switch (type) {
    BlockType.ember => const Color(0xFFFF6B4A),
    BlockType.tide => const Color(0xFF4CC9F0),
    BlockType.bloom => const Color(0xFF8AC926),
    BlockType.spark => const Color(0xFFFFD166),
    BlockType.umbra => const Color(0xFFC77DFF),
  };

  static Color monster(MonsterKind kind) => switch (kind) {
    MonsterKind.grunt => const Color(0xFF7FDBFF),
    MonsterKind.runner => const Color(0xFFFFB703),
    MonsterKind.brute => const Color(0xFFFF6B6B),
    MonsterKind.boss => const Color(0xFFFB5607),
  };
}
