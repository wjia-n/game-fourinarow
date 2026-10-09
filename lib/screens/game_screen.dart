import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai.dart';
import '../audio.dart';
import '../engine.dart';
import '../settings.dart';
import '../theme.dart';

/// Game board screen: status plaque, chrome column selectors, 7x6 grid toy,
/// score plaque. Owns the engine, bot turns, animations and persistence.
class GameScreen extends StatefulWidget {
  final int mode; // 0 = vs bot, 1 = 2 players
  final int difficulty;
  final Map<String, dynamic>? restored;
  final VoidCallback onExitToMenu;
  final VoidCallback onOpenSettings;

  const GameScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    this.restored,
    required this.onExitToMenu,
    required this.onOpenSettings,
  });

  static const saveKey = 'fir_save_v1';

  static Future<void> clearSave() async {
    (await SharedPreferences.getInstance()).remove(saveKey);
  }

  static Future<Map<String, dynamic>?> loadSave() async {
    final raw = (await SharedPreferences.getInstance()).getString(saveKey);
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final eng = FourInARowEngine()..fromJson(m['engine'] as Map<String, dynamic>);
      if (eng.over || eng.history.isEmpty) return null;
      return m;
    } catch (_) {
      return null;
    }
  }

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final engine = FourInARowEngine();
  final s = F4Settings.instance;
  final audio = F4Audio.instance;

  bool _botThinking = false;
  bool _paused = false;
  bool _showGameOver = false;
  int? _pendingBotCol; // bot finished while paused

  // drop animation
  late final AnimationController _dropCtl;
  int _animCol = -1, _animRow = -1, _animPlayer = -1;
  bool get _animating => _animCol != -1;

  // invalid-column shake
  int _shakeCol = -1;
  late final AnimationController _shakeCtl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.restored != null) {
      engine.fromJson(widget.restored!['engine'] as Map<String, dynamic>);
    }
    _dropCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addStatusListener((st) {
        if (st == AnimationStatus.completed) _onDropLanded();
      });
    _shakeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addStatusListener((st) {
        if (st == AnimationStatus.completed) {
          setState(() => _shakeCol = -1);
        }
      });
    audio.playMusic('audio/music_game.wav');
    _persist();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBot());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dropCtl.dispose();
    _shakeCtl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _persist();
    }
  }

  // -- persistence -----------------------------------------------------------
  Future<void> _persist() async {
    if (engine.over) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(
      GameScreen.saveKey,
      jsonEncode({
        'mode': widget.mode,
        'difficulty': widget.difficulty,
        'engine': engine.toJson(),
      }),
    );
  }

  // -- moves -----------------------------------------------------------------
  bool get _inputLocked =>
      _animating || _botThinking || _paused || _showGameOver || engine.over;

  bool get _isBotTurn =>
      widget.mode == 0 && engine.turn == 1 && !engine.over;

  void _tapColumn(int c) {
    if (_inputLocked || _isBotTurn) return;
    final r = engine.dropRow(c);
    if (r == -1) {
      // illegal: full column — rejected, turn stays (RULES.md §5, §12)
      audio.invalid();
      setState(() => _shakeCol = c);
      _shakeCtl.forward(from: 0);
      return;
    }
    _commitMove(c, r);
  }

  void _commitMove(int c, int r) {
    final mover = engine.turn;
    engine.play(c); // always legal here
    setState(() {
      _animCol = c;
      _animRow = r;
      _animPlayer = mover;
    });
    _dropCtl.forward(from: 0);
    // wooden tok as the disc lands
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_animating && mounted) audio.drop();
    });
  }

  void _onDropLanded() {
    setState(() {
      _animCol = -1;
      _animRow = -1;
      _animPlayer = -1;
    });
    if (engine.over) {
      _onGameOver();
    } else {
      _persist();
      _maybeBot();
    }
  }

  void _maybeBot() {
    if (!_isBotTurn || _inputLocked) return;
    setState(() => _botThinking = true);
    // small beat so the "thinking" hardware feels alive
    Future.delayed(const Duration(milliseconds: 450), () async {
      if (!mounted || engine.over) {
        if (mounted) setState(() => _botThinking = false);
        return;
      }
      final col = await Bot.choose(
        engine.cells,
        engine.turn,
        widget.difficulty,
      );
      if (!mounted) return;
      setState(() => _botThinking = false);
      if (engine.over) return;
      if (_paused) {
        _pendingBotCol = col; // hold until resume
        return;
      }
      _applyBotMove(col);
    });
  }

  void _applyBotMove(int col) {
    if (col < 0 || engine.dropRow(col) == -1) {
      // defensive: bot never plays illegal columns; fall back gracefully
      final legal = engine.legalMoves();
      if (legal.isEmpty) return;
      col = legal.first;
    }
    _commitMove(col, engine.dropRow(col));
  }

  Future<void> _onGameOver() async {
    await GameScreen.clearSave();
    final mode = widget.mode;
    if (engine.isDraw) {
      await s.recordResult(mode, -1);
      audio.start();
    } else if (engine.winner == 0) {
      await s.recordResult(mode, 0);
      audio.win();
    } else {
      await s.recordResult(mode, 1);
      audio.lose();
    }
    await Future.delayed(const Duration(milliseconds: 750));
    if (mounted) setState(() => _showGameOver = true);
  }

  // -- controls --------------------------------------------------------------
  void _restart() {
    audio.start();
    engine.reset();
    setState(() {
      _showGameOver = false;
      _paused = false;
      _pendingBotCol = null;
      _botThinking = false;
    });
    _persist();
    _maybeBot();
  }

  void _undo() {
    // 2-players only: remove the last two plies (RULES.md §12).
    if (widget.mode != 1 || engine.over || _inputLocked) return;
    if (engine.history.length < 2) return;
    audio.click();
    engine.undoPly();
    engine.undoPly();
    setState(() {});
    _persist();
  }

  void _togglePause() {
    if (engine.over || _showGameOver) return;
    audio.click();
    setState(() => _paused = !_paused);
    if (!_paused && _pendingBotCol != null) {
      final c = _pendingBotCol!;
      _pendingBotCol = null;
      _applyBotMove(c);
    } else if (!_paused) {
      _maybeBot();
    }
  }

  // -- build -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              _statusPlaque(),
              const SizedBox(height: 10),
              Expanded(child: _boardPanel()),
              const SizedBox(height: 10),
              _scorePlaque(),
              const SizedBox(height: 8),
            ],
          ),
          if (_paused) _pauseOverlay(),
          if (_showGameOver) _gameOverOverlay(),
        ],
      ),
    );
  }

  Widget _statusPlaque() {
    final turnLabel = _isBotTurn && _botThinking
        ? 'BOT THINKING'
        : widget.mode == 0
            ? (engine.turn == 0 ? 'YOUR TURN' : 'BOT TURN')
            : (engine.turn == 0 ? 'RED TO MOVE' : 'YELLOW TO MOVE');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: IronPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            AcrylicDisc(player: engine.turn, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: _isBotTurn && _botThinking
                  ? const _ThinkingDots()
                  : Text(turnLabel, style: F4Text.mono(15, color: F4Colors.amber)),
            ),
            _PlaqueStud(
              icon: Icons.undo,
              enabled: widget.mode == 1 && !_inputLocked && engine.history.length >= 2,
              onTap: _undo,
            ),
            const SizedBox(width: 8),
            _PlaqueStud(icon: Icons.refresh, enabled: !_showGameOver, onTap: _restart),
            const SizedBox(width: 8),
            _PlaqueStud(
              icon: _paused ? Icons.play_arrow : Icons.pause,
              enabled: true,
              onTap: _togglePause,
            ),
            const SizedBox(width: 8),
            _PlaqueStud(
              icon: Icons.settings,
              enabled: true,
              onTap: () {
                audio.click();
                widget.onOpenSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _boardPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IronPanel(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          children: [
            _selectorRow(),
            const SizedBox(height: 8),
            Expanded(child: _grid()),
          ],
        ),
      ),
    );
  }

  Widget _selectorRow() {
    return Row(
      children: [
        for (var c = 0; c < 7; c++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _ColumnButton(
                number: c + 1,
                shaking: _shakeCol == c,
                shakeCtl: _shakeCtl,
                enabled: !_inputLocked && !_isBotTurn && engine.dropRow(c) != -1,
                onTap: () => _tapColumn(c),
              ),
            ),
          ),
      ],
    );
  }

  Widget _grid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cellW = w / 7;
        final cellH = h / 6;
        final disc = min(cellW, cellH) * 0.88;
        return Stack(
          children: [
            Column(
              children: [
                for (var r = 5; r >= 0; r--)
                  Expanded(
                    child: Row(
                      children: [
                        for (var c = 0; c < 7; c++)
                          Expanded(child: Center(child: _cell(r, c, disc))),
                      ],
                    ),
                  ),
              ],
            ),
            // falling disc overlay
            if (_animating)
              AnimatedBuilder(
                animation: _dropCtl,
                builder: (context, _) {
                  final targetY = (5 - _animRow) * cellH + (cellH - disc) / 2;
                  const startY = -80.0;
                  final y = startY + (targetY - startY) * Curves.bounceOut.transform(_dropCtl.value);
                  return Positioned(
                    left: _animCol * cellW + (cellW - disc) / 2,
                    top: y,
                    child: AcrylicDisc(player: _animPlayer, size: disc),
                  );
                },
              ),
            // winning line rail
            if (engine.over && engine.winCells.isNotEmpty)
              CustomPaint(
                painter: _WinLinePainter(
                  cells: engine.winCells,
                  cellW: cellW,
                  cellH: cellH,
                ),
                child: const SizedBox.expand(),
              ),
          ],
        );
      },
    );
  }

  Widget _cell(int r, int c, double disc) {
    final owner = engine.cells[r * 7 + c];
    final hidden = _animating && r == _animRow && c == _animCol;
    if (owner == -1 || hidden) return BoardSlot(size: disc);
    return AcrylicDisc(
      player: owner,
      size: disc,
      highlight: engine.winCells.contains(r * 7 + c),
    );
  }

  Widget _scorePlaque() {
    final m = widget.mode;
    final left = m == 0 ? 'YOU' : 'RED';
    final right = m == 0 ? 'BOT' : 'YEL';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IronPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$left ${s.redWins[m]}', style: F4Text.mono(14, color: F4Colors.red)),
            Text('  ·  ', style: F4Text.mono(14)),
            Text('$right ${s.yellowWins[m]}', style: F4Text.mono(14, color: F4Colors.amber)),
            Text('  ·  ', style: F4Text.mono(14)),
            Text('DRAW ${s.draws[m]}', style: F4Text.mono(14)),
            if (m == 0) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: F4Colors.cream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: F4Colors.chromeDark),
                ),
                child: Text(Bot.names[widget.difficulty], style: F4Text.monoDeboss(12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -- overlays ---------------------------------------------------------------
  Widget _pauseOverlay() {
    return _OverlayCard(
      title: 'PAUSED',
      children: [
        ArcadeButton(
          label: 'RESUME',
          icon: Icons.play_arrow,
          onPressed: _togglePause,
        ),
        const SizedBox(height: 12),
        ArcadeButton(label: 'RESTART', icon: Icons.refresh, onPressed: _restart),
        const SizedBox(height: 12),
        ArcadeButton(
          label: 'QUIT TO MENU',
          icon: Icons.home_outlined,
          onPressed: () {
            audio.click();
            widget.onExitToMenu();
          },
        ),
      ],
    );
  }

  Widget _gameOverOverlay() {
    final draw = engine.isDraw;
    final winner = engine.winner;
    final title = draw
        ? 'DRAW'
        : winner == 0
            ? (widget.mode == 0 ? 'YOU WIN' : 'RED WINS')
            : (widget.mode == 0 ? 'BOT WINS' : 'YELLOW WINS');
    final accent = draw ? F4Colors.cream : F4Colors.discBase(winner);
    return Stack(
      children: [
        Confetti(active: !draw),
        _OverlayCard(
          title: title,
          accent: accent,
          children: [
            if (!draw) ...[
              const Trophy(size: 110),
              const SizedBox(height: 8),
            ],
            Text(
              draw
                  ? 'Board\'s full — nobody blinked.'
                  : widget.mode == 0 && winner == 1
                      ? 'The bot takes this one. Run it back?'
                      : 'Four in a row. Zero mercy.',
              textAlign: TextAlign.center,
              style: F4Text.body,
            ),
            const SizedBox(height: 16),
            ArcadeButton(
              label: 'REMATCH',
              icon: Icons.refresh,
              onPressed: _restart,
            ),
            const SizedBox(height: 12),
            ArcadeButton(
              label: 'CHANGE MODE',
              icon: Icons.swap_horiz,
              onPressed: () {
                audio.click();
                widget.onExitToMenu();
              },
            ),
            const SizedBox(height: 12),
            ArcadeButton(
              label: 'MAIN MENU',
              icon: Icons.home_outlined,
              onPressed: () {
                audio.click();
                widget.onExitToMenu();
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Small chrome stud for the status plaque.
class _PlaqueStud extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PlaqueStud({required this.icon, required this.enabled, required this.onTap});

  @override
  State<_PlaqueStud> createState() => _PlaqueStudState();
}

class _PlaqueStudState extends State<_PlaqueStud> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        if (widget.enabled) widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: 44,
        height: 44,
        margin: EdgeInsets.only(top: _down ? 2 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.enabled
                ? const [F4Colors.chromeLight, F4Colors.chrome, F4Colors.chromeDark]
                : const [Color(0xFF4A4D52), Color(0xFF3A3D41), Color(0xFF2A2D30)],
          ),
          border: Border.all(color: const Color(0xFF3A3D41), width: 1.5),
          boxShadow: _down || !widget.enabled
              ? const []
              : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 5, offset: const Offset(0, 2)),
                ],
        ),
        child: Icon(
          widget.icon,
          color: widget.enabled ? F4Colors.deboss : const Color(0xFF222222),
          size: 22,
        ),
      ),
    );
  }
}

/// Chrome column-selector button with press + shake feedback.
class _ColumnButton extends StatefulWidget {
  final int number;
  final bool enabled;
  final bool shaking;
  final AnimationController shakeCtl;
  final VoidCallback onTap;
  const _ColumnButton({
    required this.number,
    required this.enabled,
    required this.shaking,
    required this.shakeCtl,
    required this.onTap,
  });

  @override
  State<_ColumnButton> createState() => _ColumnButtonState();
}

class _ColumnButtonState extends State<_ColumnButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final anim = widget.shaking
        ? TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
            TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
            TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
          ]).animate(widget.shakeCtl)
        : null;
    final btn = GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        if (widget.enabled) widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: 46,
        margin: EdgeInsets.only(top: _down ? 3 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.enabled
                ? const [F4Colors.chromeLight, F4Colors.chrome, F4Colors.chromeDark]
                : const [Color(0xFF4A4D52), Color(0xFF35383C), Color(0xFF26282B)],
          ),
          border: Border.all(color: const Color(0xFF3A3D41), width: 1.5),
          boxShadow: _down || !widget.enabled
              ? const []
              : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 5, offset: const Offset(0, 3)),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          '${widget.number}',
          style: F4Text.mono(
            17,
            color: widget.enabled ? F4Colors.deboss : const Color(0xFF1B1B1B),
          ),
        ),
      ),
    );
    if (anim == null) return btn;
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Transform.translate(
        offset: Offset(anim.value, 0),
        child: btn,
      ),
    );
  }
}

