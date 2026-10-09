import "package:audioplayers/audioplayers.dart";

import "settings.dart";

/// Central audio for Four in a Row: synthesized arcade SFX + looping music.
/// All sounds are generated programmatically (tools/gen_audio.py) — no
/// external assets. Toggles and volumes actually take effect.
class F4Audio {
  F4Audio._();
  static final F4Audio instance = F4Audio._();

  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  bool _ready = false;
  String? _currentTrack;

  Future<void> init() async {
    if (_ready) return;
    await _music.setReleaseMode(ReleaseMode.loop);
    _ready = true;
  }

  void _applyVolumes() {
    final s = F4Settings.instance;
    _music.setVolume((s.masterVol * s.musicVol * 0.7).clamp(0.0, 1.0));
  }

  Future<void> playMusic(String asset) async {
    if (!_ready) return;
    final s = F4Settings.instance;
    if (!s.musicOn) return;
    if (_currentTrack == asset) return;
    _currentTrack = asset;
    try {
      _applyVolumes();
      await _music.play(AssetSource(asset));
    } catch (_) {
      _currentTrack = null;
    }
  }

  Future<void> stopMusic() async {
    _currentTrack = null;
    try {
      await _music.stop();
    } catch (_) {}
  }

  /// Re-apply toggle/volume state (call after settings change).
  Future<void> refresh() async {
    final s = F4Settings.instance;
    if (!s.musicOn) {
      await stopMusic();
    } else {
      _applyVolumes();
      if (_currentTrack != null) {
        final t = _currentTrack!;
        _currentTrack = null;
        await playMusic(t);
      }
    }
  }

  Future<void> _play(String asset, {double vol = 1.0}) async {
    if (!_ready) return;
    final s = F4Settings.instance;
    if (!s.sfxOn) return;
    try {
      await _sfx.setVolume((s.masterVol * vol).clamp(0.0, 1.0));
      await _sfx.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> click() => _play('audio/click.wav');
  Future<void> drop() => _play('audio/drop.wav');
  Future<void> start() => _play('audio/start.wav');
  Future<void> win() => _play('audio/win.wav');
  Future<void> lose() => _play('audio/lose.wav');
  Future<void> invalid() => _play('audio/invalid.wav', vol: 0.7);

  void dispose() {
    _sfx.dispose();
    _music.dispose();
  }
}
