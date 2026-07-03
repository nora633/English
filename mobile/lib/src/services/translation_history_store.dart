import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'translation_service.dart';

class TranslationHistoryItem {
  const TranslationHistoryItem({required this.result, required this.savedAt});

  final TranslationResult result;
  final String savedAt;
}

class TranslationHistoryStore {
  const TranslationHistoryStore();

  static const _key = 'translation.history';
  static const _maxItems = 12;

  Future<List<TranslationHistoryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_key) ?? const [];

    return [
      for (final raw in rawItems)
        if (_decodeItem(raw) != null) _decodeItem(raw)!,
    ];
  }

  Future<void> save(TranslationResult result) async {
    if (result.source.trim().isEmpty) return;

    final current = await load();
    final deduped = current
        .where((item) => item.result.source != result.source)
        .toList();
    final next = [
      TranslationHistoryItem(
        result: result,
        savedAt: DateTime.now().toIso8601String(),
      ),
      ...deduped,
    ].take(_maxItems).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [
      for (final item in next) jsonEncode(_encodeItem(item)),
    ]);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  TranslationHistoryItem? _decodeItem(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      return TranslationHistoryItem(
        savedAt: decoded['savedAt']?.toString() ?? '',
        result: TranslationResult(
          source: decoded['source']?.toString() ?? '',
          english: decoded['english']?.toString() ?? '',
          koreanHonorific: decoded['koreanHonorific']?.toString() ?? '',
          koreanCasual: decoded['koreanCasual']?.toString() ?? '',
          koreanPronunciation: decoded['koreanPronunciation']?.toString() ?? '',
          usageNote: decoded['usageNote']?.toString() ?? '',
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _encodeItem(TranslationHistoryItem item) {
    final result = item.result;

    return {
      'savedAt': item.savedAt,
      'source': result.source,
      'english': result.english,
      'koreanHonorific': result.koreanHonorific,
      'koreanCasual': result.koreanCasual,
      'koreanPronunciation': result.koreanPronunciation,
      'usageNote': result.usageNote,
    };
  }
}
