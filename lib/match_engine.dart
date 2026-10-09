import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai.dart';
import 'engine.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';

/// Turn phases owned ENTIRELY by the match engine. The UI only renders.
///
/// [awaitingDrop] = a side may drop now (input unlocked for humans).
/// [thinking]     = a bot is choosing; the UI shows its tray + narration.
/// [dropping]     = a disc is visibly falling; input locked.
/// [over]         = match finished; no input accepted.
///
/// Stuck states are impossible by construction:
/// - exactly one phase timer exists at a time ([_arm] cancels the old one);
/// - a 2s watchdog ([_recover]) re-arms any phase found without a live timer;
/// - every async bot handoff re-checks phase/paused/disposed before acting;
/// - pause cancels timers; resume runs the watchdog immediately.
enum F4Phase { awaitingDrop, thinking, dropping, over }

/// A match of Four in a Row. Owns the deterministic rules engine, turn flow,
/// bot turns (with visible thinking + visible disc drops), persistence,
/// pause/resume and stats recording. UI-agnostic apart from ChangeNotifier.
class F4Match extends ChangeNotifier {
  final FourInARowEngine engine = FourInARowEngine();
  final F4Settings settings;
  final F4Audio audio;

  /// 0 = vs Bot, 1 = 2 Players.
  final int mode;
  final int difficulty;

  /// Which slots are bots: vs Bot → slot 1 (Yellow); 2 Players → none.
  final List<bool> isBot;

  F4Phase phase = F4Phase.awaitingDrop;
  String banner = '';

  // Visible drop animation state (UI renders the falling disc).
  int animCol = -1;
  int animRow = -1;
  int animPlayer = -1;
  int animStartMs = 0;
  static const int dropDurationMs = 460;

  // Invalid-column shake feedback (UI consumes and clears).
  int shakeCol = -1;

  // Pause / lifecycle.
  bool paused = false;

  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool _botBusy = false;
  int? _pendingBotCol; // bot chose while we were paused

  static const saveKey = 'fir_save_v2';

