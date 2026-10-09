/// Four in a Row — deterministic game engine.
///
/// RULES.md is the source of truth. Board is 7 cols x 6 rows with gravity.
/// cells[r * cols + c]: -1 empty, 0 = RED (player 1), 1 = YELLOW (player 2).
/// Row 0 is the BOTTOM row (discs settle at the lowest free row).
class FourInARowEngine {
  static const int cols = 7;
  static const int rows = 6;

  List<int> cells = List.filled(cols * rows, -1);
  int turn = 0; // 0 = RED, 1 = YELLOW
  bool over = false;
  int winner = -1; // -1 none, 0 red, 1 yellow
  bool isDraw = false;
  Set<int> winCells = {};
  final List<int> history = []; // columns played, in order

  /// Lowest free row in column [c], or -1 when the column is full.
  int dropRow(int c) {
    if (c < 0 || c >= cols) return -1;
    for (var r = 0; r < rows; r++) {
      if (cells[r * cols + c] == -1) return r;
    }
    return -1;
  }

  /// Legal columns right now.
  List<int> legalMoves() {
    final out = <int>[];
    for (var c = 0; c < cols; c++) {
      if (dropRow(c) != -1) out.add(c);
    }
    return out;
  }

  bool get isFull => history.length == cols * rows;

  /// Attempt to drop the current player's disc into column [c].
  /// Returns the row the disc landed on, or -1 if the move is illegal
  /// (column full/out of range, game over). Illegal moves change nothing.
  int play(int c) {
    if (over) return -1;
    final r = dropRow(c);
    if (r == -1) return -1;
    final mover = turn;
    cells[r * cols + c] = mover;
    history.add(c);
    // Win check first (win takes precedence over draw on the final move).
    final win = findWin(r, c);
    if (win != null) {
      winCells = win;
      winner = mover;
      over = true;
    } else if (isFull) {
      isDraw = true;
      over = true;
    } else {
      turn = 1 - turn;
    }
    return r;
  }

  /// Winning cells containing the line through (r, c), or null.
  /// Lines of 5/6 also win (they contain a line of 4).
  Set<int>? findWin(int r, int c) {
    const dirs = [
      [0, 1], // horizontal
      [1, 0], // vertical
      [1, 1], // diagonal /
      [1, -1], // diagonal \
    ];
    final me = cells[r * cols + c];
    if (me == -1) return null;
    for (final d in dirs) {
      final line = <int>{r * cols + c};
      for (final s in [1, -1]) {
        var nr = r + d[0] * s, nc = c + d[1] * s;
        while (nr >= 0 &&
            nr < rows &&
            nc >= 0 &&
            nc < cols &&
            cells[nr * cols + nc] == me) {
          line.add(nr * cols + nc);
          nr += d[0] * s;
          nc += d[1] * s;
        }
      }
      if (line.length >= 4) return line;
    }
    return null;
  }

  /// Remove the top disc of column [c] and hand the turn back.
  /// Returns false when there is nothing to undo.
  bool undoPly() {
    if (over || history.isEmpty) return false;
    final c = history.removeLast();
    for (var r = rows - 1; r >= 0; r--) {
      if (cells[r * cols + c] != -1) {
        cells[r * cols + c] = -1;
        turn = 1 - turn;
        return true;
      }
    }
    return false; // unreachable: history and cells stay in sync
  }

  void reset() {
    cells = List.filled(cols * rows, -1);
    turn = 0;
    over = false;
    winner = -1;
    isDraw = false;
    winCells = {};
    history.clear();
  }

  Map<String, dynamic> toJson() => {
        'cells': List<int>.from(cells),
        'turn': turn,
        'history': List<int>.from(history),
      };

  void fromJson(Map<String, dynamic> j) {
    reset();
    cells = List<int>.from(j['cells'] as List);
    turn = j['turn'] as int;
    history.addAll(List<int>.from(j['history'] as List));
    // Re-derive terminal state defensively: a saved game is never over.
    over = false;
    winner = -1;
    isDraw = false;
    winCells = {};
  }
}
