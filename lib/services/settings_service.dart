import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/arcade_themes.dart';

/// Persisted settings + stats for Four in a Row. Survives app restarts.
///
/// Stores: audio toggles + volumes, player names (2 slots, renameable),
/// theme/appearance choices (incl. custom theme colors), bot difficulty,
/// Pro unlock state, opening-player alternation, and per-mode lifetime stats.
class F4Settings extends ChangeNotifier {
  static const _kMusic = 'fir_music_on';
  static const _kSfx = 'fir_sfx_on';
  static const _kMasterVol = 'fir_master_vol';
  static const _kMusicVol = 'fir_music_vol';
  static const _kDifficulty = 'fir_bot_difficulty'; // 0 easy, 1 medium, 2 hard
  static const _kNames = 'fir_player_names'; // legacy unordered StringSet key
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so the
  /// old key scrambled name order on every app restart. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'fourinarow_player_names_json';
  static const _kTheme = 'fir_theme_id';
  static const _kDiscStyle = 'fir_disc_style';
  static const _kBoardAccent = 'fir_board_accent';
  static const _kIsPro = 'fir_is_pro';
  static const _kLastStarter = 'fir_last_starter';
  static const _kMatches = 'fir_matches_'; // + mode
  static const _kWins0 = 'fir_wins0_';
  static const _kWins1 = 'fir_wins1_';
  static const _kDraws = 'fir_draws_';
  static const _kStreak = 'fir_streak_';
  static const _kBestStreak = 'fir_best_streak_';
  static const _kStreakSide = 'fir_streak_side_';
  static const _kCustomPrefix = 'fir_custom_';

  static const defaultNames = ['Red', 'Yellow'];

