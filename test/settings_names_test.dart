import 'package:flutter_test/flutter_test.dart';
import 'package:fourinarow/match_engine.dart';
import 'package:fourinarow/services/audio_service.dart';
import 'package:fourinarow/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for the player-name persistence bug (2026-10-09):
///
/// Player names were stored with SharedPreferences.setStringList, which on
/// Android is backed by an UNORDERED StringSet — so after an app restart the
/// two names came back in arbitrary order and renames appeared "not saved".
/// Names are now stored as one order-preserving JSON string
/// (fourinarow_player_names_json), with one-time migration from the legacy
/// key. These tests cover the encode/decode round-trip, the real
/// SharedPreferences load/save path (via a fake values map), the legacy
/// migration, and the match name getters after a simulated restart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('names survive an encode/decode round-trip in exact slot order', () {
    const names = ['Wajiha', 'Bot Bob'];
    final decoded = F4Settings.decodePlayerNames(
      F4Settings.encodePlayerNames(names),
    );
    expect(decoded, names);
    // Slot order is what matters: each index must map to the same player.
    for (int i = 0; i < 2; i++) {
      expect(decoded[i], names[i]);
    }
  });

  test('decode falls back to defaults on missing or corrupt data', () {
    expect(
      F4Settings.decodePlayerNames(null),
      F4Settings.defaultNames,
    );
    expect(
      F4Settings.decodePlayerNames('definitely not json'),
      F4Settings.defaultNames,
    );
    expect(
      F4Settings.decodePlayerNames('["only"]'),
      F4Settings.defaultNames,
    );
    expect(
      F4Settings.decodePlayerNames('{"a":1}'),
      F4Settings.defaultNames,
    );
    expect(
      F4Settings.decodePlayerNames('["one","two","three"]'),
      F4Settings.defaultNames,
    );
  });

  test('blank entries fall back to that slot\'s default name', () {
    final decoded =
        F4Settings.decodePlayerNames('["Wajiha","  "]');
    expect(decoded, ['Wajiha', 'Yellow']);
  });

  test('names survive a real prefs save/load cycle in slot order', () async {
    SharedPreferences.setMockInitialValues({});
    final s1 = F4Settings();
    await s1.load();
    await s1.setPlayerName(0, 'Wajiha');
    await s1.setPlayerName(1, 'Zara');

    // Simulate an app restart: a fresh settings object loads the same prefs.
    final s2 = F4Settings();
    await s2.load();
    expect(s2.playerNames, ['Wajiha', 'Zara']);
    expect(s2.playerNames[0], 'Wajiha');
    expect(s2.playerNames[1], 'Zara');
  });

  test('legacy StringList key migrates once, then is dropped', () async {
    SharedPreferences.setMockInitialValues({
      'fir_player_names': ['LegacyRed', 'LegacyYellow'],
    });
    final s = F4Settings();
    await s.load();
    expect(s.playerNames, ['LegacyRed', 'LegacyYellow']);

    // Any subsequent save must move names to the JSON key and remove the
    // legacy key so Android can never scramble the order again.
    final p = await SharedPreferences.getInstance();
    await s.setTheme('walnut');
    expect(p.getString('fourinarow_player_names_json'),
        F4Settings.encodePlayerNames(['LegacyRed', 'LegacyYellow']));
    expect(p.containsKey('fir_player_names'), isFalse);
  });

  test('match name getters reflect persisted names after "restart"', () async {
    // Simulate: user renamed slot 0, app restarted, match rebuilt from the
    // persisted value.
    SharedPreferences.setMockInitialValues({});
    final settings = F4Settings();
    await settings.load();
    await settings.setPlayerName(0, 'Wajiha');

    final fresh = F4Settings();
    await fresh.load();
    final match = F4Match(
      settings: fresh,
      audio: F4Audio(),
      mode: 1,
      difficulty: 1,
    );
    expect(match.redName, 'Wajiha');
    expect(match.yellowName, 'Yellow');
    expect(match.sideName(0), 'Wajiha');
    expect(match.sideName(1), 'Yellow');
    match.dispose();
  });
}
