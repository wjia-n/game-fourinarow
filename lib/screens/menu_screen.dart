import 'package:flutter/material.dart';

import '../audio.dart';
import '../settings.dart';
import '../theme.dart';

/// Main menu: title marquee, mini board toy, chunky mode buttons,
/// sound/music studs, stats readout, resume-when-saved.
class MenuScreen extends StatefulWidget {
  final VoidCallback onPlayBot;
  final VoidCallback onPlay2P;
  final VoidCallback onOpenSettings;
  final VoidCallback onResume;
  final bool hasSave;

  const MenuScreen({
    super.key,
    required this.onPlayBot,
    required this.onPlay2P,
    required this.onOpenSettings,
    required this.onResume,
    required this.hasSave,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final s = F4Settings.instance;
  final audio = F4Audio.instance;

  Future<void> _toggleMusic() async {
    await s.setMusic(!s.musicOn);
    await audio.refresh();
    if (s.musicOn) {
      await audio.playMusic('audio/music_menu.wav');
    }
    await audio.click();
    setState(() {});
  }

  Future<void> _toggleSfx() async {
    await s.setSfx(!s.sfxOn);
    await audio.refresh();
    await audio.click();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            // sound / music studs
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _Stud(
                  icon: s.sfxOn ? Icons.volume_up : Icons.volume_off,
                  on: s.sfxOn,
                  onTap: _toggleSfx,
                ),
                const SizedBox(width: 10),
                _Stud(
                  icon: s.musicOn ? Icons.music_note : Icons.music_off,
                  on: s.musicOn,
                  onTap: _toggleMusic,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const ChromePlaque(text: 'FOUR IN A ROW', fontSize: 30),
            const SizedBox(height: 4),
            Text('drop discs · connect four · talk trash',
                style: F4Text.body.copyWith(fontSize: 13)),
            const SizedBox(height: 18),
            const _MiniBoardToy(),
            const SizedBox(height: 22),
            if (widget.hasSave) ...[
              ArcadeButton(
                label: 'RESUME GAME',
                icon: Icons.play_arrow,
                onPressed: () {
                  audio.click();
                  widget.onResume();
                },
              ),
              const SizedBox(height: 14),
            ],
            ArcadeButton(
              label: 'PLAY VS BOT',
              icon: Icons.smart_toy_outlined,
              onPressed: () {
                audio.start();
                widget.onPlayBot();
              },
            ),
            const SizedBox(height: 14),
            ArcadeButton(
              label: '2 PLAYERS',
              icon: Icons.people_outline,
              onPressed: () {
                audio.start();
                widget.onPlay2P();
              },
            ),
            const SizedBox(height: 14),
            ArcadeButton(
              label: 'SETTINGS',
              icon: Icons.settings_outlined,
              onPressed: () {
                audio.click();
                widget.onOpenSettings();
              },
            ),
            const SizedBox(height: 20),
            IronPanel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'YOU ${s.redWins[0]}  ·  BOT ${s.yellowWins[0]}  ·  DRAW ${s.draws[0]}',
                style: F4Text.mono(14, color: F4Colors.amber),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small round chrome stud button (sound / music quick toggles).
class _Stud extends StatefulWidget {
  final IconData icon;
  final bool on;
  final VoidCallback onTap;
  const _Stud({required this.icon, required this.on, required this.onTap});

  @override
  State<_Stud> createState() => _StudState();
}

class _StudState extends State<_Stud> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: 52,
        height: 52,
        margin: EdgeInsets.only(top: _down ? 3 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [F4Colors.chromeLight, F4Colors.chrome, F4Colors.chromeDark],
          ),
          border: Border.all(color: const Color(0xFF3A3D41), width: 1.5),
          boxShadow: _down
              ? const []
              : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 3)),
                  const BoxShadow(color: F4Colors.mechShadow, blurRadius: 0, offset: Offset(0, 2)),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(widget.icon, color: F4Colors.deboss, size: 24),
            Positioned(
              top: 8,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.on ? F4Colors.amber : F4Colors.jewelOff,
                  boxShadow: widget.on
                      ? [BoxShadow(color: F4Colors.amber.withValues(alpha: 0.6), blurRadius: 6, spreadRadius: 1)]
                      : const [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative mini board toy for the menu marquee.
class _MiniBoardToy extends StatelessWidget {
  const _MiniBoardToy();

  @override
  Widget build(BuildContext context) {
    // preset charming position: red threatens, yellow blocks
    const redCells = {0, 1, 2, 8, 14, 22, 30};
    const yelCells = {7, 9, 15, 16, 21, 23, 29};
    return IronPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 5; r >= 0; r--)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < 7; c++)
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: _miniCell(r * 7 + c, redCells, yelCells),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _miniCell(int i, Set<int> red, Set<int> yel) {
    const s = 26.0;
    if (red.contains(i)) return const AcrylicDisc(player: 0, size: s);
    if (yel.contains(i)) return const AcrylicDisc(player: 1, size: s);
    return const BoardSlot(size: s);
  }
}
