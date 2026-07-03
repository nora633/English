import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract class AudioPlaybackClient {
  Future<void> play(String path);

  Future<void> stop();

  Future<void> dispose();
}

class AudioPlayerService implements AudioPlaybackClient {
  AudioPlayerService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> play(String path) async {
    await _player.stop();
    await _player.play(_sourceFor(path));
  }

  @override
  Future<void> stop() {
    return _player.stop();
  }

  @override
  Future<void> dispose() {
    return _player.dispose();
  }

  Source _sourceFor(String path) {
    if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
      return UrlSource(path);
    }

    return DeviceFileSource(path);
  }
}
