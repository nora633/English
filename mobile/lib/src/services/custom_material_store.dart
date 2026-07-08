import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_models.dart';

class CustomMaterialStore {
  const CustomMaterialStore();

  static const _themesKey = 'materials.customThemes';

  Future<List<LearningTheme>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themesKey);
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>)
          LearningTheme.fromJson(item)
        else if (item is Map)
          LearningTheme.fromJson(Map<String, dynamic>.from(item)),
    ].where((theme) => theme.sampleContent.trim().isNotEmpty).toList();
  }

  Future<List<LearningTheme>> save(LearningTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await load();
    final next = [
      theme,
      for (final item in existing)
        if (item.title != theme.title) item,
    ].take(20).toList();

    await prefs.setString(
      _themesKey,
      jsonEncode([for (final item in next) item.toJson()]),
    );
    return next;
  }
}
