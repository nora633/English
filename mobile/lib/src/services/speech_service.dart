import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class SpeechClient {
  Future<void> speak(String text, {required String locale});

  Future<void> speakLines(List<String> texts, {required String locale});

  Future<void> stop();
}

class SpeechService implements SpeechClient {
  // ignore: prefer_initializing_formals
  SpeechService({FlutterTts? engine}) : _engine = engine;

  FlutterTts? _engine;
  bool _voiceConfigured = false;

  @override
  Future<void> speak(String text, {required String locale}) async {
    if (text.trim().isEmpty) return;

    final tts = await _prepareTts(locale);
    await tts.stop();
    if (kIsWeb) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    await tts.speak(text);
  }

  @override
  Future<void> speakLines(List<String> texts, {required String locale}) async {
    final lines = texts.where((item) => item.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;

    final tts = await _prepareTts(locale);
    await tts.stop();
    if (kIsWeb) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    final combined = lines.join('. ');
    await tts.speak(combined);
  }

  @override
  Future<void> stop() async {
    await _engine?.stop();
  }

  Future<FlutterTts> _prepareTts(String locale) async {
    if (_engine == null) {
      await _engine?.stop();
      _engine = FlutterTts();
      _engine!.awaitSpeakCompletion(true);
    }
    await _configure(_engine!, locale);
    return _engine!;
  }

  Future<void> _configure(
    FlutterTts tts,
    String locale, {
    double speechRate = 0.46,
    double pitch = 1.0,
  }) async {
    await tts.setLanguage(locale);
    await _setPreferredVoice(tts, locale);
    await tts.setVolume(1);
    await tts.setSpeechRate(speechRate);
    await tts.setPitch(pitch);
  }

  Future<void> _setPreferredVoice(FlutterTts tts, String locale) async {
    if (!kIsWeb || _voiceConfigured) return;
    _voiceConfigured = true;
    try {
      final rawVoices = await tts.getVoices;
      if (rawVoices is! List) return;
      final voices = rawVoices.whereType<Map>().toList();
      if (voices.isEmpty) return;
      final preferred = voices.cast<Map>().firstWhere(
        (voice) {
          final name = voice['name']?.toString().toLowerCase() ?? '';
          final voiceLocale = voice['locale']?.toString() ?? '';
          return voiceLocale == locale &&
              (name.contains('google us english') ||
                  name.contains('samantha') ||
                  name.contains('alex'));
        },
        orElse: () => voices.firstWhere(
          (voice) => voice['locale']?.toString() == locale,
          orElse: () => voices.first,
        ),
      );
      final name = preferred['name']?.toString();
      final voiceLocale = preferred['locale']?.toString();
      if (name == null || voiceLocale == null) return;
      await tts.setVoice({'name': name, 'locale': voiceLocale});
    } catch (_) {
      // Browser voice lists are inconsistent; default TTS remains usable.
    }
  }
}
