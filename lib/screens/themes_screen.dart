import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/arcade_themes.dart';
import '../theme/arcade_widgets.dart';
import '../theme/themed_widgets.dart';
import 'pro_screen.dart';

/// Theme picker: 14 cabinet themes, 10 disc materials, 6 board accents,
/// plus a custom theme creator. All choices persist; PRO items are locked
/// for free players (tap → PRO screen).
class ThemesScreen extends StatelessWidget {
  final F4Audio audio;
  final F4Settings settings;
  final F4Store store;
  const ThemesScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  F4ArcadeThemeDef get t =>
      F4ArcadeThemes.byId(settings.themeId, custom: settings.customTheme);

  void _needPro(BuildContext context) {
    audio.click();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ProScreen(audio: audio, settings: settings, store: store)));
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          audio.click();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.accentLight,
                                theme.accent,
                                theme.accentDark
                              ],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.woodDeep,
                            ),
                            child: Icon(Icons.arrow_back,
                                color: theme.accentLight, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      ChromePlaque(
                          text: 'THEMES', fontSize: 24, accent: theme.accentDark),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(theme: theme, text: 'CABINET THEMES'),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: F4ArcadeThemes.all.length,
                    itemBuilder: (_, i) {
                      final th = F4ArcadeThemes.all[i];
                      final locked =
                          F4ArcadeThemes.isProTheme(th.id) && !settings.isPro;
                      final selected = settings.themeId == th.id;
                      return GestureDetector(
                        onTap: () {
                          if (locked) {
                            _needPro(context);
                            return;
                          }
                          audio.click();
                          settings.setTheme(th.id);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [th.woodMid, th.woodDark],
                            ),
                            border: Border.all(
                              color: selected
                                  ? theme.accentLight
                                  : th.accent.withValues(alpha: 0.6),
                              width: selected ? 3 : 1.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _dot(th.redDisc),
                                        const SizedBox(width: 8),
                                        _dot(th.amberDisc),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(th.name,
                                        style: F4Text.mono(12,
                                            color: th.ivory),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                              if (locked)
                                const Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(Icons.lock,
                                      size: 16, color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _CustomThemeTile(
                    theme: theme,
                    settings: settings,
                    audio: audio,
                    selected: settings.themeId == 'custom',
                    onLocked: () => _needPro(context),
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(theme: theme, text: 'DISC MATERIALS'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < DiscStyles.names.length; i++)
                        _DiscChip(
                          index: i,
                          theme: theme,
                          settings: settings,
                          audio: audio,
                          onLocked: () => _needPro(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(theme: theme, text: 'BOARD FRAME'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var i = 0; i < BoardAccents.names.length; i++)
                        _AccentChip(
                          index: i,
                          theme: theme,
                          settings: settings,
                          audio: audio,
                          onLocked: () => _needPro(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          border: Border.all(color: Colors.white30, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final F4ArcadeThemeDef theme;
  final String text;
  const _SectionTitle({required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: F4Text.mono(13, color: theme.accentLight));
  }
}

class _DiscChip extends StatelessWidget {
  final int index;
  final F4ArcadeThemeDef theme;
  final F4Settings settings;
  final F4Audio audio;
  final VoidCallback onLocked;
  const _DiscChip({
    required this.index,
    required this.theme,
    required this.settings,
    required this.audio,
    required this.onLocked,
  });

  @override
  Widget build(BuildContext context) {
    final locked = DiscStyles.isPro(index) && !settings.isPro;
    final selected = settings.discStyle == index;
    return GestureDetector(
      onTap: () {
        if (locked) {
          onLocked();
          return;
        }
        audio.click();
        settings.setDiscStyle(index);
      },
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? theme.accent : theme.woodDeep,
          border: Border.all(
            color: selected
                ? theme.accentLight
                : theme.accent.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ThemedDisc(
                  player: 0,
                  size: 44,
                  theme: theme,
                  style: index,
                ),
                if (locked)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(Icons.lock, size: 14, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DiscStyles.names[index],
              style: F4Text.mono(10,
                  color: selected ? theme.woodDeep : theme.ivory),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentChip extends StatelessWidget {
  final int index;
  final F4ArcadeThemeDef theme;
  final F4Settings settings;
  final F4Audio audio;
  final VoidCallback onLocked;
  const _AccentChip({
    required this.index,
    required this.theme,
    required this.settings,
    required this.audio,
    required this.onLocked,
  });

  @override
  Widget build(BuildContext context) {
    final locked = BoardAccents.isPro(index) && !settings.isPro;
    final selected = settings.boardAccent == index;
    final cols = BoardAccents.colors(index, theme);
    return GestureDetector(
      onTap: () {
        if (locked) {
          onLocked();
          return;
        }
        audio.click();
        settings.setBoardAccent(index);
      },
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? theme.accent : theme.woodDeep,
          border: Border.all(
            color: selected
                ? theme.accentLight
                : theme.accent.withValues(alpha: 0.5),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: cols,
                    ),
                    border: Border.all(
                        color: Colors.black.withValues(alpha: 0.4)),
                  ),
                ),
                if (locked)
                  const Positioned(
                    right: 2,
                    top: 2,
                    child: Icon(Icons.lock, size: 14, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              BoardAccents.names[index],
              style: F4Text.mono(10,
                  color: selected ? theme.woodDeep : theme.ivory),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomThemeTile extends StatelessWidget {
  final F4ArcadeThemeDef theme;
  final F4Settings settings;
  final F4Audio audio;
  final bool selected;
  final VoidCallback onLocked;
  const _CustomThemeTile({
    required this.theme,
    required this.settings,
    required this.audio,
    required this.selected,
    required this.onLocked,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !settings.isPro;
    return GestureDetector(
      onTap: () {
        if (locked) {
          onLocked();
          return;
        }
        audio.click();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CustomThemeScreen(
                audio: audio, settings: settings)));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.woodDeep,
          border: Border.all(
            color: selected
                ? theme.accentLight
                : theme.accent.withValues(alpha: 0.5),
            width: selected ? 3 : 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.brush, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MY CREATION',
                      style: F4Text.mono(13, color: theme.ivory)),
                  Text(
                    locked
                        ? 'Custom theme creator — PRO'
                        : 'Design your own cabinet colors',
                    style: F4Text.body.copyWith(
                        fontSize: 12,
                        color: theme.ivory.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            if (locked)
              const Icon(Icons.lock, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Custom theme creator: pick real colors for every cabinet surface.
class CustomThemeScreen extends StatelessWidget {
  final F4Audio audio;
  final F4Settings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  static const Map<String, String> labels = {
    'woodDark': 'Cabinet wood (dark)',
    'woodMid': 'Cabinet wood (mid)',
    'woodDeep': 'Deep recess',
    'accent': 'Metal accent',
    'accentLight': 'Metal highlight',
    'accentDark': 'Metal shadow',
    'ivory': 'Cream plastic',
    'felt': 'Board bed',
    'redDisc': 'Red side discs',
    'amberDisc': 'Yellow side discs',
  };

  static const List<Color> swatches = [
    Color(0xFF1D100B),
    Color(0xFF4A2E18),
    Color(0xFF7A5228),
    Color(0xFF8C9095),
    Color(0xFFC9CDD2),
    Color(0xFFC9A227),
    Color(0xFFB0713A),
    Color(0xFFF4EDE2),
    Color(0xFF2E4030),
    Color(0xFF1E3A4A),
    Color(0xFFD63426),
    Color(0xFFF49F1C),
    Color(0xFF2E7D4F),
    Color(0xFF3A6EA5),
    Color(0xFF7D4E9E),
    Color(0xFF101418),
  ];

  F4ArcadeThemeDef get t =>
      F4ArcadeThemes.byId(settings.themeId, custom: settings.customTheme);

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          audio.click();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.accentLight,
                                theme.accent,
                                theme.accentDark
                              ],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.woodDeep,
                            ),
                            child: Icon(Icons.arrow_back,
                                color: theme.accentLight, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      ChromePlaque(
                          text: 'MY CREATION',
                          fontSize: 22,
                          accent: theme.accentDark),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap a swatch to recolor each surface. Saved automatically.',
                    style: F4Text.body.copyWith(
                        fontSize: 13,
                        color: theme.ivory.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 14),
                  for (final key in labels.keys)
                    _ColorRow(
                      label: labels[key]!,
                      current: Color(settings.customColors[key]!),
                      onPick: (c) {
                        audio.click();
                        settings.setCustomColor(key, c.toARGB32());
                        if (settings.themeId != 'custom') {
                          settings.setTheme('custom');
                        }
                      },
                    ),
                  const SizedBox(height: 14),
                  ArcadeButton(
                    label: 'RESET COLORS',
                    icon: Icons.restore,
                    height: 56,
                    fontSize: 15,
                    onPressed: () async {
                      audio.click();
                      await settings.resetCustomColors();
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

class _ColorRow extends StatelessWidget {
  final String label;
  final Color current;
  final ValueChanged<Color> onPick;
  const _ColorRow({
    required this.label,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: current,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: F4Text.mono(12, color: Colors.white.withValues(alpha: 0.85))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in CustomThemeScreen.swatches)
                GestureDetector(
                  onTap: () => onPick(s),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s,
                      border: Border.all(
                        color: s.toARGB32() == current.toARGB32()
                            ? Colors.white
                            : Colors.white24,
                        width: s.toARGB32() == current.toARGB32() ? 3 : 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
