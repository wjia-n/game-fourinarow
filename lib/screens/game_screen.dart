import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine.dart';
import '../match_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/arcade_themes.dart';
import '../theme/arcade_widgets.dart';
import '../theme/themed_widgets.dart';
import 'settings_screen.dart';

/// Match screen: per-side player trays, status plaque, chrome column
/// selectors, 7×6 grid toy, score plaque. Renders the [F4Match] — the engine
/// owns ALL turn state; this screen never advances the game itself.
class GameScreen extends StatefulWidget {
  final F4Audio audio;
  final F4Settings settings;
  final int mode; // 0 = vs bot, 1 = 2 players
  final int difficulty;
  final Map<String, dynamic>? restored;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.mode,
    required this.difficulty,
    this.restored,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final F4Match match;

  // Falling-disc animation (driven by match.animCol/animRow).
  late final AnimationController _fallCtl;
  bool _fallRunning = false;

  // Invalid-column shake.
  late final AnimationController _shakeCtl;
  int _shakeCol = -1;

  F4Settings get s => widget.settings;
  F4ArcadeThemeDef get t =>
      F4ArcadeThemes.byId(s.themeId, custom: s.customTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fallCtl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: F4Match.dropDurationMs - 80),
    );
    _shakeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    match = F4Match(
      settings: s,
      audio: widget.audio,
      mode: widget.mode,
      difficulty: widget.difficulty,
      restored: widget.restored,
    );
    match.addListener(_onMatch);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    match.removeListener(_onMatch);
    match.dispose();
    _fallCtl.dispose();
    _shakeCtl.dispose();
    super.dispose();
  }

  void _onMatch() {
    if (!mounted) return;
    // Kick the falling-disc animation when a drop starts.
    if (match.animCol != -1 && !_fallRunning) {
      _fallRunning = true;
      _fallCtl.forward(from: 0).whenComplete(() {
        _fallRunning = false;
      });
    }
    // Kick the invalid-column shake.
    if (match.shakeCol != -1 && _shakeCol == -1) {
      _shakeCol = match.shakeCol;
      _shakeCtl.forward(from: 0).whenComplete(() {
        _shakeCol = -1;
        match.clearShake();
      });
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      match.setPaused(true);
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
      match.setPaused(false);
    }
  }

  Future<void> _rename(int side) async {
    final ctl = TextEditingController(text: s.playerNames[side]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.woodMid,
        title: Text('Rename player',
            style: F4Text.mono(16, color: t.ivory)),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: 14,
          style: F4Text.mono(16, color: t.ivory),
          decoration: InputDecoration(
            hintText: F4Settings.defaultNames[side],
            hintStyle: F4Text.body.copyWith(
                color: t.ivory.withValues(alpha: 0.4)),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: t.accent)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: t.accentLight, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: F4Text.mono(14, color: t.ivory.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctl.text),
            child:
                Text('Save', style: F4Text.mono(14, color: t.accentLight)),
          ),
        ],
      ),
    );
    if (result != null) {
      widget.audio.click();
      await s.setPlayerName(side, result);
    }
  }

  void _openSettings() {
    widget.audio.click();
    match.setPaused(true);
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => SettingsScreen(
                audio: widget.audio, settings: s)))
        .then((_) => match.setPaused(false));
  }

  @override
  Widget build(BuildContext context) {
    final theme = t;
    return Scaffold(
      backgroundColor: theme.woodDeep,
      body: F4WoodBackdrop(
        theme: theme,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: match,
            builder: (_, _) => Stack(
              children: [
                _body(theme),
                if (match.paused && match.phase != F4Phase.over)
                  _pauseOverlay(theme),
                if (match.phase == F4Phase.over) _gameOverOverlay(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(F4ArcadeThemeDef theme) {
    final turn = match.engine.turn;
    final inputOpen = match.phase == F4Phase.awaitingDrop &&
        !match.currentIsBot &&
        !match.paused;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Top tray — Yellow side.
          PlayerTray(
            side: 1,
            name: s.playerNames[1],
            isBot: match.isBot[1],
            active: turn == 1 && !match.engine.over,
            thinking: turn == 1 && match.phase == F4Phase.thinking,
            theme: theme,
            discStyle: s.discStyle,
            onRename: () => _rename(1),
          ),
          const SizedBox(height: 10),
          // Status plaque: banner + controls.
          IronPanel(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    match.banner,
                    key: ValueKey(match.banner),
                    style: F4Text.mono(14, color: theme.ivory),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IconStud(
                      icon: Icons.undo,
                      theme: theme,
                      enabled: widget.mode == 1 &&
                          match.phase == F4Phase.awaitingDrop &&
                          match.engine.history.isNotEmpty,
                      onTap: match.undo,
                    ),
                    const SizedBox(width: 10),
                    _IconStud(
                      icon: Icons.refresh,
                      theme: theme,
                      enabled: true,
                      onTap: () {
                        widget.audio.click();
                        match.newGame();
                      },
                    ),
                    const SizedBox(width: 10),
                    _IconStud(
                      icon: Icons.pause,
                      theme: theme,
                      enabled: true,
                      onTap: () {
                        widget.audio.click();
                        match.setPaused(true);
                      },
                    ),
                    const SizedBox(width: 10),
                    _IconStud(
                      icon: Icons.settings,
                      theme: theme,
                      enabled: true,
                      onTap: _openSettings,
                    ),
                    const SizedBox(width: 10),
                    _IconStud(
                      icon: Icons.home,
                      theme: theme,
                      enabled: true,
                      onTap: () {
                        widget.audio.click();
                        match.save();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Chrome column selectors.
          _columnSelectors(theme, inputOpen),
          const SizedBox(height: 6),
          // Board.
          _board(theme),
          const SizedBox(height: 10),
          // Bottom tray — Red side.
          PlayerTray(
            side: 0,
            name: s.playerNames[0],
            isBot: match.isBot[0],
            active: turn == 0 && !match.engine.over,
            thinking: turn == 0 && match.phase == F4Phase.thinking,
            theme: theme,
            discStyle: s.discStyle,
            onRename: () => _rename(0),
          ),
          const SizedBox(height: 10),
          _scorePlaque(theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _columnSelectors(F4ArcadeThemeDef theme, bool inputOpen) {
    final turn = match.engine.turn;
    final discColor = turn == 0 ? theme.redDisc : theme.amberDisc;
    return Row(
      children: [
        for (var c = 0; c < FourInARowEngine.cols; c++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: inputOpen ? () => match.humanDrop(c) : null,
              child: AnimatedBuilder(
                animation: _shakeCtl,
                builder: (_, _) {
                  final dx = _shakeCol == c
                      ? 8 * (1 - _shakeCtl.value) * sin(_shakeCtl.value * 12)
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Container(
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: inputOpen
                              ? [
                                  theme.accentLight,
                                  theme.accent,
                                  theme.accentDark
                                ]
                              : [
                                  theme.accentDark.withValues(alpha: 0.5),
                                  theme.accentDark.withValues(alpha: 0.35),
                                  theme.accentDark.withValues(alpha: 0.25),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.woodDeep,
                        ),
                        child: inputOpen
                            ? Icon(Icons.arrow_drop_down,
                                color: discColor, size: 26)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _board(F4ArcadeThemeDef theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cell = w / FourInARowEngine.cols;
        final boardH = cell * FourInARowEngine.rows;
        return F4BoardFrame(
          theme: theme,
          accentIndex: s.boardAccent,
          child: SizedBox(
            width: w,
            height: boardH,
            child: Stack(
              children: [
                // Grid cells (row 0 = bottom).
                for (var r = 0; r < FourInARowEngine.rows; r++)
                  for (var c = 0; c < FourInARowEngine.cols; c++)
                    Positioned(
                      left: c * cell,
                      top: (FourInARowEngine.rows - 1 - r) * cell,
                      width: cell,
                      height: cell,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => match.humanDrop(c),
                        child: Center(
                          child: _cellContent(theme, r, c, cell),
                        ),
                      ),
                    ),
                // Falling disc overlay.
                if (match.animCol != -1)
                  AnimatedBuilder(
                    animation: _fallCtl,
                    builder: (_, _) {
                      final eased =
                          Curves.easeIn.transform(_fallCtl.value.clamp(0.0, 1.0));
                      final startY = -cell * 1.2;
                      final endY =
                          (FourInARowEngine.rows - 1 - match.animRow) * cell;
                      final y = startY + (endY - startY) * eased;
                      return Positioned(
                        left: match.animCol * cell,
                        top: y,
                        width: cell,
                        height: cell,
                        child: Center(
                          child: ThemedDisc(
                            player: match.animPlayer,
                            size: cell * 0.86,
                            theme: theme,
                            style: s.discStyle,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cellContent(
      F4ArcadeThemeDef theme, int r, int c, double cell) {
    final v = match.engine.cells[r * FourInARowEngine.cols + c];
    final idx = r * FourInARowEngine.cols + c;
    if (v == -1) {
      return BoardSlot(size: cell * 0.86);
    }
    return Container(
      decoration: BoxDecoration(
        color: theme.felt.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: ThemedDisc(
          player: v,
          size: cell * 0.86,
          theme: theme,
          style: s.discStyle,
          highlight: match.engine.winCells.contains(idx),
        ),
      ),
    );
  }

  Widget _scorePlaque(F4ArcadeThemeDef theme) {
    final m = widget.mode;
    return IronPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scoreCell(theme, s.playerNames[0], '${s.wins0[m]}', theme.redDisc),
          _scoreCell(theme, 'DRAWS', '${s.draws[m]}', theme.ivory),
          _scoreCell(theme, s.playerNames[1], '${s.wins1[m]}', theme.amberDisc),
        ],
      ),
    );
  }

  Widget _scoreCell(
      F4ArcadeThemeDef theme, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: F4Text.mono(20, color: color)),
        Text(label,
            style: F4Text.mono(10, color: theme.ivory.withValues(alpha: 0.6)),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _pauseOverlay(F4ArcadeThemeDef theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: IronPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PAUSED', style: F4Text.headline(28, color: theme.ivory)),
              const SizedBox(height: 18),
              ArcadeButton(
                label: 'RESUME',
                width: 220,
                height: 56,
                fontSize: 15,
                onPressed: () {
                  widget.audio.click();
                  match.setPaused(false);
                },
              ),
              const SizedBox(height: 10),
              ArcadeButton(
                label: 'QUIT TO MENU',
                width: 220,
                height: 56,
                fontSize: 15,
                onPressed: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameOverOverlay(F4ArcadeThemeDef theme) {
    final eng = match.engine;
    final isDraw = eng.winner < 0;
    final winnerName = isDraw ? null : match.sideName(eng.winner);
    return Stack(
      children: [
        // Paper confetti rains over the whole overlay.
        const Positioned.fill(child: Confetti(active: true)),
        Container(
          color: Colors.black.withValues(alpha: 0.55),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChromePlaque(
                    text: isDraw ? "IT'S A DRAW" : '$winnerName WINS',
                    fontSize: 26,
                    accent: theme.accentDark,
                  ),
                  const SizedBox(height: 14),
                  if (!isDraw) ...[
                    const Trophy(size: 110),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    match.banner,
                    style: F4Text.body.copyWith(
                        color: theme.ivory.withValues(alpha: 0.85)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  ArcadeButton(
                    label: 'REMATCH',
                    icon: Icons.refresh,
                    width: 240,
                    onPressed: () {
                      widget.audio.click();
                      match.newGame();
                    },
                  ),
                  const SizedBox(height: 10),
                  ArcadeButton(
                    label: 'MAIN MENU',
                    icon: Icons.home,
                    width: 240,
                    onPressed: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 16),
                  _scorePlaque(theme),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconStud extends StatelessWidget {
  final IconData icon;
  final F4ArcadeThemeDef theme;
  final bool enabled;
  final VoidCallback onTap;
  const _IconStud({
    required this.icon,
    required this.theme,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.accentLight, theme.accent, theme.accentDark],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.woodDeep,
            ),
            child: Icon(icon, color: theme.accentLight, size: 20),
          ),
        ),
      ),
    );
  }
}
