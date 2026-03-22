import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:match_fantasy/game/models/asset_paths.dart';
import 'package:match_fantasy/game/models/block_type.dart';
import 'package:match_fantasy/game/models/board_move_result.dart';
import 'package:match_fantasy/game/models/combat_cue.dart';
import 'package:match_fantasy/game/models/game_difficulty.dart';
import 'package:match_fantasy/game/models/gem_tile.dart';
import 'package:match_fantasy/game/models/grid_point.dart';
import 'package:match_fantasy/game/models/hint_move.dart';
import 'package:match_fantasy/game/models/hud_state.dart';
import 'package:match_fantasy/game/models/item_type.dart';
import 'package:match_fantasy/game/models/monster_state.dart';
import 'package:match_fantasy/game/models/wave_event.dart';
import 'package:match_fantasy/game/systems/board_engine.dart';
import 'package:match_fantasy/game/systems/combat_resolver.dart';
import 'package:match_fantasy/game/systems/wave_controller.dart';
import 'package:match_fantasy/game/ui/game_palette.dart';
import 'package:match_fantasy/game/models/layout_mode.dart';
import 'package:match_fantasy/roguelike/state/run_state.dart';
import 'package:match_fantasy/roguelike/systems/class_passive_applier.dart';
import 'package:match_fantasy/roguelike/systems/relic_effect_applier.dart';

class MatchFantasyGame extends FlameGame with TapCallbacks, DragCallbacks {
  MatchFantasyGame({math.Random? random, this.runState, this.layoutMode = LayoutMode.portrait})
      : _random = random ?? math.Random() {
    resetSession();
  }

  final RunState? runState;
  final LayoutMode layoutMode;
  void Function({
    required bool victory,
    required int hpRemaining,
    required int goldEarned,
    required int kills,
  })? onCombatEnd;

  int _killCount = 0;
  int _comboCount = 0;   // 현재 스왑의 캐스케이드 콤보 수
  int _peakCombo = 0;    // 이번 스왑 최대 콤보 (HUD 표시용)
  double _shakeIntensity = 0.0;
  double _shakeTimer = 0.0;

  // When runState != null (roguelike mode), combat ends after this many waves
  static const int _combatWavesPerNode = 3;

  static const String hudOverlayId = 'hud';
  static const int meteorCost = 60;
  static const int _playerMana = 100;
  static const String _defaultStatusText =
      'Match gems to build 10-point elemental bursts.';

  final math.Random _random;
  final Map<BlockType, ui.Image> _elementIcons = <BlockType, ui.Image>{};
  final Map<MonsterKind, ui.Image> _monsterIcons = <MonsterKind, ui.Image>{};
  final ValueNotifier<HudState> hud = ValueNotifier<HudState>(
    const HudState(
      health: 30,
      maxHealth: 30,
      shield: 0,
      mana: 0,
      maxMana: _playerMana,
      score: 0,
      wave: 1,
      monstersOnField: 0,
      statusText: _defaultStatusText,
      isGameOver: false,
      isMeteorReady: false,
      elementCharges: <BlockType, int>{},
      itemCharges: <ItemType, int>{},
      timeStopRemaining: 0,
      armedItem: null,
      difficulty: GameDifficulty.normal,
      comboCount: 0,
    ),
  );

  late BoardEngine board;
  late WaveController wave;
  late SessionResources resources;
  late Map<BlockType, int> _elementCharges;
  late Map<ItemType, int> _itemCharges;

  GridPoint? _selectedCell;
  HintMove? _hintMove;
  ItemType? _armedItem;

  // Drag-to-swap state.
  GridPoint? _dragStartCell;
  Offset? _dragStartPosition;
  Offset? _dragCurrentPosition;
  final List<_BattleEffect> _battleEffects = <_BattleEffect>[];
  final List<_BoardPulse> _boardPulses = <_BoardPulse>[];
  final List<_WaveAnnouncement> _waveAnnouncements = <_WaveAnnouncement>[];
  final List<_BattlefieldAlert> _battlefieldAlerts = <_BattlefieldAlert>[];
  final List<_BoardAnimation> _boardAnimations = <_BoardAnimation>[];
  final List<_BoardSpecialEffect> _boardSpecialEffects =
      <_BoardSpecialEffect>[];
  final List<_FloatingNumber> _floatingNumbers = <_FloatingNumber>[];
  double _hintTimer = 0;
  double _timeStopRemaining = 0;
  bool _isGameOver = false;
  int _score = 0;
  String _statusText = _defaultStatusText;
  GameDifficulty _difficulty = GameDifficulty.normal;

  GameDifficulty get difficulty => _difficulty;

  bool get _isBoardAnimating => _boardAnimations.isNotEmpty;
  _BoardAnimation? get _activeBoardAnimation =>
      _boardAnimations.isEmpty ? null : _boardAnimations.first;

  void disposeHud() {
    hud.dispose();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadIconAtlases();
  }

  void resetSession() {
    final int boardSize = (runState?.hasRelic('ancient_grid_stone') ?? false) ? 7 : 6;
    board = BoardEngine(rows: boardSize, columns: boardSize, random: _random);
    wave = WaveController(
      random: _random,
      healthMultiplier: _difficulty.waveHealthMultiplier,
      speedMultiplier: _difficulty.waveSpeedMultiplier,
      spawnIntervalMultiplier: _difficulty.spawnIntervalMultiplier,
    );
    resources = SessionResources(
      maxHealth: _difficulty.maxHealth,
      maxMana: _playerMana,
    );
    _elementCharges = <BlockType, int>{
      for (final BlockType type in BlockType.values) type: 0,
    };
    _itemCharges = <ItemType, int>{
      for (final ItemType type in ItemType.values) type: _difficulty.itemStock,
    };
    _selectedCell = null;
    _hintMove = null;
    _armedItem = null;
    _dragStartCell = null;
    _dragStartPosition = null;
    _dragCurrentPosition = null;
    _battleEffects.clear();
    _boardPulses.clear();
    _waveAnnouncements.clear();
    _battlefieldAlerts.clear();
    _boardAnimations.clear();
    _boardSpecialEffects.clear();
    _floatingNumbers.clear();
    _hintTimer = 0;
    _timeStopRemaining = 0;
    _score = 0;
    _killCount = 0;
    _comboCount = 0;
    _peakCombo = 0;
    _shakeIntensity = 0.0;
    _shakeTimer = 0.0;
    _isGameOver = false;
    _statusText =
        '${_difficulty.label} - Wave ${wave.waveNumber} - ${wave.profile.label}. Build 10 points to burst.';
    _queueWaveEvents(<WaveEvent>[
      WaveEvent(
        type: WaveEventType.waveStart,
        message: 'Wave ${wave.waveNumber} - ${wave.profile.label}',
      ),
    ]);
    resumeEngine();
    if (runState != null) {
      RelicEffectApplier.applyOnCombatStart(runState!, resources);
    }
    _publishHud();
  }

  void setDifficulty(GameDifficulty difficulty) {
    if (_difficulty == difficulty) {
      return;
    }
    _difficulty = difficulty;
    resetSession();
    _statusText =
        '${difficulty.label} difficulty set. Wave ${wave.waveNumber} begins.';
    _publishHud();
  }

