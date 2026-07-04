import 'package:flutter_tts/flutter_tts.dart';

abstract class SpeechClient {
  Future<void> speak(String text, {required String locale});

  Future<void> stop();
}

class SpeechService implements SpeechClient {
  SpeechService({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _tts.awaitSpeakCompletion(true);
  }

  final FlutterTts _tts;

  @override
  Future<void> speak(String text, {required String locale}) async {
    if (text.trim().isEmpty) return;

    await _tts.stop();
    await _tts.setLanguage(locale);
    await _tts.setVolume(1);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() {
    return _tts.stop();
  }
}
