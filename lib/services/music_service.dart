import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackInfo {
  final String assetKey;
  final String displayName;

  const TrackInfo({required this.assetKey, required this.displayName});
}

class MusicService extends ChangeNotifier {
  static final MusicService _instance = MusicService._();
  static MusicService get instance => _instance;
  MusicService._();

  final AudioPlayer _player = AudioPlayer();
  TrackInfo? _currentTrack;
  List<TrackInfo> _tracks = [];
  bool _tracksLoaded = false;
  int _playGeneration = 0; // incremented on each play() call; lets concurrent calls bail out
  static const _kPrefKey = 'focusflow_last_track';

  TrackInfo? get currentTrack => _currentTrack;
  bool get isPlaying => _player.playing;
  List<TrackInfo> get tracks => _tracks;

  // Human-readable names for known files. Any file not listed here falls back
  // to the cleaned-up filename.
  static const _kDisplayNames = {
    'dragon-studio-soothing-ocean-waves-372489.mp3': 'Ocean Waves',
    'freesound_community-waves-53479.mp3': 'Gentle Waves',
    'vibehorn-motivational-jazz-beat-479216.mp3': 'Jazz Beat',
    'u_iof4lbuflq-jazz-cafe-crowd-319309.mp3': 'Jazz Café',
    'liecio-calming-rain-257596.mp3': 'Calming Rain',
    'mdjahidhossain-birds-nature-relax-sounds-110839.mp3': 'Birds & Nature',
  };

  static String _toDisplayName(String assetKey) {
    final filename = assetKey.split('/').last;
    if (_kDisplayNames.containsKey(filename)) return _kDisplayNames[filename]!;
    // Fallback: strip numbers and clean up the filename
    final noExt = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    return noExt
        .replaceAll(RegExp(r'[-_]?\d+'), '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Call once after runApp() to restore the track the user last selected.
  /// Loads the track list if needed, then restores the visual selection.
  /// Does NOT auto-play — the timer start will resume playback.
  Future<void> restoreLastTrack() async {
    await loadTracks();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_kPrefKey);
      if (savedKey == null) return;
      final match =
          _tracks.where((t) => t.assetKey == savedKey).firstOrNull;
      if (match != null) {
        _currentTrack = match;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<List<TrackInfo>> loadTracks() async {
    if (_tracksLoaded) return _tracks;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final keys = manifest
          .listAssets()
          .where((k) =>
              k.startsWith('assets/music/') &&
              (k.endsWith('.mp3') ||
                  k.endsWith('.m4a') ||
                  k.endsWith('.wav') ||
                  k.endsWith('.ogg') ||
                  k.endsWith('.aac') ||
                  k.endsWith('.flac')))
          .toList()
        ..sort();
      _tracks = keys
          .map((k) => TrackInfo(assetKey: k, displayName: _toDisplayName(k)))
          .toList();
      _tracksLoaded = true;
    } catch (_) {
      _tracks = [];
      _tracksLoaded = true;
    }
    return _tracks;
  }

  Future<void> play(TrackInfo track) async {
    // Update track immediately so the UI reflects the selection at once.
    _currentTrack = track;
    notifyListeners();

    // Generation counter: if a newer play() call starts while we're mid-load,
    // we bail out after each await so the latest call always wins cleanly.
    final generation = ++_playGeneration;

    try {
      await _player.stop();
      if (generation != _playGeneration) return;

      await _player.setAsset(track.assetKey);
      if (generation != _playGeneration) return;

      await _player.setLoopMode(LoopMode.one);
      if (generation != _playGeneration) return;

      await _player.play();
      if (generation != _playGeneration) return;

      notifyListeners();
      // Persist so the selection survives a cold restart
      SharedPreferences.getInstance()
          .then((p) => p.setString(_kPrefKey, track.assetKey))
          .catchError((_) => false);
    } catch (_) {
      if (generation == _playGeneration) {
        _currentTrack = null;
        notifyListeners();
      }
    }
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentTrack = null;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.remove(_kPrefKey))
        .catchError((_) => false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
