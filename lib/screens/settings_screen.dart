import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/arcade_themes.dart';
import '../theme/arcade_widgets.dart';
import '../theme/themed_widgets.dart';

/// Settings: bat toggles (SFX, music), chrome-knob sliders (master, music
/// volume), EASY/MEDIUM/HARD chunky buttons, player renaming, stats,
/// RESET STATS / RESTORE DEFAULTS, BACK.
class SettingsScreen extends StatelessWidget {
  final F4Audio audio;
  final F4Settings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  F4ArcadeThemeDef get t =>
      F4ArcadeThemes.byId(settings.themeId, custom: settings.customTheme);

  void _refreshAudio() {
    audio.configure(
      musicOn: settings.musicOn,
      sfxOn: settings.sfxOn,
      masterVol: settings.masterVol,
      musicVol: settings.musicVol,
    );
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
            listenable: settings,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      _BackStud(
                        theme: theme,
                        onTap: () {
                          audio.click();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 14),
                      ChromePlaque(
                          text: 'SETTINGS', fontSize: 24, accent: theme.accentDark),
                    ],
                  ),
                  const SizedBox(height: 18),
                  IronPanel(
                    child: Column(
                      children: [
                        _ToggleRow(
                          label: 'SOUND FX',
                          value: settings.sfxOn,
                          theme: theme,
                          onChanged: (v) {
                            settings.setSfx(v);
                            _refreshAudio();
                            audio.click();
                          },
                        ),
                        const Divider(height: 18),
                        _ToggleRow(
                          label: 'MUSIC',
                          value: settings.musicOn,
                          theme: theme,
                          onChanged: (v) {
                            settings.setMusic(v);
                            _refreshAudio();
                            if (v) audio.startMenuMusic();
                          },
                        ),
                        const Divider(height: 18),
                        _SliderRow(
                          label: 'MASTER VOLUME',
                          value: settings.masterVol,
                          theme: theme,
                          onChanged: (v) {
                            settings.setMasterVol(v);
                            _refreshAudio();
                          },
                        ),
                        const SizedBox(height: 6),
                        _SliderRow(
                          label: 'MUSIC VOLUME',
                          value: settings.musicVol,
                          theme: theme,
                          onChanged: (v) {
                            settings.setMusicVol(v);
                            _refreshAudio();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  IronPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BOT DIFFICULTY',
                            style: F4Text.mono(12, color: theme.accentLight)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      audio.click();
                                      settings.setDifficulty(i);
                                    },
                                    child: Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: settings.difficulty == i
                                            ? theme.accent
                                            : theme.woodDeep,
                                        border: Border.all(
                                          color: settings.difficulty == i
                                              ? theme.accentLight
                                              : theme.accent
                                                  .withValues(alpha: 0.5),
                                          width: settings.difficulty == i
                                              ? 2.5
                                              : 1.5,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (i == 2 && !settings.isPro)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 4),
                                              child: Icon(Icons.lock,
                                                  size: 14,
                                                  color: theme.ivory
                                                      .withValues(alpha: 0.7)),
                                            ),
                                          Text(
                                            const ['EASY', 'MEDIUM', 'HARD'][i],
                                            style: F4Text.mono(
                                                13,
                                                color:
                                                    settings.difficulty == i
                                                        ? theme.woodDeep
                                                        : theme.ivory),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (!settings.isPro)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'HARD mode is a PRO feature.',
                              style: F4Text.body.copyWith(
                                  fontSize: 12,
                                  color:
                                      theme.ivory.withValues(alpha: 0.55)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  IronPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PLAYER NAMES',
                            style: F4Text.mono(12, color: theme.accentLight)),
                        const SizedBox(height: 10),
                        for (var i = 0; i < 2; i++) ...[
                          _NameRow(
                            side: i,
                            theme: theme,
                            settings: settings,
                            audio: audio,
                          ),
                          if (i == 0) const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ArcadeButton(
                    label: 'RESET STATS',
                    icon: Icons.delete_outline,
                    height: 56,
                    fontSize: 15,
                    onPressed: () async {
                      audio.click();
                      await settings.resetStats();
                    },
                  ),
                  const SizedBox(height: 10),
                  ArcadeButton(
                    label: 'RESTORE DEFAULTS',
                    icon: Icons.restore,
                    height: 56,
                    fontSize: 15,
                    onPressed: () async {
                      audio.click();
                      await settings.restoreDefaults();
                      _refreshAudio();
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackStud extends StatelessWidget {
  final F4ArcadeThemeDef theme;
  final VoidCallback onTap;
  const _BackStud({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.accentLight, theme.accent, theme.accentDark],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.woodDeep,
          ),
          child: Icon(Icons.arrow_back, color: theme.accentLight, size: 24),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final F4ArcadeThemeDef theme;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: F4Text.mono(14, color: theme.ivory)),
        ),
        BatToggle(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final F4ArcadeThemeDef theme;
  final ValueChanged<double> onChanged;
  const _SliderRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: F4Text.mono(12, color: theme.accentLight)),
        ChromeSlider(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _NameRow extends StatelessWidget {
  final int side;
  final F4ArcadeThemeDef theme;
  final F4Settings settings;
  final F4Audio audio;
  const _NameRow({
    required this.side,
    required this.theme,
    required this.settings,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ThemedDisc(
          player: side,
          size: 36,
          theme: theme,
          style: settings.discStyle,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            settings.playerNames[side],
            style: F4Text.mono(15, color: theme.ivory),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () async {
            final ctl =
                TextEditingController(text: settings.playerNames[side]);
            final focus = FocusNode();
            var cancelled = false;
            // Focus-loss commit: if the field loses focus (e.g. user taps
            // away) without pressing Save/Cancel, commit what's typed so the
            // rename is never lost. Cancelled dialogs commit nothing.
            focus.addListener(() {
              if (!focus.hasFocus && !cancelled) {
                settings.setPlayerName(side, ctl.text);
              }
            });
            final result = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: theme.woodMid,
                title: Text('Rename player',
                    style: F4Text.mono(16, color: theme.ivory)),
                content: TextField(
                  controller: ctl,
                  focusNode: focus,
                  autofocus: true,
                  maxLength: 14,
                  style: F4Text.mono(16, color: theme.ivory),
                  decoration: InputDecoration(
                    hintText: F4Settings.defaultNames[side],
                    hintStyle: F4Text.body.copyWith(
                        color: theme.ivory.withValues(alpha: 0.4)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: theme.accent)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: theme.accentLight, width: 2)),
                  ),
                  // Save-on-keystroke: every keystroke persists immediately.
                  onChanged: (v) => settings.setPlayerName(side, v),
                  // Keyboard-done commits too.
                  onSubmitted: (v) {
                    cancelled = true; // Save path handles the commit.
                    Navigator.of(ctx).pop(v);
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      cancelled = true;
                      Navigator.of(ctx).pop();
                    },
                    child: Text('Cancel',
                        style: F4Text.mono(14,
                            color: theme.ivory.withValues(alpha: 0.6))),
                  ),
                  TextButton(
                    onPressed: () {
                      cancelled = true; // Save path handles the commit.
                      Navigator.of(ctx).pop(ctl.text);
                    },
                    child: Text('Save',
                        style: F4Text.mono(14, color: theme.accentLight)),
                  ),
                ],
              ),
            );
            ctl.dispose();
            focus.dispose();
            if (result != null) {
              audio.click();
              await settings.setPlayerName(side, result);
            }
          },
          child: Text('RENAME',
              style: F4Text.mono(13, color: theme.accentLight)),
        ),
      ],
    );
  }
}
