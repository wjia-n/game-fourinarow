import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const FourInARowApp());

class FourInARowApp extends StatelessWidget {
  const FourInARowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Four in a Row',
      tagline: 'Drop discs and connect four before your opponent does',
      emoji: '🔴',
      slug: 'fourinarow',
      howToPlay:
          '• Tap a column to drop your disc down the chute. 🔴\n• Connect 4 of your color — sideways, up-down or diagonal — to win.\n• Block your rival\'s sneaky almost-fours before they block yours!\n• Center columns are prime real estate. Fight for them. 🏙️\n• Fill the whole board with no winner? That\'s a dramatic tie. 🎭',
      playerOptions: const [1, 2],
      supportsBots: true,
      gameBuilder: (ctx, players, cb) => FourInARowScreen(players: players, callbacks: cb),
    );
  }
}
