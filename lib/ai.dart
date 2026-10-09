import 'dart:math';
import 'package:flutter/foundation.dart';

/// Bot brain for Four in a Row (RULES.md §11).
///
/// Easy:   60% random legal column, 40% greedy one-ply (win > block).
/// Medium: minimax depth 3, center-out ordering, win/block one-ply first,
///         window-count eval with center-column windows weighted x3.
/// Hard:   iterative-deepening minimax (depth 5-6) with alpha-beta,
///         transposition table keyed on (board, side-to-move), center-out +
///         killer move ordering. Center column (3) opening on empty board.
class Bot {
  Bot._();

  static const int easy = 0;
  static const int medium = 1;
  static const int hard = 2;
  static const List<String> names = ['EASY', 'MEDIUM', 'HARD'];

  /// Pick a column for [side] (0 = red, 1 = yellow).
  static Future<int> choose(List<int> cells, int side, int difficulty) {
    switch (difficulty) {
      case easy:
        return Future.value(_chooseEasy(cells, side));
      case medium:
        return Future.value(_chooseMedium(cells, side));
      default:
        return compute(_hardSearch, {
          'cells': List<int>.from(cells),
          'side': side,
          'budgetMs': 2400,
          'seed': DateTime.now().millisecondsSinceEpoch,
        });
    }
  }

  /// Synchronous Easy choice — used by headless bot-vs-bot simulations
  /// and unit tests (no isolate, no async).
  static int chooseEasy(List<int> cells, int side) =>
      _chooseEasy(cells, side);

  /// Synchronous Medium choice — used by headless bot-vs-bot simulations
  /// and unit tests (no isolate, no async).
  static int chooseMedium(List<int> cells, int side) =>
      _chooseMedium(cells, side);

  /// Synchronous Hard choice with a custom time budget (ms) — test hook so
  /// the sim can run Hard brains without a multi-second isolate budget.
  static int chooseHardSync(List<int> cells, int side, {int budgetMs = 400}) {
    final args = <String, dynamic>{
      'cells': List<int>.from(cells),
      'side': side,
      'budgetMs': budgetMs,
      'seed': DateTime.now().millisecondsSinceEpoch,
    };
    return _hardSearch(args);
  }

  // -- Easy ---------------------------------------------------------------
  static int _chooseEasy(List<int> cells, int side) {
    final rand = Random();
    if (rand.nextDouble() < 0.6) {
      final legal = _legal(cells);
      return legal[rand.nextInt(legal.length)];
    }
    return _greedy(cells, side, rand);
  }

  /// One-ply greedy: take immediate win, else block immediate loss,
  /// else center-out preference with a dash of chaos.
  static int _greedy(List<int> cells, int side, Random rand) {
    final win = _immediateWin(cells, side);
    if (win != -1) return win;
    final block = _immediateWin(cells, 1 - side);
    if (block != -1) return block;
    const order = [3, 2, 4, 1, 5, 0, 6];
    final valid = order.where((c) => _dropRow(cells, c) != -1).toList();
    if (valid.isEmpty) return -1;
    if (rand.nextDouble() < 0.25) return valid[rand.nextInt(valid.length)];
    return valid.first;
  }

  // -- Medium -------------------------------------------------------------
  static int _chooseMedium(List<int> cells, int side) {
    final rand = Random();
    final win = _immediateWin(cells, side);
    if (win != -1) return win;
    final block = _immediateWin(cells, 1 - side);
    if (block != -1) return block;
    final search = _Search(cells, side,
        budgetMs: 800, seed: rand.nextInt(1 << 32), centerWeight3: true);
    return search.iterativeDeepening(maxDepth: 3);
  }
}

// ---------------------------------------------------------------------------
// Shared search machinery (also used by the compute isolate for Hard).
// ---------------------------------------------------------------------------

List<int> _legal(List<int> cells) {
  final out = <int>[];
  for (var c = 0; c < 7; c++) {
    if (_dropRow(cells, c) != -1) out.add(c);
  }
  return out;
}