  Future<void> _loadIconAtlases() async {
    for (final BlockType type in BlockType.values) {
      _elementIcons[type] = await _loadUiImage(type.iconAsset);
    }
    for (final MonsterKind kind in MonsterKind.values) {
      _monsterIcons[kind] = await _loadUiImage(kind.iconAsset);
    }
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  bool castMeteor() {
    if (_isGameOver) {
      return false;
    }

    final CombatSummary summary = CombatResolver.castMeteor(
      wave: wave,
      resources: resources,
      manaCost: meteorCost,
    );
    if (summary.scoreDelta == 0) {
      _statusText = summary.statusText;
      _publishHud();
      return false;
    }

    _score += summary.scoreDelta;
    _killCount += summary.defeatedMonsters;
    _statusText = summary.statusText;
    _queueCombatCues(summary.cues);
    _boardPulses.add(
      _BoardPulse(color: GamePalette.accent, duration: 0.45, intensity: 1.1),
    );
    _triggerShake(intensity: 14.0, duration: 0.40);
    _publishHud();
    return true;
  }

  bool useItem(ItemType type) {
    if (_isGameOver) {
      return false;
    }
    if (_isBoardAnimating) {
      _statusText = 'Board is still resolving.';
      _publishHud();
      return false;
    }

    final int stock = _itemCharges[type] ?? 0;
    if (stock <= 0) {
      _statusText = '${type.label} is exhausted.';
      _publishHud();
      return false;
    }

    switch (type) {
      case ItemType.timeStone:
        _armedItem = null;
        _selectedCell = null;
        _timeStopRemaining = 4;
        _consumeItem(type);
        _statusText = 'Time Stone stopped the wave for 4 seconds.';
        _publishHud();
        return true;
      case ItemType.sageStone:
        _armedItem = null;
        _selectedCell = null;
        board.reshuffle();
        _hintMove = null;
        _hintTimer = 0;
        _consumeItem(type);
        _boardPulses.add(
          _BoardPulse(
            color: GamePalette.secondaryAccent,
            duration: 0.4,
            intensity: 1,
          ),
        );
        _statusText = 'Sage Stone reloaded the board.';
        _publishHud();
        return true;
      case ItemType.spiritDust:
        _armedItem = null;
        _selectedCell = null;
        _hintMove = board.findSuggestedMove();
        _hintTimer = 4;
        _consumeItem(type);
        _statusText = _hintMove == null
            ? 'Spirit Dust found no move.'
            : 'Spirit Dust revealed a valid swap.';
        _publishHud();
        return true;
      case ItemType.moonStone:
        if (_armedItem == ItemType.moonStone) {
          _armedItem = null;
          _statusText = 'Moon Stone canceled.';
          _publishHud();
          return true;
        }
        _armedItem = ItemType.moonStone;
        _selectedCell = null;
        _statusText = 'Moon Stone armed. Tap a gem to change its number.';
        _publishHud();
        return true;
      case ItemType.sunStone:
        if (_armedItem == ItemType.sunStone) {
          _armedItem = null;
          _statusText = 'Sun Stone canceled.';
          _publishHud();
          return true;
        }
        _armedItem = ItemType.sunStone;
        _selectedCell = null;
        _statusText = 'Sun Stone armed. Tap a gem to burst nearby blocks.';
        _publishHud();
        return true;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateVisuals(dt);

    if (_isGameOver) {
      return;
    }

    if (_shakeTimer > 0) {
      _shakeTimer = math.max(0, _shakeTimer - dt);
      if (_shakeTimer == 0) _shakeIntensity = 0;
    }

    if (_hintTimer > 0) {
      _hintTimer = math.max(0, _hintTimer - dt);
      if (_hintTimer == 0) {
        _hintMove = null;
      }
    }

    if (_timeStopRemaining > 0) {
      _timeStopRemaining = math.max(0, _timeStopRemaining - dt);
      if (_timeStopRemaining == 0) {
        _statusText = 'Time flow resumed.';
      }
      _publishHud();
      return;
    }

    final WaveTickResult tick = wave.update(dt);
    // Roguelike mode: declare victory after _combatWavesPerNode waves
    if (runState != null && wave.waveNumber > _combatWavesPerNode && !_isGameOver) {
      _triggerVictory();
      return;
    }
    if (tick.events.isNotEmpty) {
      _queueWaveEvents(tick.events);
    }
    if (tick.messages.isNotEmpty) {
      _statusText = tick.messages.join(' - ');
    }
    if (tick.breachDamage > 0) {
      resources.applyDamage(tick.breachDamage);
      final String breachText =
          'The defense line took ${tick.breachDamage} damage.';
      _statusText = tick.messages.isEmpty
          ? breachText
          : '${tick.messages.join(' - ')} - $breachText';
      if (resources.health <= 0) {
        _triggerGameOver();
        return;
      }
    }

    for (final MonsterState monster in wave.monsters) {
      if (monster.hitFlashTimer > 0) {
        monster.hitFlashTimer = math.max(0, monster.hitFlashTimer - dt);
      }
    }

    for (int i = _floatingNumbers.length - 1; i >= 0; i--) {
      _floatingNumbers[i].elapsed += dt;
      if (_floatingNumbers[i].isDone) {
        _floatingNumbers.removeAt(i);
      }
    }

    _publishHud();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isGameOver || _isBoardAnimating) {
      return;
    }
    _comboCount = 0;
    _peakCombo = 0;

    final GridPoint? tappedCell = _boardCellAt(
      Offset(event.localPosition.x, event.localPosition.y),
    );
    if (tappedCell == null) {
      return;
    }

    if (_armedItem != null) {
      _useArmedItemOn(tappedCell);
      return;
    }

    if (_selectedCell == null) {
      _selectedCell = tappedCell;
      _publishHud();
      return;
    }

    if (_selectedCell == tappedCell) {
      _selectedCell = null;
      _publishHud();
      return;
    }

    if (!_selectedCell!.isAdjacentTo(tappedCell)) {
      _selectedCell = tappedCell;
      _publishHud();
      return;
    }

    final BoardMoveResult move = board.trySwap(_selectedCell!, tappedCell);
    _selectedCell = null;

    if (!move.isValid) {
      _statusText = 'No match from that swap.';
      _publishHud();
      return;
    }

    _applyBoardResult(move, sourceLabel: 'Match');
  }

  // ── Drag-to-swap ──────────────────────────────────────────────────────────

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_isGameOver || _isBoardAnimating) {
      return;
    }
    final Offset pos = Offset(event.localPosition.x, event.localPosition.y);
    final GridPoint? cell = _boardCellAt(pos);
    if (cell == null) {
      return;
    }
    _dragStartCell = cell;
    _dragStartPosition = pos;
    _dragCurrentPosition = pos;
    if (_armedItem == null) {
      _selectedCell = cell;
      _publishHud();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragCurrentPosition != null) {
      // DragUpdateEvent provides delta, not absolute position.
      _dragCurrentPosition = Offset(
        _dragCurrentPosition!.dx + event.localDelta.x,
        _dragCurrentPosition!.dy + event.localDelta.y,
      );
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _completeDragSwap();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragStartCell = null;
    _dragStartPosition = null;
    _dragCurrentPosition = null;
  }

  void _completeDragSwap() {
    final GridPoint? startCell = _dragStartCell;
    final Offset? startPos = _dragStartPosition;
    final Offset? endPos = _dragCurrentPosition;

    _dragStartCell = null;
    _dragStartPosition = null;
    _dragCurrentPosition = null;

    if (startCell == null || startPos == null || endPos == null) {
      return;
    }
    _comboCount = 0;
    _peakCombo = 0;

    if (_armedItem != null) {
      // Armed-item taps are handled by onTapDown; ignore drag for them.
      return;
    }

    final double dx = endPos.dx - startPos.dx;
    final double dy = endPos.dy - startPos.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);

    // Require at least one-third of a cell to count as a directional drag.
    final double minDrag = _boardGeometry().cellSize * 0.33;
    if (dist < minDrag) {
      // Too small – treat as a tap: leave _selectedCell so the user can
      // complete the swap with a second tap as before.
      return;
    }

    // Determine target cell from primary drag direction.
    final GridPoint targetCell = dx.abs() > dy.abs()
        ? GridPoint(startCell.row, startCell.column + (dx > 0 ? 1 : -1))
        : GridPoint(startCell.row + (dy > 0 ? 1 : -1), startCell.column);

    _selectedCell = null;

    if (targetCell.row < 0 ||
        targetCell.row >= board.rows ||
        targetCell.column < 0 ||
        targetCell.column >= board.columns) {
      _publishHud();
      return;
    }

    final BoardMoveResult move = board.trySwap(startCell, targetCell);
    if (!move.isValid) {
      _statusText = 'No match from that swap.';
      _publishHud();
      return;
    }

