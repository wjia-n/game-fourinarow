import 'package:flutter_test/flutter_test.dart';
import 'package:fourinarow/ai.dart';
import 'package:fourinarow/engine.dart';

void main() {
  group('engine', () {
    test('drop lands at bottom row, turn alternates', () {
      final e = FourInARowEngine();
      expect(e.play(3), 0);
      expect(e.cells[0 * 7 + 3], 0);
      expect(e.turn, 1);
    });

    test('full column is rejected, turn stays', () {
      final e = FourInARowEngine();
      for (var i = 0; i < 6; i++) {
        e.play(0);
      }
      expect(e.turn, 0);
      expect(e.play(0), -1);
      expect(e.turn, 0);
      expect(e.over, isFalse);
    });

    test('horizontal win ends game immediately', () {
      final e = FourInARowEngine();
      e.play(0); e.play(6); e.play(1); e.play(6); e.play(2); e.play(6);
      expect(e.over, isFalse);
      e.play(3);
      expect(e.over, isTrue);
      expect(e.winner, 0);
      expect(e.winCells.length, 4);
      // no moves after game end
      expect(e.play(4), -1);
    });

    test('vertical win', () {
      final e = FourInARowEngine();
      e.play(0); e.play(2); e.play(0); e.play(2);
      e.play(1); e.play(2); e.play(1);
      expect(e.over, isFalse);
      e.play(2);
      expect(e.over, isTrue);
      expect(e.winner, 1);
    });

    test('diagonal win', () {
      final e = FourInARowEngine();
      e.play(0); e.play(1); e.play(6); e.play(2);
      e.play(1); e.play(2); e.play(6); e.play(3);
      e.play(2); e.play(3); e.play(6); e.play(3);
      expect(e.over, isFalse);
      e.play(3);
      expect(e.over, isTrue);
      expect(e.winner, 0);
    });

    test('undo removes two plies and restores turn', () {
      final e = FourInARowEngine();
      for (var i = 0; i < 5; i++) {
        e.play(i);
      }
      expect(e.history.length, 5);
      expect(e.turn, 1);
      expect(e.undoPly(), isTrue);
      expect(e.undoPly(), isTrue);
      expect(e.history.length, 3);
      expect(e.turn, 1); // player who made ply 3 moves again
    });

    test('reset clears everything', () {
      final e = FourInARowEngine();
      e.play(0); e.play(1);
      e.reset();
      expect(e.history, isEmpty);
      expect(e.turn, 0);
      expect(e.over, isFalse);
      expect(e.cells.every((v) => v == -1), isTrue);
    });

    test('out-of-range moves are illegal', () {
      final e = FourInARowEngine();
      expect(e.play(-1), -1);
      expect(e.play(7), -1);
    });

    test('serialization round-trip', () {
      final e = FourInARowEngine();
      e.play(3); e.play(3); e.play(4);
      final j = e.toJson();
      final e2 = FourInARowEngine()..fromJson(j);
      expect(e2.cells, e.cells);
      expect(e2.turn, e.turn);
      expect(e2.history, e.history);
    });
  });

  group('bot', () {
    test('easy always returns a legal column', () async {
      final e = FourInARowEngine();
      // fill column 0
      for (var i = 0; i < 6; i++) {
        e.play(0);
      }
      final c = await Bot.choose(e.cells, e.turn, Bot.easy);
      expect(c, isNot(0));
      expect(e.dropRow(c), isNot(-1));
    });

    test('medium takes the immediate win', () async {
      final e = FourInARowEngine();
      // red (bot) has 3 across the bottom: cols 0,1,2; red to move
      e.play(0); e.play(6); e.play(1); e.play(6); e.play(2); e.play(6);
      expect(e.turn, 0);
      final c = await Bot.choose(e.cells, 0, Bot.medium);
      expect(c, 3);
    });

    test('medium blocks the immediate loss', () async {
      final e = FourInARowEngine();
      // yellow threatens 3 across bottom; red (bot) to move must block col 3
      e.play(6); e.play(0); e.play(6); e.play(1); e.play(5); e.play(2);
      expect(e.turn, 0);
      final c = await Bot.choose(e.cells, 0, Bot.medium);
      expect(c, 3);
    });

    test('hard opens with the center column', () async {
      final e = FourInARowEngine();
      final c = await Bot.choose(e.cells, 0, Bot.hard);
      expect(c, 3);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('hard takes the immediate win', () async {
      final e = FourInARowEngine();
      e.play(0); e.play(6); e.play(1); e.play(6); e.play(2); e.play(6);
      final c = await Bot.choose(e.cells, 0, Bot.hard);
      expect(c, 3);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
