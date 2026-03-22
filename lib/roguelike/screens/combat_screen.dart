import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:match_fantasy/game/match_fantasy_game.dart';
import 'package:match_fantasy/game/ui/game_hud_overlay.dart';
import 'package:match_fantasy/roguelike/models/map_node.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';

class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  late final MatchFantasyGame _game;

  @override
  void initState() {
    super.initState();
    final run = context.read<RunState>();
    final meta = context.read<MetaState>();
    _game = MatchFantasyGame(runState: run, layoutMode: meta.layoutMode);
    _game.onCombatEnd = _onCombatEnd;
  }

  @override
  void dispose() {
    _game.disposeHud();
    super.dispose();
  }

  void _onCombatEnd({
    required bool victory,
    required int hpRemaining,
    required int goldEarned,
    required int kills,
  }) {
    if (!mounted) return;
    final run = context.read<RunState>();
    final meta = context.read<MetaState>();

    // HP sync
    final diff = hpRemaining - run.health;
    if (diff > 0) run.heal(diff);
    if (diff < 0) run.takeDamage(-diff);
    run.earnGold(goldEarned);

    // Achievement tracking
    meta.incrementAchievement('total_kills', by: kills);
    if (victory) {
      final currentNode = run.map?.nodes[run.currentNodeId];
      if (currentNode?.type == NodeType.boss && run.actNumber == 1) {
        meta.incrementAchievement('act1_boss_clear');
      }
      if (hpRemaining == run.maxHealth) {
        meta.incrementAchievement('no_hp_loss_streak');
      } else {
        // Reset streak
        meta.resetAchievement('no_hp_loss_streak');
      }
    }
    meta.checkAchievements();

    if (!victory || run.isDead) {
      final int nodesCleared = run.map?.nodes.values
          .where((n) => n.isVisited).length ?? 0;
      meta.recordRunEnd(
        nodesCleared: nodesCleared,
        kills: kills,
        hpLeft: hpRemaining,
        act3Cleared: false,
      );
      run.endRun();
      context.go('/');
    } else {
      context.go('/upgrade');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<MatchFantasyGame>(
      game: _game,
      overlayBuilderMap: {
        MatchFantasyGame.hudOverlayId:
            (ctx, game) => GameHudOverlay(game: game),
      },
      initialActiveOverlays: const [MatchFantasyGame.hudOverlayId],
    );
  }
}