int _dropRow(List<int> cells, int c) {
  for (var r = 0; r < 6; r++) {
    if (cells[r * 7 + c] == -1) return r;
  }
  return -1;
}

Set<int>? _findWin(List<int> cells, int r, int c) {
  const dirs = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
  ];
  final me = cells[r * 7 + c];
  for (final d in dirs) {
    final line = <int>{r * 7 + c};
    for (final s in [1, -1]) {
      var nr = r + d[0] * s, nc = c + d[1] * s;
      while (nr >= 0 && nr < 6 && nc >= 0 && nc < 7 && cells[nr * 7 + nc] == me) {
        line.add(nr * 7 + nc);
        nr += d[0] * s;
        nc += d[1] * s;
      }
    }
    if (line.length >= 4) return line;
  }
  return null;
}

/// Column that wins immediately for [side], or -1.
int _immediateWin(List<int> cells, int side) {
  for (final c in _legal(cells)) {
    final r = _dropRow(cells, c);
    cells[r * 7 + c] = side;
    final wins = _findWin(cells, r, c) != null;
    cells[r * 7 + c] = -1;
    if (wins) return c;
  }
  return -1;
}

class _TTEntry {
  final int score, depth, flag; // flag: 0 exact, 1 lower, 2 upper
  _TTEntry(this.score, this.depth, this.flag);
}

class _Search {
  final List<int> cells;
  final int me;
  final int budgetMs;
  final bool centerWeight3;
  final Random rand;
  final Map<String, _TTEntry> tt = {};
  final Map<int, int> killers = {}; // depth -> column
  final Stopwatch sw = Stopwatch();
  int nodes = 0;
  static const int winScore = 1000000;

  _Search(List<int> original, this.me,
      {required this.budgetMs, required int seed, this.centerWeight3 = false})
      : cells = List<int>.from(original),
        rand = Random(seed);

  bool get outOfTime => sw.elapsedMilliseconds >= budgetMs;
  String _key(int side) => '${cells.join()}:$side';

