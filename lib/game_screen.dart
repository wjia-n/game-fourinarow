import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Four in a Row - drop discs, hunt for fours, ruin friendships.
class FourInARowScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const FourInARowScreen({super.key, required this.players, required this.callbacks});

  @override
  State<FourInARowScreen> createState() => _FourInARowScreenState();
}

class _FourInARowScreenState extends State<FourInARowScreen> {
  static const cols = 7;
  static const rows = 6;
  late List<List<int>> board; // owner index or -1
  Set<int> winCells = {};
  int turn = 0;
  bool over = false;
  bool botBusy = false;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    board = List.generate(rows, (_) => List.filled(cols, -1));
    widget.callbacks.setActivePlayer(0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBot());
  }

  int _dropRow(int c) {
    for (var r = rows - 1; r >= 0; r--) {
      if (board[r][c] == -1) return r;
    }
    return -1;
  }

  bool _full() => board.every((row) => row.every((o) => o != -1));

  /// Returns the winning cell keys (r*cols+c), or null.
  Set<int>? _findWin(int r, int c) {
    const dirs = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    final me = board[r][c];
    for (final d in dirs) {
      final cells = <int>{r * cols + c};
      for (final s in [1, -1]) {
        var nr = r + d[0] * s, nc = c + d[1] * s;
        while (nr >= 0 && nr < rows && nc >= 0 && nc < cols && board[nr][nc] == me) {
          cells.add(nr * cols + nc);
          nr += d[0] * s;
          nc += d[1] * s;
        }
      }
      if (cells.length >= 4) return cells;
    }
    return null;
  }

  void _tapCol(int c) {
    if (over || botBusy || widget.players[turn].isBot) return;
    if (_dropRow(c) == -1) {
      Sfx.click(); // column's stuffed
      return;
    }
    _play(c);
  }

  void _play(int c) {
    final r = _dropRow(c);
    if (r == -1) return;
    Sfx.move();
    Set<int>? win;
    var draw = false;
    setState(() {
      board[r][c] = turn;
      win = _findWin(r, c);
      if (win != null) {
        winCells = win!;
        over = true;
      } else if (_full()) {
        over = true;
        draw = true;
      } else {
        turn = (turn + 1) % widget.players.length;
        widget.callbacks.setActivePlayer(turn);
      }
    });
    if (win != null) {
      Sfx.win();
      final w = widget.players[turn];
      w.score += 1;
      widget.callbacks.refreshHud();
      widget.callbacks.finish(
        winner: w,
        headline: '${w.name} connects four! 🏆',
        subline: 'Four in a row. Zero mercy. 🔴',
      );
    } else if (draw) {
      Sfx.lose();
      widget.callbacks.finish(
        headline: 'Board\'s full — it\'s a tie! 🎭',
        subline: 'Nobody blinked. Rematch?',
      );
    } else {
      _maybeBot();
    }
  }

  int _botCol() {
    // 1. take the win
    for (var c = 0; c < cols; c++) {
      final r = _dropRow(c);
      if (r == -1) continue;
      board[r][c] = turn;
      final wins = _findWin(r, c) != null;
      board[r][c] = -1;
      if (wins) return c;
    }
    // 2. block the rival's win
    final opp = (turn + 1) % widget.players.length;
    for (var c = 0; c < cols; c++) {
      final r = _dropRow(c);
      if (r == -1) continue;
      board[r][c] = opp;
      final danger = _findWin(r, c) != null;
      board[r][c] = -1;
      if (danger) return c;
    }
    // 3. center is king, with a dash of chaos
    const order = [3, 2, 4, 1, 5, 0, 6];
    final valid = order.where((c) => _dropRow(c) != -1).toList();
    if (valid.isEmpty) return -1;
    if (_rand.nextDouble() < 0.25) return valid[_rand.nextInt(valid.length)];
    return valid.first;
  }

  void _maybeBot() {
    if (over || !widget.players[turn].isBot) return;
    botBusy = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || over) return;
      final c = _botCol();
      botBusy = false;
      if (c == -1) return;
      _play(c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final me = widget.players[turn];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!over)
            TurnBanner(
              player: me,
              action: me.isBot ? ' is calculating… 🤖' : ', pick a column! 👇',
            ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: cols / (rows + 0.6),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: t.primary.withValues(alpha: 0.25), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: t.primary.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      for (var c = 0; c < cols; c++)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tapCol(c),
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              children: [
                                for (var r = 0; r < rows; r++)
                                  Expanded(child: _cell(r, c, t)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('First to 4 in a row takes it 🔴',
              style: TextStyle(color: t.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _cell(int r, int c, GameTheme t) {
    final owner = board[r][c];
    final isWin = winCells.contains(r * cols + c);
    return Padding(
      padding: const EdgeInsets.all(3),
      child: owner == -1
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.muted.withValues(alpha: 0.16),
              ),
            )
          : TweenAnimationBuilder<double>(
              key: ValueKey('$r,$c,$owner'),
              tween: Tween(begin: 0.2, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (_, v, _) {
                final base = widget.players[owner].color;
                final hsl = HSLColor.fromColor(base);
                final light = hsl.withLightness((hsl.lightness + 0.28).clamp(0.0, 1.0)).toColor();
                final dark = hsl.withLightness((hsl.lightness - 0.24).clamp(0.0, 1.0)).toColor();
                return Transform.scale(
                  scale: v,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.35),
                        colors: [light, base, dark],
                      ),
                      border: isWin ? Border.all(color: light, width: 3) : null,
                      boxShadow: isWin
                          ? [BoxShadow(color: base.withValues(alpha: 0.8), blurRadius: 14)]
                          : [
                              BoxShadow(
                                color: base.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: isWin
                        ? Center(
                            child: Text(widget.players[owner].emoji,
                                style: const TextStyle(fontSize: 16)))
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
