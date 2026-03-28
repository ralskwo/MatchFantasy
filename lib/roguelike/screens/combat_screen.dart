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
  bool _isPaused = false;

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _game.pauseForOverlay();
      } else {
        _game.resumeForOverlay();
      }
    });
  }

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
    required int maxComboReached,
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
      run.recordCombatResult(kills: kills, maxComboReached: maxComboReached);
      final int nodesCleared = run.map?.nodes.values
          .where((n) => n.isVisited).length ?? 0;
      meta.recordRunEnd(
        nodesCleared: nodesCleared,
        kills: run.totalKills,
        hpLeft: hpRemaining,
        act3Cleared: false,
      );
      context.go('/run_end');
    } else {
      final currentNode = run.map?.nodes[run.currentNodeId];
      if (currentNode?.type == NodeType.boss) {
        run.advanceAct();
        context.go('/map');
      } else {
        context.go('/reward');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget<MatchFantasyGame>(
          game: _game,
          overlayBuilderMap: {
            MatchFantasyGame.hudOverlayId: (ctx, game) => IgnorePointer(
              ignoring: _isPaused,
              child: GameHudOverlay(
                game: game,
                onPause: _togglePause,
              ),
            ),
          },
          initialActiveOverlays: const [MatchFantasyGame.hudOverlayId],
        ),
        if (_isPaused) _PauseOverlay(onResume: _togglePause),
      ],
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume});
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('일시정지',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onResume,
                  child: const Text('전투 재개'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
