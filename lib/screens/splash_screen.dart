import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/arcade_themes.dart';
import '../theme/arcade_widgets.dart';
import '../theme/themed_widgets.dart';
import 'menu_screen.dart';

/// Launch splash: game logo + name, animated loading line, credits.
/// (Single splash — the WAJIHA company mark rides along the credits line.)
class SplashScreen extends StatefulWidget {
  final F4Audio audio;
  final F4Settings settings;
  final F4Store store;
  const SplashScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = F4ArcadeThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: theme.woodDeep,
      body: F4WoodBackdrop(
        theme: theme,
        child: _GameSplash(theme: theme, loader: _loader),
      ),
    );
  }
}

/// Game splash: logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final F4ArcadeThemeDef theme;
  final AnimationController loader;
  const _GameSplash({required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.accent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  offset: const Offset(0, 10),
                  blurRadius: 24,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/fourinarow_logo.png', fit: BoxFit.cover),
          ),
          const SizedBox(height: 22),
          Text(
            'FOUR IN A ROW',
            style: F4Text.headline(40, color: theme.ivory),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'THE TABLETOP ARCADE EDITION',
            style: F4Text.mono(12, color: theme.accentLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          // Animated loading line.
          SizedBox(
            width: 220,
            child: AnimatedBuilder(
              animation: loader,
              builder: (_, _) => Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.black.withValues(alpha: 0.45),
                      border: Border.all(
                          color: theme.accent.withValues(alpha: 0.5)),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: loader.value.clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              theme.accentLight,
                              theme.accent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loader.value < 1 ? 'Racking the discs…' : 'Ready!',
                    style: F4Text.body.copyWith(
                      fontSize: 13,
                      color: theme.ivory.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 44),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/wajiha_logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Text(
                'Credits: WAJIHA',
                style: F4Text.mono(14, color: theme.ivory),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
