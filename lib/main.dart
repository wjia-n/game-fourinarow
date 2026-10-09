import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/settings_service.dart';
import 'theme/arcade_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = F4Settings();
  await settings.load();
  final audio = F4Audio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    masterVol: settings.masterVol,
    musicVol: settings.musicVol,
  );
  final store = F4Store();
  await store.init();
  runApp(FourInARowApp(settings: settings, audio: audio, store: store));
}

class FourInARowApp extends StatefulWidget {
  final F4Settings settings;
  final F4Audio audio;
  final F4Store store;
  const FourInARowApp({
    super.key,
    required this.settings,
    required this.audio,
    required this.store,
  });

  @override
  State<FourInARowApp> createState() => _FourInARowAppState();
}

class _FourInARowAppState extends State<FourInARowApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    widget.store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final theme = F4ArcadeThemes.byId(widget.settings.themeId,
            custom: widget.settings.customTheme);
        return MaterialApp(
          title: 'Four in a Row',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: theme.woodDeep,
            colorScheme: ColorScheme.dark(
              primary: theme.accent,
              surface: theme.woodMid,
            ),
            useMaterial3: true,
          ),
          home: SplashScreen(
            audio: widget.audio,
            settings: widget.settings,
            store: widget.store,
          ),
        );
      },
    );
  }
}
