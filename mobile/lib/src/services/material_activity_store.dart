import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_models.dart';

class MaterialUsageRecord {
  const MaterialUsageRecord({
    required this.themeTitle,
    required this.stage,
    required this.kind,
    required this.usedAt,
  });

  final String themeTitle;
  final LearningStage stage;
  final ContentKind kind;
  final DateTime usedAt;

  factory MaterialUsageRecord.fromJson(Map<String, dynamic> json) {
    return MaterialUsageRecord(
      themeTitle: json['themeTitle']?.toString() ?? '',
      stage: LearningStage.fromName(json['stage']?.toString()),
      kind: ContentKind.fromName(json['kind']?.toString()),
      usedAt:
          DateTime.tryParse(json['usedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'themeTitle': themeTitle,
      'stage': stage.name,
      'kind': kind.name,
      'usedAt': usedAt.toIso8601String(),
    };
  }
}

class MaterialActivityState {
  const MaterialActivityState({
    required this.favoriteTitles,
    required this.history,
  });

  const MaterialActivityState.empty()
    : favoriteTitles = const [],
      history = const [];

  final List<String> favoriteTitles;
  final List<MaterialUsageRecord> history;

  bool isFavorite(LearningTheme theme) => favoriteTitles.contains(theme.title);

  bool wasUsed(LearningTheme theme) {
    return history.any((record) => record.themeTitle == theme.title);
  }

  List<String> recentUsedTitles({int limit = 3}) {
    return [for (final record in history.take(limit)) record.themeTitle];
  }

  int useCount(LearningTheme theme) {
    return history.where((record) => record.themeTitle == theme.title).length;
  }
}

class MaterialActivityStore {
  const MaterialActivityStore({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const _favoriteTitlesKey = 'materials.favoriteTitles';
  static const _historyKey = 'materials.usageHistory';

  Future<MaterialActivityState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoriteTitlesKey) ?? const [];
    final rawHistory = prefs.getString(_historyKey);

    return MaterialActivityState(
      favoriteTitles: favorites,
      history: _decodeHistory(rawHistory),
    );
  }

  Future<MaterialActivityState> toggleFavorite(LearningTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = <String>[
      ...(prefs.getStringList(_favoriteTitlesKey) ?? const <String>[]),
    ];

    if (favorites.contains(theme.title)) {
      favorites.remove(theme.title);
    } else {
      favorites.add(theme.title);
    }

    await prefs.setStringList(_favoriteTitlesKey, favorites);
    return load();
  }

  Future<MaterialActivityState> recordUse(LearningTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    final history = [
      MaterialUsageRecord(
        themeTitle: theme.title,
        stage: theme.stage,
        kind: theme.kind,
        usedAt: _now(),
      ),
      ..._decodeHistory(prefs.getString(_historyKey)),
    ].take(20).toList();

    await prefs.setString(
      _historyKey,
      jsonEncode([for (final record in history) record.toJson()]),
    );
    return load();
  }

  List<MaterialUsageRecord> _decodeHistory(String? raw) {
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>)
          MaterialUsageRecord.fromJson(item)
        else if (item is Map)
          MaterialUsageRecord.fromJson(Map<String, dynamic>.from(item)),
    ].where((record) => record.themeTitle.isNotEmpty).toList();
  }
}
