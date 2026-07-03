import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingSession {
  const RecordingSession({required this.path});

  final String path;
}

abstract class RecordingClient {
  Future<void> start();

  Future<RecordingSession?> stop();

  Future<void> dispose();
}

class AudioRecorderService implements RecordingClient {
  AudioRecorderService({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  @override
  Future<void> start() async {
    final granted = await hasPermission();
    if (!granted) {
      throw const AudioRecorderException('需要麦克风权限后才能录音。');
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: await _recordingPath(),
    );
  }

  @override
  Future<RecordingSession?> stop() async {
    final path = await _recorder.stop();
    if (path == null || path.isEmpty) return null;

    return RecordingSession(path: path);
  }

  @override
  Future<void> dispose() {
    return _recorder.dispose();
  }

  Future<String> _recordingPath() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (kIsWeb) return 'speaking-practice-$timestamp.m4a';

    final directory = await getTemporaryDirectory();
    return '${directory.path}/speaking-practice-$timestamp.m4a';
  }
}

class AudioRecorderException implements Exception {
  const AudioRecorderException(this.message);

  final String message;

  @override
  String toString() => message;
}