/// Animated "thinking" dots for the bot turn.
class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) => Row(
        children: [
          Text('BOT THINKING', style: F4Text.mono(15, color: F4Colors.amber)),
          const SizedBox(width: 6),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Opacity(
                opacity: ((_ctl.value * 3 - i * 0.5).clamp(0.0, 1.0) * 0.8 + 0.2),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: F4Colors.amber,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Brass pointer rail drawn through the winning cells.
class _WinLinePainter extends CustomPainter {
  final Set<int> cells;
  final double cellW, cellH;
  _WinLinePainter({required this.cells, required this.cellW, required this.cellH});

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.length < 2) return;
    Offset centerOf(int i) {
      final r = i ~/ 7, c = i % 7;
      return Offset(c * cellW + cellW / 2, (5 - r) * cellH + cellH / 2);
    }
    // endpoints = the two cells farthest apart
    var a = cells.first, b = cells.first;
    var best = -1.0;
    final list = cells.toList();
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final d = (centerOf(list[i]) - centerOf(list[j])).distanceSquared;
        if (d > best) {
          best = d;
          a = list[i];
          b = list[j];
        }
      }
    }
    final p1 = centerOf(a), p2 = centerOf(b);
    final dir = (p2 - p1);
    final ext = dir / dir.distance * (cellW * 0.35);
    for (final (width, color) in [
      (12.0, const Color(0xFF5A3600)),
      (8.0, F4Colors.gold),
    ]) {
      canvas.drawLine(
        p1 - ext,
        p2 + ext,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WinLinePainter old) => old.cells != cells;
}

/// Dimmed backdrop + centered plaque card for pause / game-over.
class _OverlayCard extends StatelessWidget {
  final String title;
  final Color accent;
  final List<Widget> children;
  const _OverlayCard({
    required this.title,
    required this.children,
    this.accent = F4Colors.cream,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.62),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChromePlaque(text: title, fontSize: 26, accent: accent == F4Colors.cream ? null : accent),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: IronPanel(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