    _applyBoardResult(move, sourceLabel: 'Match');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_shakeTimer > 0) {
      canvas.save();
      final double dx = (_random.nextDouble() - 0.5) * _shakeIntensity;
      final double dy = (_random.nextDouble() - 0.5) * _shakeIntensity;
      canvas.translate(dx, dy);
      _drawBackground(canvas);
      _drawBattlefield(canvas);
      _drawBoard(canvas);
      canvas.restore();
      _drawFloatingNumbers(canvas);
    } else {
      _drawBackground(canvas);
      _drawBattlefield(canvas);
      _drawBoard(canvas);
      _drawFloatingNumbers(canvas);
    }
  }

  void _applyBoardResult(BoardMoveResult move, {required String sourceLabel}) {
    // 캐스케이드 수만큼 콤보 누적
    final int cascadeSteps = move.cascadeBoards.length;
    if (cascadeSteps > 0) {
      _comboCount += cascadeSteps;
      if (_comboCount > _peakCombo) _peakCombo = _comboCount;
    }
    final CombatSummary summary = CombatResolver.resolveClear(
      move: move,
      wave: wave,
      resources: resources,
      elementCharges: _elementCharges,
      sourceLabel: sourceLabel,
      burstDamageMultiplier: _getBurstMultiplier(),
    );
    _queueBoardAnimation(move);
    _queueBoardFeedback(move);
    _queueCombatCues(summary.cues);
    if (summary.cues.any((c) => c.kind == CombatCueKind.elementBurst)) {
      final bool highCombo = _comboCount >= 3;
      _triggerShake(
        intensity: highCombo ? 8.0 : 4.0,
        duration: highCombo ? 0.25 : 0.18,
      );
    }
    for (final CombatCue cue in summary.cues) {
      if (cue.kind == CombatCueKind.elementBurst) {
        final Rect battleRect = _battlefieldRect();
        final double x = battleRect.left + _random.nextDouble() * battleRect.width;
        final double y = battleRect.center.dy;
        final bool highCombo = _comboCount >= 3;
        _floatingNumbers.add(
          _FloatingNumber(
            position: Offset(x, y),
            text: highCombo
                ? '×$_comboCount ${cue.magnitude}'
                : '${cue.magnitude}',
            color: GamePalette.block(cue.element ?? BlockType.ember),
            fontSize: highCombo ? 24 : 18,
          ),
        );
      }
    }
    _score += summary.scoreDelta;
    _killCount += summary.defeatedMonsters;
    if (runState != null && summary.defeatedMonsters > 0) {
      RelicEffectApplier.applyOnKill(runState!, resources);
    }
    _statusText = summary.statusText;
    _publishHud();
    _fireMeteorIfReady();
  }

  void _fireMeteorIfReady() {
    if (resources.mana >= meteorCost) {
      castMeteor();
    }
  }

  void _useArmedItemOn(GridPoint cell) {
    _selectedCell = null;

    switch (_armedItem) {
      case ItemType.moonStone:
        final GemTile updated = board.rerollValueAt(cell);
        _consumeItem(ItemType.moonStone);
        _armedItem = null;
        _boardPulses.add(
          _BoardPulse(
            color: GamePalette.block(BlockType.umbra),
            duration: 0.32,
            intensity: 0.9,
          ),
        );
        _statusText = 'Moon Stone changed the gem to ${updated.power}.';
        _publishHud();
        return;
      case ItemType.sunStone:
        final BoardMoveResult result = board.explodeAt(cell);
        _consumeItem(ItemType.sunStone);
        _armedItem = null;
        _applyBoardResult(result, sourceLabel: 'Sun Stone');
        return;
      case null:
      case ItemType.timeStone:
      case ItemType.sageStone:
      case ItemType.spiritDust:
        return;
    }
  }

  void _consumeItem(ItemType type) {
    _itemCharges[type] = (_itemCharges[type] ?? 0) - 1;
  }

  void _updateVisuals(double dt) {
    if (_boardAnimations.isNotEmpty) {
      _boardAnimations.first.elapsed += dt;
      if (_boardAnimations.first.elapsed >= _boardAnimations.first.duration) {
        _boardAnimations.removeAt(0);
      }
    }

    for (int index = _battleEffects.length - 1; index >= 0; index--) {
      _battleEffects[index].elapsed += dt;
      if (_battleEffects[index].elapsed >= _battleEffects[index].duration) {
        _battleEffects.removeAt(index);
      }
    }

    for (int index = _boardPulses.length - 1; index >= 0; index--) {
      _boardPulses[index].elapsed += dt;
      if (_boardPulses[index].elapsed >= _boardPulses[index].duration) {
        _boardPulses.removeAt(index);
      }
    }

    for (int index = _waveAnnouncements.length - 1; index >= 0; index--) {
      _waveAnnouncements[index].elapsed += dt;
      if (_waveAnnouncements[index].elapsed >=
          _waveAnnouncements[index].duration) {
        _waveAnnouncements.removeAt(index);
      }
    }

    for (int index = _battlefieldAlerts.length - 1; index >= 0; index--) {
      _battlefieldAlerts[index].elapsed += dt;
      if (_battlefieldAlerts[index].elapsed >=
          _battlefieldAlerts[index].duration) {
        _battlefieldAlerts.removeAt(index);
      }
    }

    for (int index = _boardSpecialEffects.length - 1; index >= 0; index--) {
      _boardSpecialEffects[index].elapsed += dt;
      if (_boardSpecialEffects[index].elapsed >=
          _boardSpecialEffects[index].duration) {
        _boardSpecialEffects.removeAt(index);
      }
    }
  }

  void _queueBoardFeedback(BoardMoveResult move) {
    for (final MapEntry<BlockType, ElementClearSummary> entry
        in move.clearedByType.entries) {
      final double intensity = (entry.value.powerTotal / 10)
          .clamp(0.35, 1.25)
          .toDouble();
      _boardPulses.add(
        _BoardPulse(
          color: GamePalette.block(entry.key),
          duration: 0.36 + (move.comboDepth * 0.05),
          intensity: intensity,
        ),
      );
    }

    for (final MatchBonus bonus in move.matchBonuses) {
      _boardPulses.add(
        _BoardPulse(
          color: GamePalette.block(bonus.element),
          duration: bonus.bonusType == MatchBonusType.nova ? 0.62 : 0.48,
          intensity: bonus.bonusType == MatchBonusType.nova ? 1.35 : 1.05,
        ),
      );
      _boardSpecialEffects.add(
        _BoardSpecialEffect(
          element: bonus.element,
          bonusType: bonus.bonusType,
          duration: bonus.bonusType == MatchBonusType.nova ? 0.88 : 0.62,
        ),
      );
    }
  }

  void _queueBoardAnimation(BoardMoveResult move) {
    _boardAnimations.addAll(_buildBoardAnimations(move));
  }

  List<_BoardAnimation> _buildBoardAnimations(BoardMoveResult move) {
    final List<_BoardAnimation> animations = <_BoardAnimation>[];

    // Phase 1: swap animation (before swap → after swap, no clears).
    if (move.initialBoard.isNotEmpty && move.beforeBoard.isNotEmpty) {
      final _BoardAnimation? swapAnimation = _buildBoardAnimationPhase(
        fromBoard: move.initialBoard,
        toBoard: move.beforeBoard,
        minimumDuration: 0.14,
        includeClears: false,
      );
      if (swapAnimation != null) {
        animations.add(swapAnimation);
      }
    }

    // Phase 2+: one animation phase per cascade step so each clear → fall →
    // refill is shown sequentially before the next combo fires.
    final List<List<List<GemTile>>> cascadeBoards = move.cascadeBoards;
    if (cascadeBoards.isNotEmpty) {
      final List<List<List<GemTile>>> steps = <List<List<GemTile>>>[
        move.beforeBoard,
        ...cascadeBoards,
      ];
      for (int i = 0; i < steps.length - 1; i++) {
        final _BoardAnimation? cascadeAnimation = _buildBoardAnimationPhase(
          fromBoard: steps[i],
          toBoard: steps[i + 1],
          minimumDuration: 0.42,
          includeClears: true,
        );
        if (cascadeAnimation != null) {
          animations.add(cascadeAnimation);
        }
      }
    } else {
      // Fallback for moves that didn't go through _resolveClears
      // (e.g. older code paths or empty cascadeBoards).
      final _BoardAnimation? resolveAnimation = _buildBoardAnimationPhase(
        fromBoard: move.beforeBoard,
        toBoard: move.afterBoard,
        minimumDuration: 0.36,
        includeClears: true,
      );
      if (resolveAnimation != null) {
        animations.add(resolveAnimation);
      }
    }

    return animations;
  }

  _BoardAnimation? _buildBoardAnimationPhase({
    required List<List<GemTile>> fromBoard,
    required List<List<GemTile>> toBoard,
    required double minimumDuration,
    required bool includeClears,
  }) {
    if (fromBoard.isEmpty || toBoard.isEmpty) {
      return null;
    }

    final Map<int, _BoardTileSnapshot> before = _snapshotTiles(fromBoard);
    final Map<int, _BoardTileSnapshot> after = _snapshotTiles(toBoard);
    if (before.isEmpty || after.isEmpty) {
      return null;
    }

    final List<_AnimatedGem> gems = <_AnimatedGem>[];
    final Set<int> beforeIds = before.keys.toSet();
    final Set<int> afterIds = after.keys.toSet();

    if (includeClears) {
      for (final int id in beforeIds.difference(afterIds)) {
        final _BoardTileSnapshot tile = before[id]!;
        gems.add(
          _AnimatedGem.clear(
            tile: tile.tile,
            fromRow: tile.row,
            fromColumn: tile.column,
            travelDuration: 0.13,
          ),
        );
      }
    }

    for (final int id in beforeIds.intersection(afterIds)) {
      final _BoardTileSnapshot start = before[id]!;
      final _BoardTileSnapshot end = after[id]!;
      if (start.cell != end.cell) {
        final double travelDistance =
            (start.row - end.row).abs() + (start.column - end.column).abs();
        // Constant-velocity movement so tiles all fall at the same speed.
        gems.add(
          _AnimatedGem.move(
            tile: end.tile,
            fromRow: start.row,
            fromColumn: start.column,
            toCell: end.cell,
            travelDuration: (travelDistance / 13.0).clamp(0.07, 0.38),
          ),
        );
      }
    }

    final List<_BoardTileSnapshot> spawns =
        afterIds
            .difference(beforeIds)
            .map((int id) => after[id]!)
            .toList(growable: false)
          // Sort descending by row so the LOWEST destination in each column
          // gets depth 0 (starts just above the board). This means the bottom
          // tile has the longest fall distance and arrives last, while the top
          // tile starts furthest above and arrives first – mimicking a column
          // of tiles stacked above the board that all drop together.
          ..sort((_BoardTileSnapshot a, _BoardTileSnapshot b) {
            final int byColumn = a.cell.column.compareTo(b.cell.column);
            return byColumn != 0
                ? byColumn
                : b.cell.row.compareTo(a.cell.row); // descending row
          });
    final Map<int, int> spawnDepthByColumn = <int, int>{};
    for (final _BoardTileSnapshot spawn in spawns) {
      final int depth = spawnDepthByColumn.update(
        spawn.cell.column,
        (int value) => value + 1,
        ifAbsent: () => 0,
      );
      // Stagger origin by exactly 1 row per depth so every tile in the
      // column travels the SAME distance (destination_row + 0.6 + depth).
      // Equal distance at equal speed → all tiles in a column arrive
      // simultaneously, like a stack of blocks dropped from above the board.
      final double spawnFromRow = -0.6 - depth.toDouble();
      final double spawnDistance = spawn.cell.row - spawnFromRow;
      // Speed = 13 rows/s. A full 7-row column: max distance ≈ 6.6 rows
      // → 0.51 s. Clamp max 0.55 stays above this so clamping never fires
      // for normal columns and accidentally changes the velocity.
      final double fallDuration = (spawnDistance / 13.0).clamp(0.10, 0.55);
      gems.add(
        _AnimatedGem.spawn(
          tile: spawn.tile,
          fromRow: spawnFromRow,
          fromColumn: spawn.column,
          toCell: spawn.cell,
          travelDuration: fallDuration,
        ),
      );
    }

    if (gems.isEmpty) {
      return null;
    }

    final double duration = math.max(
      minimumDuration,
      gems.fold<double>(
        0,
        (double longest, _AnimatedGem gem) =>
            math.max(longest, gem.travelDuration),
      ),
    );
    return _BoardAnimation(gems: gems, duration: duration, boardState: toBoard);
  }

  Map<int, _BoardTileSnapshot> _snapshotTiles(List<List<GemTile>> boardState) {
    final Map<int, _BoardTileSnapshot> snapshots = <int, _BoardTileSnapshot>{};
    for (int row = 0; row < boardState.length; row++) {
      for (int column = 0; column < boardState[row].length; column++) {
        final GemTile tile = boardState[row][column];
        snapshots[tile.id] = _BoardTileSnapshot(
          tile: tile,
          cell: GridPoint(row, column),
        );
      }
    }
    return snapshots;
  }

  void _queueCombatCues(List<CombatCue> cues) {
    for (final CombatCue cue in cues) {
      switch (cue.kind) {
        case CombatCueKind.meteor:
          _battleEffects.add(
            _BattleEffect(
              kind: _BattleEffectKind.meteor,
              color: GamePalette.accent,
              duration: 0.9,
              intensity: 1.2,
            ),
          );
          break;
        case CombatCueKind.lineBlast:
          if (cue.element == null) {
            continue;
          }
          _battleEffects.add(
            _BattleEffect(
              kind: _BattleEffectKind.lineBlast,
              color: GamePalette.block(cue.element!),
              duration: 0.62,
              intensity: ((cue.magnitude / 20).clamp(0.9, 2.1)).toDouble(),
              starBoost: cue.starBoost,
            ),
          );
          break;
        case CombatCueKind.nova:
          if (cue.element == null) {
            continue;
          }
          _battleEffects.add(
            _BattleEffect(
              kind: _BattleEffectKind.nova,
              color: GamePalette.block(cue.element!),
              duration: 0.85,
              intensity: ((cue.magnitude / 24).clamp(1.0, 2.4)).toDouble(),
              starBoost: cue.starBoost,
            ),
          );
          break;
        case CombatCueKind.elementBurst:
          if (cue.element == null) {
            continue;
          }
          _battleEffects.add(
            _BattleEffect(
              kind: _battleEffectKindFor(cue.element!),
              color: GamePalette.block(cue.element!),
              duration: 0.7 + (cue.burstCount * 0.08),
              intensity: ((cue.magnitude / 24).clamp(0.7, 2.2)).toDouble(),
              burstCount: cue.burstCount,
              starBoost: cue.starBoost,
            ),
          );
          break;
      }
    }
  }

  void _queueWaveEvents(List<WaveEvent> events) {
    for (final WaveEvent event in events) {
      final Color color = _waveEventColor(event.type);
      _waveAnnouncements.add(
        _WaveAnnouncement(
          message: event.message,
          color: color,
          duration: _waveAnnouncementDuration(event.type),
        ),
      );

      final double intensity = _waveAlertIntensity(event.type);
      if (intensity > 0) {
        _battlefieldAlerts.add(
          _BattlefieldAlert(
            type: event.type,
            color: color,
            duration: 0.7 + (intensity * 0.35),
            intensity: intensity,
          ),
        );
      }
    }

    const int maxAnnouncements = 5;
    if (_waveAnnouncements.length > maxAnnouncements) {
      _waveAnnouncements.removeRange(
        0,
        _waveAnnouncements.length - maxAnnouncements,
      );
    }

    const int maxAlerts = 6;
    if (_battlefieldAlerts.length > maxAlerts) {
      _battlefieldAlerts.removeRange(0, _battlefieldAlerts.length - maxAlerts);
    }
  }

  _BattleEffectKind _battleEffectKindFor(BlockType type) => switch (type) {
    BlockType.ember => _BattleEffectKind.ember,
    BlockType.tide => _BattleEffectKind.tide,
    BlockType.bloom => _BattleEffectKind.bloom,
    BlockType.spark => _BattleEffectKind.spark,
    BlockType.umbra => _BattleEffectKind.umbra,
  };

  Color _waveEventColor(WaveEventType type) => switch (type) {
    WaveEventType.waveStart => GamePalette.secondaryAccent,
    WaveEventType.bossArrival => GamePalette.accent,
    WaveEventType.bossShockwave => const Color(0xFFFF6B6B),
    WaveEventType.bossRally => GamePalette.block(BlockType.spark),
    WaveEventType.bossReinforce => GamePalette.block(BlockType.umbra),
  };

  double _waveAnnouncementDuration(WaveEventType type) => switch (type) {
    WaveEventType.waveStart => 1.85,
    WaveEventType.bossArrival => 2.15,
    WaveEventType.bossShockwave => 1.45,
    WaveEventType.bossRally => 1.45,
    WaveEventType.bossReinforce => 1.6,
  };

  double _waveAlertIntensity(WaveEventType type) => switch (type) {
    WaveEventType.waveStart => 0.45,
    WaveEventType.bossArrival => 0.85,
    WaveEventType.bossShockwave => 1.15,
    WaveEventType.bossRally => 0.8,
    WaveEventType.bossReinforce => 0.95,
  };

  void _drawBackground(Canvas canvas) {
    final Rect screen = Rect.fromLTWH(0, 0, size.x, size.y);
    final Paint paint = Paint()
      ..shader = ui.Gradient.linear(
        screen.topCenter,
        screen.bottomCenter,
        const <Color>[GamePalette.backgroundTop, GamePalette.backgroundBottom],
      );
    canvas.drawRect(screen, paint);

    final Paint glow = Paint()
      ..color = const Color(0x333AD6D0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 42);
    canvas.drawCircle(Offset(size.x * 0.25, size.y * 0.14), 48, glow);
    canvas.drawCircle(
      Offset(size.x * 0.78, size.y * 0.46),
      64,
      glow..color = const Color(0x22FF8C42),
    );
  }

  void _drawBattlefield(Canvas canvas) {
    final Rect battleRect = _battlefieldRect();
    final RRect battleFrame = RRect.fromRectAndRadius(
      battleRect,
      const Radius.circular(28),
    );
    final double defenseY = battleRect.bottom - 26;

    final Paint framePaint = Paint()
      ..shader = ui.Gradient.linear(
        battleRect.topCenter,
        battleRect.bottomCenter,
        const <Color>[GamePalette.battlefield, Color(0xFF0D2438)],
      );
    canvas.drawRRect(battleFrame, framePaint);
    canvas.drawRRect(
      battleFrame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = GamePalette.battlefieldEdge,
    );

    if (_timeStopRemaining > 0) {
      canvas.drawRRect(battleFrame, Paint()..color = const Color(0x333AD6D0));
    }
    _drawBattlefieldAlerts(canvas, battleRect, defenseY);

    final Paint lanePaint = Paint()
      ..color = const Color(0x33577A99)
      ..strokeWidth = 2;
    for (int lane = 1; lane < wave.laneCount; lane++) {
      final double x =
          battleRect.left + (battleRect.width * lane / wave.laneCount);
      canvas.drawLine(
        Offset(x, battleRect.top + 20),
        Offset(x, defenseY),
        lanePaint,
      );
    }

    canvas.drawLine(
      Offset(battleRect.left + 20, defenseY),
      Offset(battleRect.right - 20, defenseY),
      Paint()
        ..color = GamePalette.defenseLine
        ..strokeWidth = 4,
    );

    final String headerText = _timeStopRemaining > 0
        ? 'MONSTER WAVE - ${wave.profile.label} - TIME STOP ${_timeStopRemaining.toStringAsFixed(1)}s'
        : 'MONSTER WAVE - ${wave.profile.label}';
    _drawText(
      canvas,
      headerText,
      Offset(battleRect.left + 18, battleRect.top + 14),
      color: GamePalette.textMuted,
      fontSize: 14,
      fontWeight: FontWeight.w800,
    );

    if (wave.monsters.isEmpty) {
      _drawText(
        canvas,
        'Hold for the next spawn...',
        battleRect.center,
        centered: true,
        color: GamePalette.textMuted.withValues(alpha: 0.85),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      );
    } else {
      final List<MonsterState> renderMonsters =
          List<MonsterState>.of(wave.monsters)..sort(
            (MonsterState a, MonsterState b) =>
                a.progress.compareTo(b.progress),
          );

      for (final MonsterState monster in renderMonsters) {
        final Offset center = _monsterCenter(monster, battleRect, defenseY);
        final double scale = 42 * monster.kind.scale;
        final Rect bodyRect = Rect.fromCenter(
          center: center,
          width: scale,
          height: scale * 1.1,
        );
        final RRect body = RRect.fromRectAndRadius(
          bodyRect,
          Radius.circular(scale * 0.25),
        );

        if (monster.kind == MonsterKind.runner && monster.rushTriggered) {
          for (int index = 1; index <= 3; index++) {
            final double trailOffset = index * (scale * 0.22);
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(center.dx, center.dy - trailOffset),
                width: scale * (0.62 - (index * 0.1)),
                height: scale * (0.28 - (index * 0.03)),
              ),
              Paint()
                ..color = GamePalette.monster(
                  monster.kind,
                ).withValues(alpha: 0.2 - (index * 0.04)),
            );
          }
        }

        final Color baseColor = GamePalette.monster(monster.kind);
        final Color renderColor = monster.hitFlashTimer > 0
            ? Color.lerp(baseColor, Colors.white,
                (monster.hitFlashTimer / 0.12).clamp(0.0, 1.0))!
            : baseColor;
        final Paint bodyPaint = Paint()..color = renderColor;
        canvas.drawRRect(body, bodyPaint);
        if (monster.kind.isArmored) {
          canvas.drawRRect(
            body,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..color = const Color(0xB5F5D47A),
          );
        }
        if (monster.slowFactor < 1) {
          canvas.drawRRect(
            body,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0xFF4BD0D1),
          );
        }
        if (monster.hasteFactor > 1) {
          canvas.drawRRect(
            body,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0x66FFD166),
          );
        }

        final Rect hpBar = Rect.fromLTWH(
          bodyRect.left,
          bodyRect.top - 10,
          bodyRect.width,
          5,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(hpBar, const Radius.circular(999)),
          Paint()..color = const Color(0x66233344),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              hpBar.left,
              hpBar.top,
              hpBar.width * monster.healthRatio.clamp(0, 1),
              hpBar.height,
            ),
            const Radius.circular(999),
          ),
          Paint()..color = const Color(0xFFE5F2FF),
        );

        _drawMonsterIcon(canvas, monster.kind, bodyRect.deflate(scale * 0.14));
      }
    }

    _drawBattleEffects(canvas, battleRect, defenseY);
    _drawWaveAnnouncements(canvas, battleRect);
  }

  void _drawBattlefieldAlerts(Canvas canvas, Rect battleRect, double defenseY) {
    if (_battlefieldAlerts.isEmpty) {
      return;
    }

    final RRect overlayRect = RRect.fromRectAndRadius(
      battleRect.deflate(3),
      const Radius.circular(24),
    );
    final double laneWidth = battleRect.width / wave.laneCount;

    for (final _BattlefieldAlert alert in _battlefieldAlerts) {
      final double t = alert.progress;
      final double fade = (1 - t).clamp(0, 1).toDouble();
      final double reveal = Curves.easeOutCubic.transform(t);

      canvas.drawRRect(
        overlayRect,
        Paint()
          ..color = alert.color.withValues(
            alpha: 0.04 * fade * alert.intensity,
          ),
      );
      canvas.drawRRect(
        overlayRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + (3 * fade)
          ..color = alert.color.withValues(alpha: 0.4 * fade * alert.intensity),
      );

      switch (alert.type) {
        case WaveEventType.waveStart:
          final double scanY = ui.lerpDouble(
            battleRect.top + 24,
            defenseY - 20,
            reveal,
          )!;
          canvas.drawLine(
            Offset(battleRect.left + 18, scanY),
            Offset(battleRect.right - 18, scanY),
            Paint()
              ..color = alert.color.withValues(alpha: 0.5 * fade)
              ..strokeWidth = 4,
          );
          break;
        case WaveEventType.bossArrival:
          final Offset center = Offset(
            battleRect.center.dx,
            battleRect.top + 54,
          );
          final double radius = ui.lerpDouble(18, 82, reveal)!;
          canvas.drawCircle(
            center,
            radius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = alert.color.withValues(alpha: 0.55 * fade),
          );
          canvas.drawCircle(
            center,
            radius * 0.5,
            Paint()..color = alert.color.withValues(alpha: 0.16 * fade),
          );
          break;
        case WaveEventType.bossShockwave:
          final double waveRadius = ui.lerpDouble(
            18,
            battleRect.width * 0.46,
            reveal,
          )!;
          canvas.drawLine(
            Offset(battleRect.left + 18, defenseY),
            Offset(battleRect.right - 18, defenseY),
            Paint()
              ..color = alert.color.withValues(alpha: 0.85 * fade)
              ..strokeWidth = 6,
          );
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(battleRect.center.dx, defenseY),
              width: waveRadius * 2,
              height: waveRadius * 0.85,
            ),
            math.pi,
            math.pi,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = alert.color.withValues(alpha: 0.55 * fade),
          );
          break;
        case WaveEventType.bossRally:
          for (int lane = 0; lane < wave.laneCount; lane++) {
            final double centerX =
                battleRect.left + (laneWidth * lane) + (laneWidth / 2);
            final double topY = ui.lerpDouble(
              battleRect.top + 28,
              battleRect.top + 72,
              reveal,
            )!;
            canvas.drawLine(
              Offset(centerX - 14, defenseY - 16),
              Offset(centerX, topY),
              Paint()
                ..color = alert.color.withValues(alpha: 0.5 * fade)
                ..strokeWidth = 3,
            );
            canvas.drawLine(
              Offset(centerX + 14, defenseY - 16),
              Offset(centerX, topY),
              Paint()
                ..color = alert.color.withValues(alpha: 0.5 * fade)
                ..strokeWidth = 3,
            );
          }
          break;
        case WaveEventType.bossReinforce:
          for (int lane = 0; lane < wave.laneCount; lane++) {
            final double centerX =
                battleRect.left + (laneWidth * lane) + (laneWidth / 2);
            final double radius = ui.lerpDouble(10, 28, reveal)!;
            final Offset center = Offset(centerX, battleRect.top + 34);
            canvas.drawCircle(
              center,
              radius,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..color = alert.color.withValues(alpha: 0.55 * fade),
            );
            canvas.drawCircle(
              center,
              radius * 0.38,
              Paint()..color = alert.color.withValues(alpha: 0.18 * fade),
            );
          }
          break;
      }
    }
  }

  void _drawWaveAnnouncements(Canvas canvas, Rect battleRect) {
    if (_waveAnnouncements.isEmpty) {
      return;
    }

    final List<_WaveAnnouncement> visible = _waveAnnouncements
        .skip(math.max(0, _waveAnnouncements.length - 3))
        .toList(growable: false);

    for (int index = 0; index < visible.length; index++) {
      final _WaveAnnouncement announcement =
          visible[visible.length - index - 1];
      final double t = announcement.progress;
      double opacity = 1;
      if (t < 0.15) {
        opacity = Curves.easeOut.transform(t / 0.15);
      } else if (t > 0.82) {
        opacity = Curves.easeIn.transform((1 - t) / 0.18);
      }

      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: announcement.message,
          style: TextStyle(
            color: GamePalette.textPrimary.withValues(alpha: opacity),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.35,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: battleRect.width - 92);

      final double bannerWidth = painter.width + 28;
      final double bannerHeight = painter.height + 16;
      final double x = battleRect.center.dx - (bannerWidth / 2);
      final double y =
          battleRect.top + 20 + (index * 34) + ((1 - opacity) * 10);
      final RRect banner = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, bannerWidth, bannerHeight),
        const Radius.circular(16),
      );

      canvas.drawRRect(
        banner,
        Paint()
          ..color = const Color(0xCC07111D).withValues(alpha: 0.7 * opacity),
      );
      canvas.drawRRect(
        banner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = announcement.color.withValues(alpha: 0.65 * opacity),
      );
      painter.paint(
        canvas,
        Offset(x + 14, y + ((bannerHeight - painter.height) / 2)),
      );
    }
  }

  void _drawBoard(Canvas canvas) {
    final _BoardGeometry geometry = _boardGeometry();
    final List<List<GemTile>>? animationBoard =
        _activeBoardAnimation?.boardState;
    final RRect frame = RRect.fromRectAndRadius(
      geometry.frame,
      const Radius.circular(28),
    );

    canvas.drawRRect(
      frame,
      Paint()
        ..shader = ui.Gradient.linear(
          geometry.frame.topCenter,
          geometry.frame.bottomCenter,
          const <Color>[Color(0xCC112339), Color(0xEE0C1828)],
        ),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66324E6F),
    );

    _drawText(
      canvas,
      'ELEMENTAL BOARD',
      Offset(geometry.frame.left + 18, geometry.frame.top + 14),
      color: GamePalette.textMuted,
      fontSize: 14,
      fontWeight: FontWeight.w800,
    );
    _drawText(
      canvas,
      'Numbers add charge. Reach 10 to burst.',
      Offset(geometry.frame.right - 216, geometry.frame.top + 16),
      color: GamePalette.textMuted.withValues(alpha: 0.82),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );

    final Set<GridPoint> hiddenCells =
        _activeBoardAnimation?.hiddenCells ?? <GridPoint>{};
    for (int row = 0; row < board.rows; row++) {
      for (int column = 0; column < board.columns; column++) {
        final GridPoint cell = GridPoint(row, column);
        final Rect cellRect = Rect.fromLTWH(
          geometry.grid.left + (column * geometry.cellSize),
          geometry.grid.top + (row * geometry.cellSize),
          geometry.cellSize,
          geometry.cellSize,
        );
        final Rect inset = cellRect.deflate(geometry.cellSize * 0.07);
        final RRect tileFrame = RRect.fromRectAndRadius(
          inset,
          Radius.circular(geometry.cellSize * 0.2),
        );

        canvas.drawRRect(tileFrame, Paint()..color = GamePalette.boardTile);
        canvas.drawRRect(
          tileFrame,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = GamePalette.boardTileBorder,
        );

        if (hiddenCells.contains(cell)) {
          continue;
        }

        final GemTile tile = animationBoard == null
            ? board.tileAt(row, column)
            : animationBoard[row][column];
        final bool isSelected = _selectedCell == GridPoint(row, column);
        final bool isHinted =
            _hintMove != null && _hintTimer > 0 && _hintMove!.contains(cell);
        final bool isArmedTarget =
            _armedItem == ItemType.sunStone || _armedItem == ItemType.moonStone;
        _drawGemTile(
          canvas,
          geometry: geometry,
          tile: tile,
          cellRect: cellRect,
          tileFrame: tileFrame,
          isSelected: isSelected,
          isHinted: isHinted,
          isArmedTarget: isArmedTarget,
        );
      }
    }

    _drawBoardPulses(canvas, geometry);
    _drawBoardAnimation(canvas, geometry);
    _drawBoardSpecialEffects(canvas, geometry);
  }

  void _drawGemTile(
    Canvas canvas, {
    required _BoardGeometry geometry,
    required GemTile tile,
    required Rect cellRect,
    required RRect tileFrame,
    bool isSelected = false,
    bool isHinted = false,
    bool isArmedTarget = false,
    double alpha = 1,
    double scale = 1,
  }) {
    final Rect baseGemRect = cellRect
        .deflate(geometry.cellSize * 0.07)
        .deflate(geometry.cellSize * 0.12);
    final Rect gemRect = Rect.fromCenter(
      center: baseGemRect.center,
      width: baseGemRect.width * scale,
      height: baseGemRect.height * scale,
    );
    final RRect gemFrame = RRect.fromRectAndRadius(
      gemRect,
      Radius.circular(geometry.cellSize * 0.18 * scale),
    );

    canvas.drawRRect(
      gemFrame,
      Paint()..color = GamePalette.block(tile.type).withValues(alpha: alpha),
    );

    if (tile.isSpecial) {
      final Color frameColor = tile.special == GemSpecialKind.nova
          ? const Color(0xFFFFF1A8)
          : Colors.white;
      canvas.drawRRect(
        gemFrame,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tile.special == GemSpecialKind.nova ? 3 : 2.4
          ..color = frameColor.withValues(alpha: alpha),
      );
      canvas.drawRRect(
        gemFrame.inflate(tile.special == GemSpecialKind.nova ? 2 : 1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = GamePalette.block(tile.type).withValues(alpha: 0.7 * alpha),
      );
    }

    if (isHinted) {
      canvas.drawRRect(
        tileFrame,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF4BD0D1).withValues(alpha: alpha),
      );
    }
    if (isSelected) {
      canvas.drawRRect(
        tileFrame,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFF4F8FF).withValues(alpha: alpha),
      );
    }
    if (isArmedTarget) {
      canvas.drawRRect(
        gemFrame,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color =
              (_armedItem == ItemType.sunStone
                      ? const Color(0xFFFFD166)
                      : const Color(0xFFC77DFF))
                  .withValues(alpha: alpha),
      );
    }

    // Draw element icon as the primary tile visual – no number overlay.
    _drawElementIcon(
      canvas,
      tile.type,
      gemRect.deflate(gemRect.width * 0.06),
      alpha: alpha * 0.92,
    );

    if (tile.isStar) {
      _drawText(
        canvas,
        '*',
        Offset(gemRect.right - 12, gemRect.top + 2),
        color: const Color(0xFFFFF1A8).withValues(alpha: alpha),
        fontSize: geometry.cellSize * 0.24 * scale,
        fontWeight: FontWeight.w900,
      );
    }

    if (tile.special != null) {
      _drawText(
        canvas,
        tile.special!.marker,
        Offset(gemRect.left + 8, gemRect.bottom - 16),
        color: const Color(0xFFF7FBFF).withValues(alpha: alpha),
        fontSize: geometry.cellSize * 0.18 * scale,
        fontWeight: FontWeight.w900,
      );
    }
  }

  void _drawBoardAnimation(Canvas canvas, _BoardGeometry geometry) {
    final _BoardAnimation? animation = _activeBoardAnimation;
    if (animation == null) {
      return;
    }

    for (final _AnimatedGem gem in animation.gems) {
      final double gemProgress = gem.progressAt(animation.elapsed);
      // All movements use easeOutCubic: tiles rush in quickly then settle.
      // This matches the visual feel of pieces dropping with a soft landing.
      final double moveProgress = Curves.easeOutCubic.transform(gemProgress);
      final double clearProgress = Curves.easeIn.transform(gemProgress);
      late final double row;
      late final double column;
      late final double alpha;
      late final double scale;
      switch (gem.kind) {
        case _AnimatedGemKind.clear:
          row = gem.fromRow;
          column = gem.fromColumn;
          alpha = 1 - clearProgress;
          scale = 1 - (clearProgress * 0.25);
          break;
        case _AnimatedGemKind.move:
        case _AnimatedGemKind.spawn:
          row = ui.lerpDouble(
            gem.fromRow,
            gem.toCell!.row.toDouble(),
            moveProgress,
          )!;
          column = ui.lerpDouble(
            gem.fromColumn,
            gem.toCell!.column.toDouble(),
            moveProgress,
          )!;
          // Spawn tiles: no fade-in so they are immediately visible and
          // clearly "falling" rather than ghosting in.
          alpha = 1;
          scale = 1;
          break;
      }

      final Rect cellRect = Rect.fromLTWH(
        geometry.grid.left + (column * geometry.cellSize),
        geometry.grid.top + (row * geometry.cellSize),
        geometry.cellSize,
        geometry.cellSize,
      );
      final Rect inset = cellRect.deflate(geometry.cellSize * 0.07);
      final RRect tileFrame = RRect.fromRectAndRadius(
        inset,
        Radius.circular(geometry.cellSize * 0.2),
      );

      canvas.drawRRect(
        tileFrame,
        Paint()
          ..color = const Color(0x44000000).withValues(alpha: alpha * 0.45),
      );

      if (gem.kind == _AnimatedGemKind.clear) {
        final double burstRadius =
            (geometry.cellSize * 0.22) +
            (geometry.cellSize * 0.42 * clearProgress);
        canvas.drawCircle(
          cellRect.center,
          burstRadius,
          Paint()
            ..color = GamePalette.block(
              gem.tile.type,
            ).withValues(alpha: 0.18 * alpha),
        );
        canvas.drawCircle(
          cellRect.center,
          burstRadius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = GamePalette.block(
              gem.tile.type,
            ).withValues(alpha: 0.7 * alpha),
        );
      }

      _drawGemTile(
        canvas,
        geometry: geometry,
        tile: gem.tile,
        cellRect: cellRect,
        tileFrame: tileFrame,
        alpha: alpha,
        scale: scale,
      );
    }
  }

  void _drawBoardSpecialEffects(Canvas canvas, _BoardGeometry geometry) {
    if (_boardSpecialEffects.isEmpty) {
      return;
    }

    final List<_BoardSpecialEffect> visible = _boardSpecialEffects
        .skip(math.max(0, _boardSpecialEffects.length - 2))
        .toList(growable: false);
    for (int index = 0; index < visible.length; index++) {
      final _BoardSpecialEffect effect = visible[index];
      final double fade = (1 - effect.progress).clamp(0, 1).toDouble();
      final double reveal = Curves.easeOutCubic.transform(effect.progress);
      final double labelY = geometry.frame.top + 42 + (index * 28);
      final Rect labelRect = Rect.fromCenter(
        center: Offset(geometry.frame.center.dx, labelY),
        width: 148,
        height: 28,
      );
      final RRect label = RRect.fromRectAndRadius(
        labelRect,
        const Radius.circular(999),
      );
      canvas.drawRRect(
        label,
        Paint()..color = const Color(0xD0091827).withValues(alpha: 0.72 * fade),
      );
      canvas.drawRRect(
        label,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = GamePalette.block(
            effect.element,
          ).withValues(alpha: 0.7 * fade),
      );
      _drawElementIcon(
        canvas,
        effect.element,
        Rect.fromCenter(
          center: Offset(labelRect.left + 18, labelRect.center.dy),
          width: 16,
          height: 16,
        ),
        alpha: 0.9 * fade,
      );
      _drawText(
        canvas,
        effect.label,
        Offset(labelRect.left + 30, labelRect.top + 6),
        color: GamePalette.textPrimary.withValues(alpha: fade),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      );

      switch (effect.bonusType) {
        case MatchBonusType.lineBlast:
          final double sweepY = ui.lerpDouble(
            geometry.grid.top + geometry.cellSize,
            geometry.grid.bottom - geometry.cellSize,
            reveal,
          )!;
          canvas.drawLine(
            Offset(geometry.grid.left + 10, sweepY),
            Offset(geometry.grid.right - 10, sweepY),
            Paint()
              ..color = GamePalette.block(
                effect.element,
              ).withValues(alpha: 0.8 * fade)
              ..strokeWidth = 3.5,
          );
          break;
        case MatchBonusType.nova:
          final double radius = ui.lerpDouble(
            20,
            geometry.grid.shortestSide * 0.42,
            reveal,
          )!;
          canvas.drawCircle(
            geometry.grid.center,
            radius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = GamePalette.block(
                effect.element,
              ).withValues(alpha: 0.65 * fade),
          );
          canvas.drawCircle(
            geometry.grid.center,
            radius * 0.55,
            Paint()
              ..color = GamePalette.block(
                effect.element,
              ).withValues(alpha: 0.14 * fade),
          );
          break;
      }
    }
  }

  void _drawElementIcon(
    Canvas canvas,
    BlockType type,
    Rect rect, {
    double alpha = 1,
  }) {
    final ui.Image? icon = _elementIcons[type];
    if (icon != null) {
      canvas.drawImageRect(
        icon,
        Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()),
        rect,
        Paint()
          ..colorFilter = ui.ColorFilter.mode(
            Colors.white.withValues(alpha: alpha),
            BlendMode.modulate,
          ),
      );
      return;
    }

    _drawText(
      canvas,
      type.glyph,
      rect.center,
      centered: true,
      color: GamePalette.textPrimary.withValues(alpha: alpha),
      fontSize: rect.height * 0.5,
      fontWeight: FontWeight.w800,
    );
  }

  void _drawMonsterIcon(Canvas canvas, MonsterKind kind, Rect rect) {
    final ui.Image? icon = _monsterIcons[kind];
    if (icon != null) {
      canvas.drawImageRect(
        icon,
        Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()),
        rect,
        Paint(),
      );
      return;
    }

    _drawText(
      canvas,
      kind.glyph,
      rect.center,
      centered: true,
      color: const Color(0xFF08111D),
      fontSize: rect.height * 0.52,
      fontWeight: FontWeight.w900,
    );
  }

  void _drawBattleEffects(Canvas canvas, Rect battleRect, double defenseY) {
    if (_battleEffects.isEmpty) {
      return;
    }

    final int frontLane = _frontLaneForEffects();
    final Offset boardOrigin = Offset(
      battleRect.center.dx,
      battleRect.bottom + 28,
    );
    final Offset impactPoint = _laneImpactPoint(
      battleRect,
      defenseY,
      frontLane,
    );

    for (final _BattleEffect effect in _battleEffects) {
      final double t = effect.progress;
      final double fade = (1 - t).clamp(0, 1).toDouble();
      switch (effect.kind) {
        case _BattleEffectKind.ember:
          final Offset current = Offset.lerp(
            boardOrigin,
            impactPoint,
            Curves.easeOutCubic.transform(t),
          )!;
          canvas.drawLine(
            boardOrigin,
            current,
            Paint()
              ..color = effect.color.withValues(alpha: 0.38 * fade)
              ..strokeWidth = 6 * effect.intensity,
          );
          canvas.drawCircle(
            current,
            10 + (6 * effect.intensity),
            Paint()..color = effect.color.withValues(alpha: 0.92 * fade),
          );
          break;
        case _BattleEffectKind.tide:
          final double waveY = ui.lerpDouble(
            battleRect.top + 34,
            defenseY - 18,
            Curves.easeInOut.transform(t),
          )!;
          final Rect sweepRect = Rect.fromLTWH(
            battleRect.left + 12,
            waveY - (12 * effect.intensity),
            battleRect.width - 24,
            18 + (12 * effect.intensity),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(sweepRect, const Radius.circular(999)),
            Paint()..color = effect.color.withValues(alpha: 0.28 * fade),
          );
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(battleRect.center.dx, waveY),
              width: battleRect.width * 0.9,
              height: 52 + (18 * effect.intensity),
            ),
            math.pi,
            math.pi,
            false,
            Paint()
              ..color = effect.color.withValues(alpha: 0.82 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4,
          );
          break;
        case _BattleEffectKind.lineBlast:
          final double reveal = Curves.easeOutCubic.transform(t);
          final double strikeY = ui.lerpDouble(
            boardOrigin.dy - 14,
            impactPoint.dy,
            reveal,
          )!;
          final Rect beam = Rect.fromLTWH(
            battleRect.left + 18,
            strikeY - (7 * effect.intensity),
            battleRect.width - 36,
            14 + (10 * effect.intensity),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(beam, const Radius.circular(999)),
            Paint()..color = effect.color.withValues(alpha: 0.24 * fade),
          );
          canvas.drawLine(
            Offset(battleRect.left + 22, strikeY),
            Offset(battleRect.right - 22, strikeY),
            Paint()
              ..color = effect.color.withValues(alpha: 0.92 * fade)
              ..strokeWidth = 3 + (4 * effect.intensity),
          );
          final double cutterX = ui.lerpDouble(
            battleRect.left + 26,
            battleRect.right - 26,
            reveal,
          )!;
          canvas.drawCircle(
            Offset(cutterX, strikeY),
            8 + (5 * effect.intensity),
            Paint()..color = effect.color.withValues(alpha: 0.95 * fade),
          );
          break;
        case _BattleEffectKind.bloom:
          final Offset center = Offset(battleRect.center.dx, defenseY - 20);
          final double radius = ui.lerpDouble(
            20,
            battleRect.width * 0.3 * effect.intensity,
            Curves.easeOut.transform(t),
          )!;
          canvas.drawCircle(
            center,
            radius,
            Paint()
              ..color = effect.color.withValues(alpha: 0.24 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5,
          );
          canvas.drawCircle(
            center,
            radius * 0.45,
            Paint()..color = effect.color.withValues(alpha: 0.14 * fade),
          );
          break;
        case _BattleEffectKind.spark:
          final Path lightning = Path()..moveTo(boardOrigin.dx, boardOrigin.dy);
          const int segments = 6;
          for (int index = 1; index <= segments; index++) {
            final double ratio = index / segments;
            final double baseX = ui.lerpDouble(
              boardOrigin.dx,
              impactPoint.dx,
              ratio,
            )!;
            final double baseY = ui.lerpDouble(
              boardOrigin.dy,
              impactPoint.dy,
              ratio,
            )!;
            final double offset = index == segments
                ? 0
                : math.sin((t * 10) + index) * 14;
            lightning.lineTo(baseX + offset, baseY);
          }
          canvas.drawPath(
            lightning,
            Paint()
              ..color = effect.color.withValues(alpha: 0.9 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.2,
          );
          break;
        case _BattleEffectKind.nova:
          final Offset center = battleRect.center;
          final double radius = ui.lerpDouble(
            20,
            battleRect.width * 0.5 * effect.intensity,
            Curves.easeOutQuart.transform(t),
          )!;
          canvas.drawCircle(
            center,
            radius * 0.56,
            Paint()..color = effect.color.withValues(alpha: 0.12 * fade),
          );
          canvas.drawCircle(
            center,
            radius,
            Paint()
              ..color = effect.color.withValues(alpha: 0.7 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5,
          );
          canvas.drawCircle(
            center,
            radius * 0.65,
            Paint()
              ..color = effect.color.withValues(alpha: 0.42 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
          final double laneWidth = battleRect.width / wave.laneCount;
          for (int lane = 0; lane < wave.laneCount; lane++) {
            final double laneX =
                battleRect.left + (laneWidth * lane) + (laneWidth / 2);
            canvas.drawLine(
              center,
              Offset(laneX, defenseY - 10),
              Paint()
                ..color = effect.color.withValues(alpha: 0.34 * fade)
                ..strokeWidth = 2.5,
            );
          }
          break;
        case _BattleEffectKind.umbra:
          final Offset center = battleRect.center;
          final double radius = ui.lerpDouble(
            18,
            battleRect.width * 0.42 * effect.intensity,
            Curves.easeOutQuart.transform(t),
          )!;
          canvas.drawCircle(
            center,
            radius,
            Paint()..color = effect.color.withValues(alpha: 0.14 * fade),
          );
          canvas.drawCircle(
            center,
            radius,
            Paint()
              ..color = effect.color.withValues(alpha: 0.55 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4,
          );
          break;
        case _BattleEffectKind.meteor:
          for (int index = 0; index < 3; index++) {
            final double startX =
                battleRect.left + 36 + (index * battleRect.width * 0.27);
            final Offset start = Offset(
              startX,
              battleRect.top - 24 - (index * 18),
            );
            final Offset end = Offset(startX - 28, defenseY - 18 + (index * 8));
            final Offset current = Offset.lerp(
              start,
              end,
              Curves.easeIn.transform(t),
            )!;
            canvas.drawLine(
              Offset(current.dx + 18, current.dy - 30),
              current,
              Paint()
                ..color = effect.color.withValues(alpha: 0.85 * fade)
                ..strokeWidth = 5,
            );
            canvas.drawCircle(
              current,
              8 + (index * 2),
              Paint()..color = effect.color.withValues(alpha: 0.95 * fade),
            );
          }
          break;
      }

      if (effect.starBoost) {
        canvas.drawCircle(
          impactPoint,
          12 + (8 * (1 - t)),
          Paint()
            ..color = const Color(0xFFFFF1A8).withValues(alpha: 0.55 * fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _drawBoardPulses(Canvas canvas, _BoardGeometry geometry) {
    if (_boardPulses.isEmpty) {
      return;
    }

    for (final _BoardPulse pulse in _boardPulses) {
      final double fade = (1 - pulse.progress).clamp(0, 1).toDouble();
      final double inset = 4 + (pulse.progress * 12);
      final RRect pulseRect = RRect.fromRectAndRadius(
        geometry.frame.deflate(inset),
        const Radius.circular(26),
      );

      canvas.drawRRect(
        pulseRect,
        Paint()
          ..color = pulse.color.withValues(
            alpha: 0.08 * fade * pulse.intensity,
          ),
      );
      canvas.drawRRect(
        pulseRect,
        Paint()
          ..color = pulse.color.withValues(alpha: 0.55 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + (2 * fade),
      );

      final double shimmerY = ui.lerpDouble(
        geometry.grid.top,
        geometry.grid.bottom,
        pulse.progress,
      )!;
      canvas.drawLine(
        Offset(geometry.grid.left, shimmerY),
        Offset(geometry.grid.right, shimmerY),
        Paint()
          ..color = pulse.color.withValues(alpha: 0.28 * fade)
          ..strokeWidth = 4,
      );
    }
  }

  int _frontLaneForEffects() {
    if (wave.monsters.isEmpty) {
      return wave.laneCount ~/ 2;
    }

    MonsterState target = wave.monsters.first;
    for (final MonsterState monster in wave.monsters.skip(1)) {
      if (monster.progress > target.progress) {
        target = monster;
      }
    }
    return target.lane;
  }

  Offset _laneImpactPoint(Rect battleRect, double defenseY, int lane) {
    final double laneWidth = battleRect.width / wave.laneCount;
    return Offset(
      battleRect.left + (laneWidth * lane) + (laneWidth / 2),
      defenseY - 26,
    );
  }

  void _triggerGameOver() {
    _isGameOver = true;
    _statusText = 'The wave broke through.';
    pauseEngine();
    _publishHud();
    onCombatEnd?.call(
      victory: false,
      hpRemaining: resources.health,
      goldEarned: 0,
      kills: _killCount,
    );
  }

  void _triggerVictory() {
    _isGameOver = true;
    _statusText = 'Waves cleared!';
    pauseEngine();
    _publishHud();
    final int goldEarned = 15 + (_random.nextInt(11)); // 15-25 gold
    onCombatEnd?.call(
      victory: true,
      hpRemaining: resources.health,
      goldEarned: goldEarned,
      kills: _killCount,
    );
  }

  void _triggerShake({required double intensity, required double duration}) {
    if (intensity > _shakeIntensity) {
      _shakeIntensity = intensity;
      _shakeTimer = duration;
    }
  }

  double _getBurstMultiplier() {
    final double baseMultiplier = runState == null
        ? 1.0
        : RelicEffectApplier.burstDamageMultiplier(runState!) +
            ClassPassiveApplier.burstDamageBonus(runState!);
    return baseMultiplier + (_comboCount * 0.10);
  }

  void _publishHud() {
    hud.value = HudState(
      health: resources.health,
      maxHealth: resources.maxHealth,
      shield: resources.shield,
      mana: resources.mana,
      maxMana: resources.maxMana,
      score: _score,
      wave: wave.waveNumber,
      monstersOnField: wave.monsters.length,
      statusText: _statusText,
      isGameOver: _isGameOver,
      isMeteorReady: resources.mana >= meteorCost,
      elementCharges: Map<BlockType, int>.unmodifiable(_elementCharges),
      itemCharges: Map<ItemType, int>.unmodifiable(_itemCharges),
      timeStopRemaining: _timeStopRemaining,
      armedItem: _armedItem,
      difficulty: _difficulty,
      comboCount: _peakCombo,
    );
  }

  _BoardGeometry _buildBoardGeometry(Rect frame) {
    final double cellSize = math.min(
      frame.width / board.columns,
      (frame.height - 34) / board.rows,
    );
    final double gridWidth = cellSize * board.columns;
    final double gridHeight = cellSize * board.rows;
    final Rect grid = Rect.fromLTWH(
      frame.left + ((frame.width - gridWidth) / 2),
      frame.top + 34 + (((frame.height - 34) - gridHeight) / 2),
      gridWidth,
      gridHeight,
    );
    return _BoardGeometry(frame: frame, grid: grid, cellSize: cellSize);
  }

  Rect _battlefieldRect() {
    const double padding = 18;
    switch (layoutMode) {
      case LayoutMode.portrait:
        return Rect.fromLTRB(padding, 48, size.x - padding, size.y * 0.50);
      case LayoutMode.landscapeA:
        return Rect.fromLTRB(padding, padding, size.x * 0.50, size.y - padding);
      case LayoutMode.landscapeB:
        return Rect.fromLTRB(size.x * 0.50, padding, size.x - padding, size.y - padding);
    }
  }

  _BoardGeometry _boardGeometry() {
    switch (layoutMode) {
      case LayoutMode.portrait:
        final Rect frame = Rect.fromLTRB(18, size.y * 0.50 + 8, size.x - 18, size.y - 8);
        return _buildBoardGeometry(frame);
      case LayoutMode.landscapeA:
        final Rect frame = Rect.fromLTRB(size.x * 0.50 + 8, 18, size.x - 18, size.y - 18);
        return _buildBoardGeometry(frame);
      case LayoutMode.landscapeB:
        final Rect frame = Rect.fromLTRB(18, 18, size.x * 0.50 - 8, size.y - 18);
        return _buildBoardGeometry(frame);
    }
  }

  GridPoint? _boardCellAt(Offset position) {
    final _BoardGeometry geometry = _boardGeometry();
    if (!geometry.grid.contains(position)) {
      return null;
    }

    final int column = ((position.dx - geometry.grid.left) / geometry.cellSize)
        .floor();
    final int row = ((position.dy - geometry.grid.top) / geometry.cellSize)
        .floor();

    if (row < 0 || row >= board.rows || column < 0 || column >= board.columns) {
      return null;
    }

    return GridPoint(row, column);
  }

  Offset _monsterCenter(
    MonsterState monster,
    Rect battleRect,
    double defenseY,
  ) {
    final double laneWidth = battleRect.width / wave.laneCount;
    final double x =
        battleRect.left + (laneWidth * monster.lane) + (laneWidth / 2);
    final double y = ui.lerpDouble(
      battleRect.top + 44,
      defenseY - 24,
      monster.progress.clamp(0, 1),
    )!;
    return Offset(x, y);
  }

  void _drawFloatingNumbers(Canvas canvas) {
    for (final _FloatingNumber fn in _floatingNumbers) {
      final Color c = fn.color.withValues(alpha: fn.alpha.clamp(0.0, 1.0));
      _drawText(
        canvas,
        fn.text,
        Offset(fn.position.dx, fn.position.dy + fn.yOffset),
        color: c,
        fontSize: fn.fontSize,
        fontWeight: FontWeight.w900,
        centered: true,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset anchor, {
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    bool centered = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - 36);

    final Offset offset = centered
        ? anchor - Offset(painter.width / 2, painter.height / 2)
        : anchor;
    painter.paint(canvas, offset);
  }

  // テスト用ヘルパー
  double testBurstMultiplier() => _getBurstMultiplier();
}

class _BoardGeometry {
  const _BoardGeometry({
    required this.frame,
    required this.grid,
    required this.cellSize,
  });

  final Rect frame;
  final Rect grid;
  final double cellSize;
}

enum _BattleEffectKind {
  ember,
  tide,
  lineBlast,
  bloom,
  spark,
  nova,
  umbra,
  meteor,
}

class _BattleEffect {
  _BattleEffect({
    required this.kind,
    required this.color,
    required this.duration,
    required this.intensity,
    this.burstCount = 1,
    this.starBoost = false,
  });

  final _BattleEffectKind kind;
  final Color color;
  final double duration;
  final double intensity;
  final int burstCount;
  final bool starBoost;
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);
}

class _BoardPulse {
  _BoardPulse({
    required this.color,
    required this.duration,
    required this.intensity,
  });

  final Color color;
  final double duration;
  final double intensity;
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);
}

enum _AnimatedGemKind { move, spawn, clear }

class _AnimatedGem {
  _AnimatedGem.move({
    required this.tile,
    required this.fromRow,
    required this.fromColumn,
    required this.travelDuration,
    required GridPoint this.toCell,
  }) : kind = _AnimatedGemKind.move;

  _AnimatedGem.spawn({
    required this.tile,
    required this.fromRow,
    required this.fromColumn,
    required this.travelDuration,
    required GridPoint this.toCell,
  }) : kind = _AnimatedGemKind.spawn;

  _AnimatedGem.clear({
    required this.tile,
    required this.fromRow,
    required this.fromColumn,
    required this.travelDuration,
  }) : kind = _AnimatedGemKind.clear,
       toCell = null;

  final _AnimatedGemKind kind;
  final GemTile tile;
  final double fromRow;
  final double fromColumn;
  final double travelDuration;
  final GridPoint? toCell;

  double progressAt(double elapsed) {
    return (elapsed / travelDuration).clamp(0.0, 1.0);
  }
}

class _BoardAnimation {
  _BoardAnimation({
    required this.gems,
    required this.duration,
    required this.boardState,
  });

  final List<_AnimatedGem> gems;
  final double duration;
  final List<List<GemTile>> boardState;
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);

  Set<GridPoint> get hiddenCells {
    return gems
        .where((_AnimatedGem gem) => gem.toCell != null)
        .map((_AnimatedGem gem) => gem.toCell!)
        .toSet();
  }
}

class _BoardTileSnapshot {
  const _BoardTileSnapshot({required this.tile, required this.cell});

  final GemTile tile;
  final GridPoint cell;

  double get row => cell.row.toDouble();
  double get column => cell.column.toDouble();
}

class _BoardSpecialEffect {
  _BoardSpecialEffect({
    required this.element,
    required this.bonusType,
    required this.duration,
  });

  final BlockType element;
  final MatchBonusType bonusType;
  final double duration;
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);

  String get label => switch (bonusType) {
    MatchBonusType.lineBlast => '${element.label.toUpperCase()} LINE',
    MatchBonusType.nova => '${element.label.toUpperCase()} NOVA',
  };
}

class _WaveAnnouncement {
  _WaveAnnouncement({
    required this.message,
    required this.color,
    required this.duration,
  });

  final String message;
  final Color color;
  final double duration;
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);
}

class _BattlefieldAlert {
  _BattlefieldAlert({
    required this.type,
    required this.color,
    required this.duration,
    required this.intensity,
  });

  final WaveEventType type;
  final Color color;
  final double duration;
  final double intensity;
  double elapsed = 0;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);
}

class _FloatingNumber {
  _FloatingNumber({
    required this.position,
    required this.text,
    required this.color,
    this.fontSize = 18.0,
  });

  final Offset position;
  final String text;
  final Color color;
  final double fontSize;
  final double lifetime = 0.8;
  double elapsed = 0.0;

  bool get isDone => elapsed >= lifetime;
  double get progress => (elapsed / lifetime).clamp(0.0, 1.0);

  double get yOffset {
    final double t = 1.0 - (1.0 - progress) * (1.0 - progress);
    return -60.0 * t;
  }

  double get alpha {
    final double fadeStart = (lifetime - 0.3) / lifetime;
    if (progress < fadeStart) return 1.0;
    return 1.0 - ((progress - fadeStart) / (1.0 - fadeStart));
  }
}
