import 'package:flutter/material.dart';

import '../match_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/arcade_themes.dart';
import '../theme/arcade_widgets.dart';
import '../theme/themed_widgets.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'themes_screen.dart';

/// Main menu: title marquee → board toy → mode buttons → difficulty row →
/// player trays → stats plaque.
class MenuScreen extends StatefulWidget {
  final F4Audio audio;
  final F4Settings settings;
  final F4Store store;
  const MenuScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, dynamic>? _save;
  bool _saveChecked = false;

  F4Settings get s => widget.settings;
  F4ArcadeThemeDef get t =>
      F4ArcadeThemes.byId(s.themeId, custom: s.customTheme);

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _checkSave();
  }

  Future<void> _checkSave() async {
    final save = await F4Match.loadSave();
    if (mounted) {
      setState(() {
        _save = save;
        _saveChecked = true;
      });
    }
  }

  void _push(Widget screen) {
    widget.audio.click();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) {
      widget.audio.startMenuMusic();
      _checkSave();
    });
  }

  void _startGame({required int mode, Map<String, dynamic>? restored}) {
    _push(GameScreen(
      audio: widget.audio,
      settings: s,
      mode: mode,
      difficulty: s.difficulty,
      restored: restored,
    ));
  }

  Future<void> _rename(int side) async {
    final ctl = TextEditingController(text: s.playerNames[side]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.woodMid,
        title: Text('Rename player',
            style: F4Text.mono(16, color: t.ivory)),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: 14,
          style: F4Text.mono(16, color: t.ivory),
          decoration: InputDecoration(
            hintText: F4Settings.defaultNames[side],
            hintStyle: F4Text.body.copyWith(
                color: t.ivory.withValues(alpha: 0.4)),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: t.accent)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: t.accentLight, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: F4Text.mono(14, color: t.ivory.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctl.text),
            child:
                Text('Save', style: F4Text.mono(14, color: t.accentLight)),
          ),
        ],
      ),
    );
    if (result != null) {
      widget.audio.click();
      await s.setPlayerName(side, result);
    }
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
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  // Sound studs.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _Stud(
                        icon: s.musicOn ? Icons.music_note : Icons.music_off,
                        onTap: () {
                          s.setMusic(!s.musicOn);
                          widget.audio.configure(
                            musicOn: s.musicOn,
                            sfxOn: s.sfxOn,
                            masterVol: s.masterVol,
                            musicVol: s.musicVol,
                          );
                          if (s.musicOn) {
                            widget.audio.startMenuMusic();
                          }
                        },
                        theme: theme,
                      ),
                      const SizedBox(width: 10),
                      _Stud(
                        icon: s.sfxOn ? Icons.volume_up : Icons.volume_off,
                        onTap: () {
                          s.setSfx(!s.sfxOn);
                          widget.audio.configure(
                            musicOn: s.musicOn,
                            sfxOn: s.sfxOn,
                            masterVol: s.masterVol,
                            musicVol: s.musicVol,
                          );
                          widget.audio.click();
                        },
                        theme: theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ChromePlaque(
                    text: 'FOUR IN A ROW',
                    fontSize: 30,
                    accent: theme.accentDark,
                  ),
                  const SizedBox(height: 14),
                  // Mini board toy with the game logo.
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.accent, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/fourinarow_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 18),
                  if (_saveChecked && _save != null) ...[
                    ArcadeButton(
                      label:
                          'RESUME  ·  ${_save!['mode'] == 0 ? 'VS BOT' : '2 PLAYERS'}',
                      icon: Icons.play_arrow,
                      onPressed: () => _startGame(
                        mode: _save!['mode'] as int,
                        restored: _save,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ArcadeButton(
                    label: 'PLAY VS BOT',
                    icon: Icons.smart_toy,
                    onPressed: () => _startGame(mode: 0),
                  ),
                  const SizedBox(height: 12),
                  ArcadeButton(
                    label: '2 PLAYERS',
                    icon: Icons.people,
                    onPressed: () => _startGame(mode: 1),
                  ),
                  const SizedBox(height: 16),
                  // Difficulty row.
                  Text('BOT DIFFICULTY',
                      style: F4Text.mono(12, color: theme.accentLight)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: Padding(
                            padding:
                                EdgeInsets.only(left: i == 0 ? 0 : 8),
                            child: _DifficultyChip(
                              label: const ['EASY', 'MEDIUM', 'HARD'][i],
                              selected: s.difficulty == i,
                              locked: i == 2 && !s.isPro,
                              theme: theme,
                              onTap: () {
                                if (i == 2 && !s.isPro) {
                                  _push(ProScreen(
                                    audio: widget.audio,
                                    settings: s,
                                    store: widget.store,
                                  ));
                                  return;
                                }
                                widget.audio.click();
                                s.setDifficulty(i);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Player trays.
                  PlayerTray(
                    side: 0,
                    name: s.playerNames[0],
                    isBot: false,
                    active: false,
                    thinking: false,
                    theme: theme,
                    discStyle: s.discStyle,
                    onRename: () => _rename(0),
                  ),
                  const SizedBox(height: 10),
                  PlayerTray(
                    side: 1,
                    name: s.playerNames[1],
                    isBot: true,
                    active: false,
                    thinking: false,
                    theme: theme,
                    discStyle: s.discStyle,
                    onRename: () => _rename(1),
                  ),
                  const SizedBox(height: 16),
                  // Stats plaque.
                  _StatsPlaque(theme: theme, s: s),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ArcadeButton(
                          label: 'THEMES',
                          icon: Icons.palette,
                          height: 56,
                          fontSize: 14,
                          onPressed: () => _push(ThemesScreen(
                            audio: widget.audio,
                            settings: s,
                            store: widget.store,
                          )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ArcadeButton(
                          label: s.isPro ? 'PRO ✓' : 'GET PRO',
                          icon: Icons.star,
                          height: 56,
                          fontSize: 14,
                          onPressed: () => _push(ProScreen(
                            audio: widget.audio,
                            settings: s,
                            store: widget.store,
                          )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ArcadeButton(
                          label: 'SETTINGS',
                          icon: Icons.settings,
                          height: 56,
                          fontSize: 14,
                          onPressed: () => _push(SettingsScreen(
                            audio: widget.audio,
                            settings: s,
                          )),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stud extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final F4ArcadeThemeDef theme;
  const _Stud({required this.icon, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
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
          child: Icon(icon, color: theme.accentLight, size: 22),
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool locked;
  final F4ArcadeThemeDef theme;
  final VoidCallback onTap;
  const _DifficultyChip({
    required this.label,
    required this.selected,
    required this.locked,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? theme.accent : theme.woodDeep,
          border: Border.all(
            color: selected ? theme.accentLight : theme.accent.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.lock,
                    size: 14,
                    color: theme.ivory.withValues(alpha: 0.7)),
              ),
            Text(
              label,
              style: F4Text.mono(13,
                  color: selected ? theme.woodDeep : theme.ivory),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsPlaque extends StatelessWidget {
  final F4ArcadeThemeDef theme;
  final F4Settings s;
  const _StatsPlaque({required this.theme, required this.s});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String vBot, String v2p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                  flex: 4,
                  child: Text(label,
                      style: F4Text.body.copyWith(
                          fontSize: 12,
                          color: theme.ivory.withValues(alpha: 0.7)))),
              Expanded(
                  flex: 2,
                  child: Text(vBot,
                      style: F4Text.mono(12, color: theme.ivory),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text(v2p,
                      style: F4Text.mono(12, color: theme.ivory),
                      textAlign: TextAlign.center)),
            ],
          ),
        );
    return IronPanel(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 4, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('VS BOT',
                      style: F4Text.mono(11, color: theme.accentLight),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('2P',
                      style: F4Text.mono(11, color: theme.accentLight),
                      textAlign: TextAlign.center)),
            ],
          ),
          const Divider(height: 10),
          row('Matches', '${s.matches[0]}', '${s.matches[1]}'),
          row('${s.playerNames[0]} wins', '${s.wins0[0]}', '${s.wins0[1]}'),
          row('${s.playerNames[1]} wins', '${s.wins1[0]}', '${s.wins1[1]}'),
          row('Draws', '${s.draws[0]}', '${s.draws[1]}'),
        ],
      ),
    );
  }
}