  /// Encode the 2 player names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 2) {
        return [for (int i = 0; i < 2; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double masterVol = 0.8;
  double musicVol = 0.7;
  int difficulty = 1; // medium default
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'walnut';
  int discStyle = 0;
  int boardAccent = 0;
  bool isPro = true; // everything unlocked — no Pro version

  /// Which side opened the last match (0 = Red, 1 = Yellow). Next match
  /// opens with the other side (RULES.md §3 + opening-player alternation).
  int lastStarter = 1;

  // per-mode stats (mode 0 = vs Bot, 1 = 2 Players) — RULES.md §8.
  final List<int> matches = [0, 0];
  final List<int> wins0 = [0, 0]; // Red side wins
  final List<int> wins1 = [0, 0]; // Yellow side wins
  final List<int> draws = [0, 0];
  final List<int> streak = [0, 0];
  final List<int> bestStreak = [0, 0];
  final List<int> streakSide = [-1, -1];

  /// Custom theme colors (ARGB ints).
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'woodDark': 0xFF1D100B,
    'woodMid': 0xFF4A2E18,
    'woodDeep': 0xFF0E0705,
    'accent': 0xFF8C9095,
    'accentLight': 0xFFC9CDD2,
    'accentDark': 0xFF565A5F,
    'ivory': 0xFFF4EDE2,
    'felt': 0xFF2E4030,
    'redDisc': 0xFFD63426,
    'amberDisc': 0xFFF49F1C,
  };

  F4ArcadeThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return F4ArcadeThemeDef(
      id: 'custom',
      name: 'My Creation',
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      woodDeep: c('woodDeep'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      ivory: c('ivory'),
      felt: c('felt'),
      redDisc: c('redDisc'),
      amberDisc: c('amberDisc'),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    masterVol = (p.getDouble(_kMasterVol) ?? 0.8).clamp(0.0, 1.0);
    musicVol = (p.getDouble(_kMusicVol) ?? 0.7).clamp(0.0, 1.0);
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    // Player names: prefer the order-safe JSON key. Fall back to the legacy
    // StringList key once (one-time migration); it may already be scrambled
    // on Android, which is exactly the bug this replaces.
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.length == 2)
          ? [for (int i = 0; i < 2; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'walnut';
    discStyle = (p.getInt(_kDiscStyle) ?? 0).clamp(0, DiscStyles.names.length - 1);
    boardAccent =
        (p.getInt(_kBoardAccent) ?? 0).clamp(0, BoardAccents.names.length - 1);
    isPro = true; // everything unlocked
    lastStarter = (p.getInt(_kLastStarter) ?? 1).clamp(0, 1);
    for (var m = 0; m < 2; m++) {
      matches[m] = p.getInt('$_kMatches$m') ?? 0;
      wins0[m] = p.getInt('$_kWins0$m') ?? 0;
      wins1[m] = p.getInt('$_kWins1$m') ?? 0;
      draws[m] = p.getInt('$_kDraws$m') ?? 0;
      streak[m] = p.getInt('$_kStreak$m') ?? 0;
      bestStreak[m] = p.getInt('$_kBestStreak$m') ?? 0;
      streakSide[m] = p.getInt('$_kStreakSide$m') ?? -1;
    }
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kMasterVol, masterVol);
    await p.setDouble(_kMusicVol, musicVol);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kDiscStyle, discStyle);
    await p.setInt(_kBoardAccent, boardAccent);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kLastStarter, lastStarter);
    for (var m = 0; m < 2; m++) {
      await p.setInt('$_kMatches$m', matches[m]);
      await p.setInt('$_kWins0$m', wins0[m]);
      await p.setInt('$_kWins1$m', wins1[m]);
      await p.setInt('$_kDraws$m', draws[m]);
      await p.setInt('$_kStreak$m', streak[m]);
      await p.setInt('$_kBestStreak$m', bestStreak[m]);
      await p.setInt('$_kStreakSide$m', streakSide[m]);
    }
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (F4ArcadeThemes.isProTheme(themeId)) {
      themeId = 'walnut';
      changed = true;
    }
    if (DiscStyles.isPro(discStyle)) {
      discStyle = 0;
      changed = true;
    }
    if (BoardAccents.isPro(boardAccent)) {
      boardAccent = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  /// Consume the alternation: returns the side that should open the next
  /// match, then persists the swap.
  Future<int> nextStarter() async {
    final starter = 1 - lastStarter;
    lastStarter = starter;
    notifyListeners();
    await _save();
    return starter;
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setMasterVol(double v) async {
    masterVol = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setMusicVol(double v) async {
    musicVol = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    var nv = v.clamp(0, 2);
    if (!isPro && nv > 1) nv = 1; // Hard is a Pro feature.
    difficulty = nv;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 1) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && F4ArcadeThemes.isProTheme(id)) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setDiscStyle(int v) async {
    v = v.clamp(0, DiscStyles.names.length - 1);
    if (!isPro && DiscStyles.isPro(v)) return;
    discStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setBoardAccent(int v) async {
    v = v.clamp(0, BoardAccents.names.length - 1);
    if (!isPro && BoardAccents.isPro(v)) return;
    boardAccent = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished match. [winnerSide]: 0 = Red, 1 = Yellow, -1 = draw.
  Future<void> recordResult(int mode, int winnerSide) async {
    matches[mode]++;
    if (winnerSide == 0) {
      wins0[mode]++;
    } else if (winnerSide == 1) {
      wins1[mode]++;
    } else {
      draws[mode]++;
    }
    if (winnerSide < 0) {
      streak[mode] = 0;
      streakSide[mode] = -1;
    } else if (streakSide[mode] == winnerSide) {
      streak[mode]++;
    } else {
      streakSide[mode] = winnerSide;
      streak[mode] = 1;
    }
    if (streak[mode] > bestStreak[mode]) bestStreak[mode] = streak[mode];
    notifyListeners();
    await _save();
  }

  Future<void> resetStats() async {
    for (var m = 0; m < 2; m++) {
      matches[m] = 0;
      wins0[m] = 0;
      wins1[m] = 0;
      draws[m] = 0;
      streak[m] = 0;
      bestStreak[m] = 0;
      streakSide[m] = -1;
    }
    notifyListeners();
    await _save();
  }

  Future<void> restoreDefaults() async {
    musicOn = true;
    sfxOn = true;
    masterVol = 0.8;
    musicVol = 0.7;
    difficulty = 1;
    notifyListeners();
    await _save();
  }
}
