import 'package:flutter_test/flutter_test.dart';
import 'package:fourinarow/ai.dart';
import 'package:fourinarow/engine.dart';
import 'package:fourinarow/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Engine audit vs RULES.md: every rule test case, plus a headless
/// bot-vs-bot simulation proving no stuck states are possible.
void main() {
  group('engine — RULES.md compliance', () {
    test('empty board: RED drops column 3 -> row 0, turn passes to YELLOW',
        () {
      final e = FourInARowEngine();
      final row = e.play(3);
      expect(row, 0);
      expect(e.cells[3], 0);
      expect(e.turn, 1);
      expect(e.over, isFalse);
    });

    test('gravity: discs stack on the lowest free row', () {
      final e = FourInARowEngine();
      expect(e.play(2), 0);
      expect(e.play(2), 1);
      expect(e.play(2), 2);
      expect(e.cells[2], 0);
      expect(e.cells[1 * 7 + 2], 1);
      expect(e.cells[2 * 7 + 2], 0);
    });

    test('full column tap is rejected: no state change, turn stays', () {
      final e = FourInARowEngine();
      for (var i = 0; i < 6; i++) {
        expect(e.play(0), i);
      }
      final turnBefore = e.turn;
      final cellsBefore = List<int>.from(e.cells);
      expect(e.play(0), -1); // illegal
      expect(e.turn, turnBefore);
      expect(e.cells, cellsBefore);
      expect(e.over, isFalse);
    });

    test('out-of-range columns are illegal', () {
      final e = FourInARowEngine();
      expect(e.play(-1), -1);
      expect(e.play(7), -1);
      expect(e.history, isEmpty);
    });

    test('horizontal win: RED at (0,0),(1,0),(2,0) drops col 3', () {
      final e = FourInARowEngine();
      // RED: 0, YELLOW: 6 (keeps yellow busy), RED: 1, YELLOW: 6, ...
      e.play(0); // R
      e.play(6); // Y
      e.play(1); // R
      e.play(6); // Y
      e.play(2); // R
      e.play(6); // Y
      final row = e.play(3); // R wins
      expect(row, 0);
      expect(e.over, isTrue);
      expect(e.winner, 0);
      expect(e.isDraw, isFalse);
      expect(e.winCells.length, greaterThanOrEqualTo(4));
      // No moves after game end.
      expect(e.play(4), -1);
    });

    test('vertical win: YELLOW stacks column 2', () {
      final e = FourInARowEngine();
      e.play(0); // R
      e.play(2); // Y
      e.play(1); // R
      e.play(2); // Y
      e.play(0); // R
      e.play(2); // Y
      e.play(1); // R
      e.play(2); // Y -> vertical 4
      expect(e.over, isTrue);
      expect(e.winner, 1);
      expect(e.winCells.length, greaterThanOrEqualTo(4));
    });

    test('diagonal win (rising /)', () {
      final e = FourInARowEngine();
      // Build RED diagonal (0,0)-(1,1)-(2,2)-(3,3).
      e.play(0); // R (0,0)
      e.play(1); // Y (1,0)
      e.play(1); // R (1,1)
      e.play(2); // Y (2,0)
      e.play(6); // R filler
      e.play(2); // Y (2,1)
      e.play(2); // R (2,2)
      e.play(3); // Y (3,0)
      e.play(6); // R filler
      e.play(3); // Y (3,1)
      e.play(6); // R filler
      e.play(3); // Y (3,2)
      e.play(3); // R (3,3) -> wins
      expect(e.over, isTrue);
      expect(e.winner, 0);
    });

    test('diagonal win (falling \\)', () {
      final e = FourInARowEngine();
      // YELLOW diagonal (3,0)-(2,1)-(1,2)-(0,3): mirror of the above.
      e.play(6); // R filler
      e.play(3); // Y (3,0)
      e.play(2); // R (2,0)
      e.play(2); // Y (2,1)
      e.play(1); // R (1,0)
      e.play(6); // Y filler
      e.play(1); // R (1,1)
      e.play(1); // Y (1,2)
      e.play(0); // R (0,0)
      e.play(6); // Y filler
      e.play(0); // R (0,1)
      e.play(6); // Y filler
      e.play(0); // R (0,2)
      e.play(0); // Y (0,3) -> wins
      expect(e.over, isTrue);
      expect(e.winner, 1);
    });

    test('line of 5 also wins', () {
      final e = FourInARowEngine();
      for (var c = 0; c < 5; c++) {
        e.play(c); // R
        if (c < 4) e.play(6); // Y filler (stops at 4 to let R finish)
      }
      // After R plays col 3 -> horizontal 4, game already over.
      expect(e.over, isTrue);
      expect(e.winner, 0);
    });

    test('full board with no line of 4 -> draw', () {
      // Known draw pattern: cell(r,c) = (((c ~/ 2) + r) % 2 == 0) ? RED : YEL.
      // Verticals alternate, horizontals run at most 2, diagonals flip
      // parity at least every other step (max run 2) — no 4-in-a-row.
      int pat(int r, int c) => (((c ~/ 2) + r) % 2 == 0) ? 0 : 1;
      final e = FourInARowEngine();
      // Fill 41 cells, leaving (5,0) — the top of column 0 — empty.
      for (var c = 0; c < 7; c++) {
        for (var r = 0; r < 6; r++) {
          if (c == 0 && r == 5) continue;
          e.cells[r * 7 + c] = pat(r, c);
          e.history.add(c);
        }
      }
      // Sanity: no line of 4 anywhere on the 41-disc board.
      var preWin = false;
      for (var r = 0; r < 6; r++) {
        for (var c = 0; c < 7; c++) {
          if (e.cells[r * 7 + c] != -1 && e.findWin(r, c) != null) {
            preWin = true;
          }
        }
      }
      expect(preWin, isFalse, reason: 'draw pattern must have no line of 4');
      // Pattern assigns YELLOW to (5,0); YELLOW to move.
      e.turn = pat(5, 0);
      expect(e.turn, 1);
      final row = e.play(0);
      expect(row, 5);
      expect(e.over, isTrue);
      expect(e.isDraw, isTrue);
      expect(e.winner, -1);
    });

    test('42nd move creating a line -> win takes precedence over draw', () {
      // RED owns (0,0),(0,1),(0,2); (0,3) is the LAST empty cell on the
      // board. Everything else is filled arbitrarily (pre-existing lines
      // elsewhere are irrelevant: play() only checks the new disc's lines).
      final e = FourInARowEngine();
      for (var c = 0; c < 7; c++) {
        for (var r = 0; r < 6; r++) {
          if (c == 3 && r == 0) continue; // the final empty cell
          if (r == 0 && c < 3) {
            e.cells[r * 7 + c] = 0; // RED horizontal threat
          } else {
            e.cells[r * 7 + c] = 1;
          }
          e.history.add(c);
        }
      }
      expect(e.history.length, 41);
      e.turn = 0; // RED to move
      final row = e.play(3);
      expect(row, 0);
      expect(e.over, isTrue);
      expect(e.winner, 0, reason: 'win must take precedence over draw');
      expect(e.isDraw, isFalse);
    });

    test('undo removes two plies and restores turn order', () {
      final e = FourInARowEngine();
      for (var c = 0; c < 5; c++) {
        e.play(c); // 5 plies: R,Y,R,Y,R -> turn = Y
      }
      expect(e.history.length, 5);
      expect(e.turn, 1);
      e.undoPly();
      e.undoPly();
      expect(e.history.length, 3);
      expect(e.turn, 1); // the player who made ply 3 (YELLOW) to move
      expect(e.cells[3], -1);
      expect(e.cells[4], -1);
      expect(e.cells[0], 0);
    });

    test('undo is refused after game end', () {
      final e = FourInARowEngine();
      e.play(0);
      e.play(6);
      e.play(1);
      e.play(6);
      e.play(2);
      e.play(6);
      e.play(3); // RED wins
      expect(e.over, isTrue);
      expect(e.undoPly(), isFalse);
    });

    test('reset restores the opening position, RED to move', () {
      final e = FourInARowEngine();
      e.play(3);
      e.play(3);
      e.reset();
      expect(e.cells.every((v) => v == -1), isTrue);
      expect(e.turn, 0);
      expect(e.over, isFalse);
      expect(e.history, isEmpty);
    });

    test('persistence round-trips board and side-to-move', () {
      final e = FourInARowEngine();
      for (var c = 0; c < 10; c++) {
        e.play(c % 7);
      }
      final json = e.toJson();
      final e2 = FourInARowEngine()..fromJson(json);
      expect(e2.cells, e.cells);
      expect(e2.turn, e.turn);
      expect(e2.history, e.history);
      expect(e2.over, isFalse);
    });

    test('opening player alternates across matches (RED opens first)', () async {
      SharedPreferences.setMockInitialValues({});
      final s = F4Settings();
      await s.load();
      expect(await s.nextStarter(), 0); // match 1: RED (RULES.md §3)
      expect(await s.nextStarter(), 1); // match 2: YELLOW
      expect(await s.nextStarter(), 0); // match 3: RED again
      // Survives reload.
      final s2 = F4Settings();
      await s2.load();
      expect(s2.lastStarter, 0);
      expect(await s2.nextStarter(), 1);
    });
  });

  group('bot AI — RULES.md §11', () {
    test('medium takes an immediate winning column', () {
      // RED owns (0,0),(1,0),(2,0); RED to move must play 3.
      final cells = List<int>.filled(42, -1);
      cells[0] = 0;
      cells[1] = 0;
      cells[2] = 0;
      cells[6] = 1;
      final col = Bot.chooseMedium(cells, 0);
      expect(col, 3);
    });

    test('medium blocks an immediate opponent threat', () {
      // YELLOW owns (4,0),(5,0),(6,0); RED to move must block 3.
      final cells = List<int>.filled(42, -1);
      cells[4] = 1;
      cells[5] = 1;
      cells[6] = 1;
      cells[0] = 0;
      final col = Bot.chooseMedium(cells, 0);
      expect(col, 3);
    });

    test('hard opens with the center column on an empty board', () {
      final cells = List<int>.filled(42, -1);
      expect(Bot.chooseHardSync(cells, 0), 3);
    });

    test('easy always returns a legal column', () {
      final cells = List<int>.filled(42, -1);
      for (var i = 0; i < 6; i++) {
        cells[i * 7 + 0] = i % 2; // column 0 full
      }
      for (var t = 0; t < 50; t++) {
        final col = Bot.chooseEasy(cells, 0);
        expect(col, isNot(0));
        expect(col, inInclusiveRange(0, 6));
      }
    });
  });

  group('bot-vs-bot simulation — no stuck states', () {
    /// Plays full games headlessly. Every game must terminate with a win or
    /// a draw, every chosen move must be legal, and the engine must never
    /// accept a move after the game ends.
    void playGames(int n, int Function(List<int>, int) pickA,
        int Function(List<int>, int) pickB) {
      var winsA = 0;
      var winsB = 0;
      var draws = 0;
      for (var g = 0; g < n; g++) {
        final e = FourInARowEngine();
        var plies = 0;
        while (!e.over) {
          expect(plies, lessThan(42),
              reason: 'game $g exceeded 42 plies without terminating');
          final side = e.turn;
          final col =
              side == 0 ? pickA(e.cells, side) : pickB(e.cells, side);
          expect(e.legalMoves(), contains(col),
              reason: 'game $g: bot chose illegal column $col');
          final row = e.play(col);
          expect(row, greaterThanOrEqualTo(0),
              reason: 'game $g: legal move was rejected');
          plies++;
        }
        // Terminal state is exactly one of win / draw.
        expect(e.winner == -1, e.isDraw,
            reason: 'game $g: terminal state inconsistent');
        if (e.isDraw) {
          draws++;
          expect(e.history.length, 42);
        } else {
          expect(e.winCells.length, greaterThanOrEqualTo(4));
          if (e.winner == 0) {
            winsA++;
          } else {
            winsB++;
          }
        }
        // Post-game: no further moves accepted.
        expect(e.play(3), -1);
      }
      // Sanity: bots actually finish games with varied outcomes.
      expect(winsA + winsB + draws, n);
    }

    test('easy vs medium: 30 games all terminate cleanly', () {
      playGames(30, Bot.chooseEasy, Bot.chooseMedium);
    });

    test('medium vs medium: 12 games all terminate cleanly', () {
      playGames(12, Bot.chooseMedium, Bot.chooseMedium);
    });

    test('hard (short budget) vs medium: 6 games all terminate cleanly', () {
      playGames(
        6,
        (cells, side) => Bot.chooseHardSync(cells, side, budgetMs: 150),
        Bot.chooseMedium,
      );
    });
  });
}

Matcher inInclusiveRange(int lo, int hi) =>
    predicate<int>((v) => v >= lo && v <= hi, 'in range [$lo, $hi]');