  F4Match({
    required this.settings,
    required this.audio,
    required this.mode,
    required this.difficulty,
    Map<String, dynamic>? restored,
  }) : isBot = mode == 0 ? [false, true] : [false, false] {
    if (restored != null) {
      try {
        engine.fromJson(Map<String, dynamic>.from(restored['engine'] as Map));
        banner = _turnBanner();
      } catch (_) {
        engine.reset();
      }
    }
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _recover());
    _afterPhase();
    notifyListeners();
  }

  String get redName => settings.playerNames[0];
  String get yellowName => settings.playerNames[1];
  String sideName(int side) => side == 0 ? redName : yellowName;
  bool get currentIsBot => isBot[engine.turn];

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer. Resume re-arms the current phase via the
  /// watchdog. Persists the game on pause (app backgrounded mid-game).
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
      save();
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if any phase is found without a live timer, recover it.
  /// This makes stuck states impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || engine.over || paused || _timer != null) return;
    if (phase == F4Phase.thinking) {
      if (_pendingBotCol != null && !_botBusy) {
        final col = _pendingBotCol!;
        _pendingBotCol = null;
        _applyDrop(col);
      } else if (!_botBusy) {
        _botTurn();
      }
    } else if (phase == F4Phase.dropping) {
      // Drop animation interrupted (e.g. backgrounded): finish the drop.
      _afterDrop();
    } else if (phase == F4Phase.awaitingDrop && currentIsBot) {
      _botTurn();
    }
  }

  String _turnBanner() {
    if (engine.over) return banner;
    final name = sideName(engine.turn);
    return currentIsBot ? '$name is up…' : '$name — drop a disc!';
  }

  // ------------------------------------------------------------- match flow
  /// Start (or restart) a match. The opening side alternates across matches
  /// (RULES.md §3: RED opens the first match).
  Future<void> newGame() async {
    _timer?.cancel();
    _timer = null;
    _botBusy = false;
    _pendingBotCol = null;
    engine.reset();
    engine.turn = await settings.nextStarter();
    phase = F4Phase.awaitingDrop;
    animCol = -1;
    animRow = -1;
    banner = _turnBanner();
    audio.gameStart();
    notifyListeners();
    _afterPhase();
  }

  /// Called whenever we settle into awaitingDrop: bots play themselves.
  void _afterPhase() {
    if (engine.over || phase != F4Phase.awaitingDrop || paused || _disposed) {
      return;
    }
    if (currentIsBot) _botTurn();
  }

  /// Human taps a column. Guarded: correct phase, human side, live game.
  /// Illegal (full column) → invalid sound + shake; turn does NOT pass.
  void humanDrop(int col) {
    if (engine.over ||
        phase != F4Phase.awaitingDrop ||
        currentIsBot ||
        paused) {
      return;
    }
    if (engine.dropRow(col) == -1) {
      shakeCol = col;
      banner = 'Column is full — pick another one!';
      audio.invalid();
      notifyListeners();
      return;
    }
    _applyDrop(col);
  }

  /// Commit the rules-engine move, then animate the disc visibly falling.
  void _applyDrop(int col) {
    final mover = engine.turn;
    final row = engine.play(col);
    if (row == -1) {
      // Defensive: should never happen (guarded above / bot uses legal
      // columns). Recover to awaitingDrop so the game can never stick.
      phase = F4Phase.awaitingDrop;
      notifyListeners();
      _afterPhase();
      return;
    }
    phase = F4Phase.dropping;
    animCol = col;
    animRow = row;
    animPlayer = mover;
    animStartMs = DateTime.now().millisecondsSinceEpoch;
    banner = '${sideName(mover)} drops in column ${col + 1}…';
    audio.drop();
    notifyListeners();
    _arm(const Duration(milliseconds: dropDurationMs), _afterDrop);
  }

  void _afterDrop() {
    if (_disposed) return;
    animCol = -1;
    animRow = -1;
    if (engine.over) {
      phase = F4Phase.over;
      _finishMatch();
      return;
    }
    phase = F4Phase.awaitingDrop;
    banner = _turnBanner();
    notifyListeners();
    save();
    _afterPhase();
  }

  /// Bot turn: visible "thinking" narration first, then the choice runs
  /// (Hard on an isolate), then the disc drops visibly — never instantly.
  void _botTurn() {
    if (engine.over ||
        phase != F4Phase.awaitingDrop ||
        !currentIsBot ||
        paused ||
        _botBusy) {
      return;
    }
    phase = F4Phase.thinking;
    final name = sideName(engine.turn);
    banner = '$name is thinking…';
    _botBusy = true;
    notifyListeners();
    // Visible thinking beat before the brain runs, so every bot turn is
    // narrated and nothing resolves silently.
    _arm(const Duration(milliseconds: 800), () async {
      int col = -1;
      try {
        col = await Bot.choose(
          List<int>.from(engine.cells),
          engine.turn,
          difficulty,
        );
      } catch (_) {
        col = -1;
      }
      _botBusy = false;
      if (_disposed || engine.over) return;
      if (col < 0 || engine.dropRow(col) == -1) {
        // Fallback: first legal column (keeps the game unstuck no matter
        // what the search returns).
        final legal = engine.legalMoves();
        if (legal.isEmpty) {
          _finishDraw();
          return;
        }
        col = legal.first;
      }
      if (paused || phase != F4Phase.thinking) {
        // We were backgrounded mid-think: stash the choice; the watchdog
        // applies it on resume.
        _pendingBotCol = col;
        notifyListeners();
        return;
      }
      _applyDrop(col);
    });
  }

  void _finishMatch() {
    if (engine.winner >= 0) {
      final name = sideName(engine.winner);
      banner = '$name connects four — $name wins!';
      final humanWon = !isBot[engine.winner];
      if (humanWon) {
        audio.win();
      } else {
        audio.lose();
      }
      settings.recordResult(mode, engine.winner);
    } else {
      _finishDraw();
      return;
    }
    notifyListeners();
    clearSave();
  }

  void _finishDraw() {
    banner = "Board's full — it's a draw!";
    audio.lose();
    settings.recordResult(mode, -1);
    phase = F4Phase.over;
    notifyListeners();
    clearSave();
  }

  /// Undo (2 Players only, RULES.md §12): removes the last two plies (one per
  /// player) so turn order is preserved. Never after game end, never on a
  /// bot's turn, never mid-animation.
  void undo() {
    if (mode != 1 ||
        engine.over ||
        phase != F4Phase.awaitingDrop ||
        engine.history.isEmpty ||
        paused) {
      return;
    }
    audio.click();
    final n = engine.history.length >= 2 ? 2 : 1;
    for (var i = 0; i < n; i++) {
      engine.undoPly();
    }
    banner = _turnBanner();
    notifyListeners();
    save();
  }

  void clearShake() {
    shakeCol = -1;
  }

  // ------------------------------------------------------------ persistence
  Future<void> save() async {
    if (engine.over || engine.history.isEmpty) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          saveKey,
          jsonEncode({
            'engine': engine.toJson(),
            'mode': mode,
            'difficulty': difficulty,
          }));
    } catch (_) {}
  }

  static Future<void> clearSave() async {
    try {
      await (await SharedPreferences.getInstance()).remove(saveKey);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> loadSave() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(saveKey);
      if (raw == null) return null;
      final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final eng = FourInARowEngine()
        ..fromJson(Map<String, dynamic>.from(m['engine'] as Map));
      if (eng.over || eng.history.isEmpty) return null;
      return m;
    } catch (_) {
      return null;
    }
  }
}
