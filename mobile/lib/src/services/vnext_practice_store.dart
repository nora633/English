import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vnext_models.dart';

class VNextPracticeStore {
  static const currentPackKey = 'vnext.current_pack_id';

  const VNextPracticeStore({
    required this.storageKey,
    required this.sentenceCount,
  });

  final String storageKey;
  final int sentenceCount;

  Future<PracticeState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return PracticeState.initial(sentenceCount);
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return PracticeState.initial(sentenceCount);
    }
    return PracticeState.fromJson(decoded, sentenceCount);
  }

  Future<void> save(PracticeState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, encodePracticeState(state));
  }

  static Future<String?> loadCurrentPackId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(currentPackKey);
  }

  static Future<void> saveCurrentPackId(String packId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(currentPackKey, packId);
  }
}
