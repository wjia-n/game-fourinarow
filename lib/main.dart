import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'screens/game_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/settings_screen.dart';
import 'settings.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await F4Settings.instance.init();
  await F4Audio.instance.init();
  runApp(const FourInARowApp());
}

enum _Screen { menu, game, settings }

class FourInARowApp extends StatefulWidget {
  const FourInARowApp({super.key});

  @override
  State<FourInARowApp> createState() => _FourInARowAppState();
}

class _FourInARowAppState extends State<FourInARowApp> {
  _Screen _screen = _Screen.menu;
  _Screen _settingsReturn = _Screen.menu;
  GameScreen? _game; // retained while settings is pushed over a live game
  Map<String, dynamic>? _save;
  bool _saveChecked = false;

  final audio = F4Audio.instance;
  final s = F4Settings.instance;

  @override
  void initState() {
    super.initState();
    audio.playMusic('audio/music_menu.wav');
    _checkSave();
  }

  Future<void> _checkSave() async {
    final save = await GameScreen.loadSave();
    if (mounted) {
      setState(() {
        _save = save;
        _saveChecked = true;
      });
    }
  }

  void _goMenu() {
    _game = null;
    setState(() {
      _screen = _Screen.menu;
      _saveChecked = false;
    });
    audio.playMusic('audio/music_menu.wav');
    _checkSave();
  }

  void _startGame({required int mode, Map<String, dynamic>? restored}) {
    setState(() {
      _game = GameScreen(
        key: ValueKey('game-$mode-${DateTime.now().millisecondsSinceEpoch}'),
        mode: mode,
        difficulty: s.difficulty,
        restored: restored,
        onExitToMenu: _goMenu,
        onOpenSettings: () {
          _settingsReturn = _Screen.game;
          setState(() => _screen = _Screen.settings);
        },
      );
      _screen = _Screen.game;
    });
    audio.playMusic('audio/music_game.wav');
  }

  void _openSettings() {
    _settingsReturn = _Screen.menu;
    setState(() => _screen = _Screen.settings);
    audio.click();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Four in a Row',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: F4Colors.walnut,
        colorScheme: ColorScheme.dark(
          primary: F4Colors.amber,
          surface: F4Colors.chassis,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: WalnutBackground(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _currentScreen(),
          ),
        ),
      ),
    );
  }

  Widget _currentScreen() {
    switch (_screen) {
      case _Screen.menu:
        return MenuScreen(
          key: const ValueKey('menu'),
          hasSave: _saveChecked && _save != null,
          onPlayBot: () => _startGame(mode: 0),
          onPlay2P: () => _startGame(mode: 1),
          onOpenSettings: _openSettings,
          onResume: () {
            final save = _save;
            if (save == null) return;
            _startGame(
              mode: save['mode'] as int,
              restored: save,
            );
          },
        );
      case _Screen.game:
        return _game ?? const SizedBox.shrink(key: ValueKey('empty'));
      case _Screen.settings:
        return SettingsScreen(
          key: const ValueKey('settings'),
          onBack: () {
            audio.click();
            setState(() => _screen = _settingsReturn);
            if (_settingsReturn == _Screen.menu) {
              audio.playMusic('audio/music_menu.wav');
            } else {
              audio.playMusic('audio/music_game.wav');
            }
          },
        );
    }
  }
}
