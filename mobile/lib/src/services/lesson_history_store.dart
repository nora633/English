import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_models.dart';

class LessonHistoryRecord {
  const LessonHistoryRecord({
    required this.id,
    required this.savedAt,
    required this.sourceLabel,
    required this.lesson,
  });

  final String id;
  final DateTime savedAt;
  final String sourceLabel;
  final DailyLesson lesson;

  factory LessonHistoryRecord.fromJson(Map<String, dynamic> json) {
    return LessonHistoryRecord(
      id: json['id']?.toString() ?? '',
      savedAt:
          DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sourceLabel: json['sourceLabel']?.toString() ?? '本地记录',
      lesson: DailyLesson.fromJson(
        json['lesson'] is Map<String, dynamic>
            ? json['lesson'] as Map<String, dynamic>
            : const {},
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'savedAt': savedAt.toIso8601String(),
      'sourceLabel': sourceLabel,
      'lesson': lesson.toJson(),
    };
  }
}

class LessonHistoryStore {
  const LessonHistoryStore({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const _itemsKey = 'lesson.history.items';

  Future<List<LessonHistoryRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeRecords(prefs.getString(_itemsKey));
  }

  Future<List<LessonHistoryRecord>> recordLesson({
    required DailyLesson lesson,
    required String sourceLabel,
  }) async {
    final existing = await load();
    final now = _now();
    final id = _idFor(lesson, now);
    final next = [
      LessonHistoryRecord(
        id: id,
        savedAt: now,
        sourceLabel: sourceLabel,
        lesson: lesson,
      ),
      for (final item in existing)
        if (item.lesson.theme.title != lesson.theme.title) item,
    ].take(40).toList();

    await _save(next);
    return load();
  }

  Future<List<Map<String, Object?>>> exportItems() async {
    final items = await load();
    return [for (final item in items) item.toJson()];
  }

  Future<void> importItems(Object? value) async {
    if (value is! List) return;

    final items = [
      for (final item in value)
        if (item is Map<String, dynamic>)
          LessonHistoryRecord.fromJson(item)
        else if (item is Map)
          LessonHistoryRecord.fromJson(Map<String, dynamic>.from(item)),
    ].where((item) => item.id.isNotEmpty).toList();

    await _save(items);
  }

  List<LessonHistoryRecord> search(
    List<LessonHistoryRecord> items,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return items;

    return items.where((item) {
      final lesson = item.lesson;
      final haystack = [
        lesson.title,
        lesson.theme.title,
        lesson.theme.focus,
        lesson.theme.sourceHint,
        ...lesson.listeningLines,
        ...lesson.targetChunks,
        ...lesson.keyWords.map((word) => word.word),
        ...lesson.keyWords.map((word) => word.meaning),
      ].join(' ').toLowerCase();
      return haystack.contains(normalized);
    }).toList();
  }

  Future<void> _save(List<LessonHistoryRecord> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _itemsKey,
      jsonEncode([for (final item in items) item.toJson()]),
    );
  }

  List<LessonHistoryRecord> _decodeRecords(String? raw) {
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>)
          LessonHistoryRecord.fromJson(item)
        else if (item is Map)
          LessonHistoryRecord.fromJson(Map<String, dynamic>.from(item)),
    ].where((item) => item.id.isNotEmpty).toList();
  }

  String _idFor(DailyLesson lesson, DateTime now) {
    return '${now.toIso8601String()}:${lesson.theme.title}';
  }
}
