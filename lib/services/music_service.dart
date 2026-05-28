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

  static String _toDisplayName(String assetKey) {
    final filename = assetKey.split('/').last;
    final noExt = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    return noExt
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
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
    try {
      if (_currentTrack?.assetKey != track.assetKey) {
        await _player.stop();
        await _player.setAsset(track.assetKey);
        await _player.setLoopMode(LoopMode.one);
      }
      await _player.play();
      _currentTrack = track;
      notifyListeners();
    } catch (_) {}
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
