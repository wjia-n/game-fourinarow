import 'package:shared_preferences/shared_preferences.dart';

/// Persisted settings + match stats for Four in a Row.
/// Stats are tracked per mode: 0 = vs Bot, 1 = 2 Players (RULES.md §8).
class F4Settings {
  F4Settings._();
  static final F4Settings instance = F4Settings._();

  bool musicOn = true;
  bool sfxOn = true;
  double masterVol = 0.8;
  double musicVol = 0.7;
  int difficulty = 1; // 0 easy, 1 medium, 2 hard

  // per-mode stats
  final List<int> matches = [0, 0];
  final List<int> redWins = [0, 0]; // "you" in vs-bot mode
  final List<int> yellowWins = [0, 0]; // "bot" in vs-bot mode
  final List<int> draws = [0, 0];
  final List<int> streak = [0, 0];
  final List<int> bestStreak = [0, 0];

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool('fir_music') ?? true;
    sfxOn = p.getBool('fir_sfx') ?? true;
    masterVol = p.getDouble('fir_master_vol') ?? 0.8;
    musicVol = p.getDouble('fir_music_vol') ?? 0.7;
    difficulty = p.getInt('fir_difficulty') ?? 1;
    for (var m = 0; m < 2; m++) {
      matches[m] = p.getInt('fir_matches_$m') ?? 0;
      redWins[m] = p.getInt('fir_red_$m') ?? 0;
      yellowWins[m] = p.getInt('fir_yel_$m') ?? 0;
      draws[m] = p.getInt('fir_draws_$m') ?? 0;
      streak[m] = p.getInt('fir_streak_$m') ?? 0;
      bestStreak[m] = p.getInt('fir_best_$m') ?? 0;
    }
    _ready = true;
  }

  Future<void> _saveAudio() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('fir_music', musicOn);
    await p.setBool('fir_sfx', sfxOn);
    await p.setDouble('fir_master_vol', masterVol);
    await p.setDouble('fir_music_vol', musicVol);
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    await _saveAudio();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    await _saveAudio();
  }

  Future<void> setMasterVol(double v) async {
    masterVol = v.clamp(0.0, 1.0);
    await _saveAudio();
  }

  Future<void> setMusicVol(double v) async {
    musicVol = v.clamp(0.0, 1.0);
    await _saveAudio();
  }

  Future<void> setDifficulty(int v) async {
    difficulty = v.clamp(0, 2);
    (await SharedPreferences.getInstance()).setInt('fir_difficulty', difficulty);
  }

  /// result: 0 = red wins, 1 = yellow wins, -1 = draw.
  Future<void> recordResult(int mode, int result) async {
    final p = await SharedPreferences.getInstance();
    matches[mode]++;
    await p.setInt('fir_matches_$mode', matches[mode]);
    if (result == 0) {
      redWins[mode]++;
      await p.setInt('fir_red_$mode', redWins[mode]);
      streak[mode]++;
    } else if (result == 1) {
      yellowWins[mode]++;
      await p.setInt('fir_yel_$mode', yellowWins[mode]);
      streak[mode] = 0;
    } else {
      draws[mode]++;
      await p.setInt('fir_draws_$mode', draws[mode]);
      streak[mode] = 0;
    }
    if (streak[mode] > bestStreak[mode]) {
      bestStreak[mode] = streak[mode];
      await p.setInt('fir_best_$mode', bestStreak[mode]);
    }
    await p.setInt('fir_streak_$mode', streak[mode]);
  }

  Future<void> resetStats() async {
    final p = await SharedPreferences.getInstance();
    for (var m = 0; m < 2; m++) {
      matches[m] = 0;
      redWins[m] = 0;
      yellowWins[m] = 0;
      draws[m] = 0;
      streak[m] = 0;
      bestStreak[m] = 0;
      await p.setInt('fir_matches_$m', 0);
      await p.setInt('fir_red_$m', 0);
      await p.setInt('fir_yel_$m', 0);
      await p.setInt('fir_draws_$m', 0);
      await p.setInt('fir_streak_$m', 0);
      await p.setInt('fir_best_$m', 0);
    }
  }

  Future<void> restoreDefaults() async {
    musicOn = true;
    sfxOn = true;
    masterVol = 0.8;
    musicVol = 0.7;
    difficulty = 1;
    await _saveAudio();
    await setDifficulty(1);
  }
}
