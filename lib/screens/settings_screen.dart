import 'package:flutter/material.dart';

import '../ai.dart';
import '../audio.dart';
import '../settings.dart';
import '../theme.dart';

/// Settings: bat toggles (SFX, music), chrome-knob sliders (master, music),
/// difficulty chunky buttons, reset stats / restore defaults, back.
class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const SettingsScreen({super.key, required this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final s = F4Settings.instance;
  final audio = F4Audio.instance;

  Future<void> _changed() async {
    await audio.refresh();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: ChromePlaque(text: 'SETTINGS', fontSize: 26)),
            const SizedBox(height: 18),
            IronPanel(
              child: Column(
                children: [
                  _toggleRow(
                    label: 'SOUND FX',
                    value: s.sfxOn,
                    onChanged: (v) async {
                      await s.setSfx(v);
                      await audio.click();
                      await _changed();
                    },
                  ),
                  const SizedBox(height: 16),
                  _toggleRow(
                    label: 'MUSIC',
                    value: s.musicOn,
                    onChanged: (v) async {
                      await s.setMusic(v);
                      await _changed();
                      if (v) {
                        await audio.playMusic('audio/music_menu.wav');
                      }
                      await audio.click();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  _sliderRow(
                    label: 'MASTER VOLUME',
                    value: s.masterVol,
                    onChanged: (v) async {
                      await s.setMasterVol(v);
                      await _changed();
                    },
                  ),
                  const SizedBox(height: 8),
                  _sliderRow(
                    label: 'MUSIC VOLUME',
                    value: s.musicVol,
                    onChanged: (v) async {
                      await s.setMusicVol(v);
                      await _changed();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('BOT DIFFICULTY', style: F4Text.mono(14, color: F4Colors.amber)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 0 : 5,
                        right: i == 2 ? 0 : 5,
                      ),
                      child: _DifficultyButton(
                        label: Bot.names[i],
                        selected: s.difficulty == i,
                        onTap: () async {
                          await s.setDifficulty(i);
                          await audio.click();
                          setState(() {});
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            ArcadeButton(
              label: 'RESET STATS',
              icon: Icons.delete_outline,
              height: 56,
              fontSize: 15,
              onPressed: () async {
                await s.resetStats();
                await audio.click();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            ArcadeButton(
              label: 'RESTORE DEFAULTS',
              icon: Icons.restore,
              height: 56,
              fontSize: 15,
              onPressed: () async {
                await s.restoreDefaults();
                await audio.refresh();
                await audio.click();
                setState(() {});
              },
            ),
            const SizedBox(height: 18),
            ArcadeButton(
              label: 'BACK',
              icon: Icons.arrow_back,
              onPressed: () {
                audio.click();
                widget.onBack();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, style: F4Text.mono(15))),
        BatToggle(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: F4Text.mono(14)),
            Text('${(value * 100).round()}%', style: F4Text.monoDeboss(13).copyWith(color: F4Colors.amber)),
          ],
        ),
        const SizedBox(height: 4),
        ChromeSlider(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Chunky difficulty button; selected = depressed amber jewel state.
class _DifficultyButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DifficultyButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_DifficultyButton> createState() => _DifficultyButtonState();
}

class _DifficultyButtonState extends State<_DifficultyButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final pressed = widget.selected || _down;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 56,
        margin: EdgeInsets.only(top: pressed ? 3 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: pressed
                ? const [Color(0xFFC77F14), Color(0xFFF49F1C), Color(0xFFB56E0A)]
                : const [Color(0xFFFFFBF3), F4Colors.cream, Color(0xFFE3D5BF)],
          ),
          border: Border.all(
            color: pressed ? const Color(0xFF7A4A05) : F4Colors.chromeDark,
            width: 2,
          ),
          boxShadow: pressed
              ? const [BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 1))]
              : [
                  const BoxShadow(color: F4Colors.mechShadow, blurRadius: 0, offset: Offset(0, 3)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3)),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: F4Text.monoDeboss(14).copyWith(
            color: pressed ? const Color(0xFF3A2404) : F4Colors.deboss,
          ),
        ),
      ),
    );
  }
}