  /// Score every possible 4-cell window (69 total) from [me]'s perspective.
  int _evaluate(int side) {
    final opp = 1 - me;
    var score = 0;

    int windowScore(int a, int b, int c, int d, bool touchesCenter) {
      var mine = 0, theirs = 0;
      for (final v in [cells[a], cells[b], cells[c], cells[d]]) {
        if (v == me) {
          mine++;
        } else if (v == opp) {
          theirs++;
        }
      }
      if (mine > 0 && theirs > 0) return 0; // dead window
      var s = 0;
      if (mine == 3) {
        s += 10; // open 3
      } else if (mine == 2) {
        s += 5; // open 2
      } else if (mine == 1) {
        s += 1;
      }
      if (theirs == 3) {
        s -= 80; // opponent threat
      } else if (theirs == 2) {
        s -= 4;
      }
      if (touchesCenter && centerWeight3) s *= 3;
      return s;
    }

    bool isCenter(int c) => c == 3;
    // horizontal: r 0..5, c 0..3 (24)
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c <= 3; c++) {
        final i = r * 7 + c;
        score += windowScore(i, i + 1, i + 2, i + 3,
            isCenter(c) || isCenter(c + 1) || isCenter(c + 2) || isCenter(c + 3));
      }
    }
    // vertical: r 0..2, c 0..6 (21)
    for (var r = 0; r <= 2; r++) {
      for (var c = 0; c < 7; c++) {
        final i = r * 7 + c;
        score += windowScore(i, i + 7, i + 14, i + 21, isCenter(c));
      }
    }
    // diagonals (24)
    for (var r = 0; r <= 2; r++) {
      for (var c = 0; c <= 3; c++) {
        final i = r * 7 + c;
        final tc = isCenter(c) || isCenter(c + 1) || isCenter(c + 2) || isCenter(c + 3);
        score += windowScore(i, i + 8, i + 16, i + 24, tc);
        final j = (r + 3) * 7 + c;
        score += windowScore(j, j - 6, j - 12, j - 18, tc);
      }
    }
    if (!centerWeight3) {
      for (var r = 0; r < 6; r++) {
        if (cells[r * 7 + 3] == me) score += 3; // center column discs
      }
    }
    return score * (side == me ? 1 : -1);
  }

  List<int> _orderedMoves(int depth) {
    final moves = _legal(cells);
    moves.sort((a, b) {
      var sa = (3 - (a - 3).abs()) * 10;
      var sb = (3 - (b - 3).abs()) * 10;
      if (killers[depth] == a) sa += 100;
      if (killers[depth] == b) sb += 100;
      return sb - sa;
    });
    return moves;
  }

  int _minimax(int depth, int alpha, int beta, int side) {
    if (outOfTime) return 0;
    if ((++nodes & 2047) == 0 && outOfTime) return 0;

    final key = _key(side);
    final entry = tt[key];
    if (entry != null && entry.depth >= depth) {
      if (entry.flag == 0) return entry.score;
      if (entry.flag == 1 && entry.score >= beta) return entry.score;
      if (entry.flag == 2 && entry.score <= alpha) return entry.score;
    }

    final moves = _orderedMoves(depth);
    if (moves.isEmpty || depth == 0) return _evaluate(side);

    var best = -winScore * 2;
    var flag = 2; // upper bound
    for (final c in moves) {
      final r = _dropRow(cells, c);
      cells[r * 7 + c] = side;
      final int score;
      if (_findWin(cells, r, c) != null) {
        score = side == me ? winScore + depth : -winScore - depth;
      } else {
        score = -_minimax(depth - 1, -beta, -alpha, 1 - side);
      }
      cells[r * 7 + c] = -1;
      if (outOfTime) return 0;
      if (score > best) best = score;
      if (score > alpha) {
        alpha = score;
        flag = 0; // exact
        killers[depth] = c;
      }
      if (alpha >= beta) {
        flag = 1; // lower bound
        break;
      }
    }
    tt[key] = _TTEntry(best, depth, flag);
    return best;
  }

  /// Iterative deepening; returns the best column from the last
  /// fully completed depth, with random tie-break among equal scores.
  int iterativeDeepening({required int maxDepth}) {
    sw.start();
    final legal = _legal(cells);
    var bestCol = legal.isEmpty ? -1 : legal.first;
    for (var depth = 2; depth <= maxDepth && !outOfTime; depth++) {
      var alpha = -winScore * 2;
      final beta = winScore * 2;
      var best = -winScore * 2;
      final tied = <int>[];
      for (final c in _orderedMoves(depth)) {
        final r = _dropRow(cells, c);
        cells[r * 7 + c] = me;
        final int score;
        if (_findWin(cells, r, c) != null) {
          score = winScore + depth;
        } else {
          score = -_minimax(depth - 1, -beta, -alpha, 1 - me);
        }
        cells[r * 7 + c] = -1;
        if (outOfTime) break;
        if (score > best) {
          best = score;
          tied
            ..clear()
            ..add(c);
        } else if (score == best) {
          tied.add(c);
        }
        if (score > alpha) alpha = score;
      }
      if (!outOfTime && tied.isNotEmpty) {
        bestCol = tied[rand.nextInt(tied.length)];
      }
    }
    sw.stop();
    return bestCol;
  }
}

/// Top-level entry for compute(): Hard search.
int _hardSearch(Map<String, dynamic> args) {
  final cells = List<int>.from(args['cells'] as List);
  final side = args['side'] as int;
  final budgetMs = args['budgetMs'] as int;
  final seed = args['seed'] as int;

  // Opening book: empty board -> center column.
  if (cells.every((v) => v == -1)) return 3;

  // Immediate tactics first (cheap, guarantees win/block behavior).
  final win = _immediateWin(cells, side);
  if (win != -1) return win;
  final block = _immediateWin(cells, 1 - side);
  if (block != -1) return block;

  final search = _Search(cells, side, budgetMs: budgetMs, seed: seed);
  return search.iterativeDeepening(maxDepth: 6);
}
