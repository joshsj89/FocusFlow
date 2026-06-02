import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

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
    // Update track immediately so the UI reflects the selection at once,
    // rather than waiting for all the async audio operations to finish.
    _currentTrack = track;
    notifyListeners();
    try {
      await _player.stop();
      await _player.setAsset(track.assetKey);
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
      notifyListeners();
    } catch (_) {
      _currentTrack = null;
      notifyListeners();
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
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
