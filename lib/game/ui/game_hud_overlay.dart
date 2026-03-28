import 'package:flutter/material.dart';
import 'package:match_fantasy/game/match_fantasy_game.dart';
import 'package:match_fantasy/game/models/asset_paths.dart';
import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/game_difficulty.dart';
import 'package:match_fantasy/game/models/hud_state.dart';
import 'package:match_fantasy/game/models/item_type.dart';
import 'package:match_fantasy/game/models/layout_mode.dart';
import 'package:match_fantasy/game/ui/game_palette.dart';
import 'package:match_fantasy/roguelike/data/cards_data.dart';
import 'package:match_fantasy/roguelike/state/meta_state.dart';
import 'package:provider/provider.dart';

Color _comboColor(int count) {
  if (count >= 5) return Colors.amber;
  if (count >= 3) return const Color(0xFFFF6B35);
  return const Color(0xFF4BD0D1);
}

class GameHudOverlay extends StatelessWidget {
  const GameHudOverlay({required this.game, this.onPause, super.key});

  final MatchFantasyGame game;
  final VoidCallback? onPause;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HudState>(
      valueListenable: game.hud,
      builder: (BuildContext context, HudState hud, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xCC102035),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x663A5777)),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    _StatChip(
                                      label: 'HP',
                                      value: '${hud.health}/${hud.maxHealth}',
                                      color: const Color(0xFFFF6B6B),
                                    ),
                                    _StatChip(
                                      label: 'Shield',
                                      value: '${hud.shield}',
                                      color: const Color(0xFF7FDBFF),
                                    ),
                                    _StatChip(
                                      label: 'Mana',
                                      value: '${hud.mana}/${hud.maxMana}',
                                      color: GamePalette.secondaryAccent,
                                    ),
                                    _StatChip(
                                      label: 'Wave',
                                      value: '${hud.wave}',
                                      color: GamePalette.accent,
                                    ),
                                    _StatChip(
                                      label: 'Score',
                                      value: '${hud.score}',
                                      color: const Color(0xFFFFD166),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                onPressed: hud.isGameOver
                                    ? null
                                    : game.castMeteor,
                                style: FilledButton.styleFrom(
                                  backgroundColor: hud.isMeteorReady
                                      ? GamePalette.accent
                                      : const Color(0xFF40546B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Text(
                                      'Meteor',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${MatchFantasyGame.meteorCost} mana',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hud.statusText,
                            style: const TextStyle(
                              color: GamePalette.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (hud.comboCount >= 2) ...<Widget>[
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _comboColor(
                                  hud.comboCount,
                                ).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                hud.comboCount >= 5
                                    ? '★ COMBO ×${hud.comboCount} ★'
                                    : 'COMBO ×${hud.comboCount}',
                                style: TextStyle(
                                  fontSize: hud.comboCount >= 3 ? 20 : 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: GameDifficulty.values
                                      .map(
                                        (GameDifficulty difficulty) =>
                                            _DifficultyButton(
                                              difficulty: difficulty,
                                              isSelected:
                                                  hud.difficulty == difficulty,
                                              onPressed: () =>
                                                  game.setDifficulty(
                                                    difficulty,
                                                  ),
                                            ),
                                      )
                                      .toList(growable: false),
                                ),
                              ),
                              Consumer<MetaState>(
                                builder: (ctx, meta, _) =>
                                    PopupMenuButton<LayoutMode>(
                                      icon: const Icon(
                                        Icons.screen_rotation,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      tooltip: '레이아웃',
                                      onSelected: (mode) {
                                        meta.setLayoutMode(mode);
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text('다음 전투부터 적용됩니다'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      itemBuilder: (ctx) => const <PopupMenuItem<LayoutMode>>[
                                        PopupMenuItem(
                                          value: LayoutMode.portrait,
                                          child: Text('세로 모드'),
                                        ),
                                        PopupMenuItem(
                                          value: LayoutMode.landscapeA,
                                          child: Text('가로 (몹→왼쪽)'),
                                        ),
                                        PopupMenuItem(
                                          value: LayoutMode.landscapeB,
                                          child: Text('가로 (몹→오른쪽)'),
                                        ),
                                      ],
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.pause, color: Colors.white70, size: 20),
                                tooltip: '일시정지',
                                onPressed: hud.isGameOver ? null : onPause,
                              ),
                            ],
                          ),
                          if (hud.armedItem != null) ...<Widget>[
                            const SizedBox(height: 8),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xAA091827),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: GamePalette.accent.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                child: Text(
                                  '${hud.armedItem!.label}: ${hud.armedItem!.helperText}',
                                  style: const TextStyle(
                                    color: GamePalette.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: BlockType.values
                                .map((BlockType type) {
                                  final int charge =
                                      hud.elementCharges[type] ?? 0;
                                  return _ChargeChip(
                                    type: type,
                                    charge: charge,
                                  );
                                })
                                .toList(growable: false),
                          ),
                          if (hud.timeStopRemaining > 0) ...<Widget>[
                            const SizedBox(height: 10),
                            Text(
                              'Time Stop ${hud.timeStopRemaining.toStringAsFixed(1)}s',
                              style: const TextStyle(
                                color: GamePalette.secondaryAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (!hud.isGameOver)
                  Positioned(
                    top: 168,
                    right: 0,
                    child: SizedBox(
                      width: 122,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: ItemType.values
                            .map(
                              (ItemType type) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ItemButton(
                                  type: type,
                                  stock: hud.itemCharges[type] ?? 0,
                                  isArmed: hud.armedItem == type,
                                  onPressed: () => game.useItem(type),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                if (!hud.isGameOver && hud.activeCardIds.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    child: SizedBox(
                      width: 118,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: hud.activeCardIds.map((String cardId) {
                          final card = cardById(cardId);
                          final int uses = hud.activeCardUses[cardId] ?? 0;
                          final int progress =
                              hud.activeCardChargeProgress[cardId] ?? 0;
                          final int threshold =
                              hud.activeCardRechargeThresholds[cardId] ?? 15;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ActiveCardButton(
                              name: card.name,
                              uses: uses,
                              chargeProgress: progress,
                              rechargeThreshold: threshold,
                              onPressed: uses > 0
                                  ? () => game.useActiveCard(cardId)
                                  : null,
                            ),
                          );
                        }).toList(growable: false),
                      ),
                    ),
                  ),
                if (hud.isGameOver)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xE6102035),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0x885D7FA3)),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x99000000),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                'Defense Down',
                                style: TextStyle(
                                  color: GamePalette.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Final score ${hud.score} - reached wave ${hud.wave}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: GamePalette.textMuted,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: game.resetSession,
                                style: FilledButton.styleFrom(
                                  backgroundColor: GamePalette.accent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Restart Run',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC0B1828),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: GamePalette.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargeChip extends StatefulWidget {
  const _ChargeChip({required this.type, required this.charge});

  final BlockType type;
  final int charge;

  @override
  State<_ChargeChip> createState() => _ChargeChipState();
}

class _ChargeChipState extends State<_ChargeChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.charge >= 10) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_ChargeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.charge >= 10 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.charge < 10 && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = widget.charge >= 10;
    final Color elementColor = GamePalette.block(widget.type);
    final Color barColor = ready ? Colors.amber : elementColor;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        final double borderAlpha = ready ? _pulseAnim.value * 0.9 : 0.4;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xAA091827),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: barColor.withValues(alpha: borderAlpha),
              width: ready ? 1.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Image.asset(widget.type.iconAsset, width: 20, height: 20),
                const SizedBox(height: 4),
                SizedBox(
                  width: 30,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (widget.charge / 10.0).clamp(0.0, 1.0),
                      backgroundColor: Colors.white12,
                      color: barColor,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.charge}',
                  style: TextStyle(
                    color: ready
                        ? Colors.amber
                        : elementColor.withValues(alpha: 0.85),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({
    required this.difficulty,
    required this.isSelected,
    required this.onPressed,
  });

  final GameDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? GamePalette.accent.withValues(alpha: 0.18)
            : const Color(0x66091827),
        foregroundColor: isSelected ? Colors.white : GamePalette.textMuted,
        side: BorderSide(
          color: isSelected ? GamePalette.accent : const Color(0x66486582),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            difficulty.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            difficulty.helperText,
            style: const TextStyle(fontSize: 10, height: 1.15),
          ),
        ],
      ),
    );
  }
}

class _ItemButton extends StatelessWidget {
  const _ItemButton({
    required this.type,
    required this.stock,
    required this.isArmed,
    required this.onPressed,
  });

  final ItemType type;
  final int stock;
  final bool isArmed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: stock > 0 ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: isArmed
            ? GamePalette.accent
            : stock > 0
            ? const Color(0xCC102035)
            : const Color(0x6640546B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            type.shortLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            type.helperText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: GamePalette.textMuted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'x$stock',
            style: const TextStyle(fontSize: 12, color: GamePalette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ActiveCardButton extends StatelessWidget {
  const _ActiveCardButton({
    required this.name,
    required this.uses,
    required this.chargeProgress,
    required this.rechargeThreshold,
    required this.onPressed,
  });

  final String name;
  final int uses;
  final int chargeProgress;
  final int rechargeThreshold;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool ready = uses > 0;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ready
            ? const Color(0xCC1A2E45)
            : const Color(0x6640546B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: ready
                ? GamePalette.accent.withValues(alpha: 0.6)
                : const Color(0x33486582),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: rechargeThreshold > 0
                        ? chargeProgress / rechargeThreshold
                        : 0.0,
                    minHeight: 3,
                    backgroundColor: const Color(0x33FFFFFF),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ready ? Colors.amber : GamePalette.secondaryAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'x$uses',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: GamePalette.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
