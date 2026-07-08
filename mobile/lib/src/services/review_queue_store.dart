import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_models.dart';

enum ReviewItemKind {
  keyword('词汇'),
  chunk('词块'),
  sentence('句子');

  const ReviewItemKind(this.label);

  final String label;

  static ReviewItemKind fromName(String? value) {
    return ReviewItemKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => ReviewItemKind.chunk,
    );
  }
}

class ReviewQueueItem {
  const ReviewQueueItem({
    required this.id,
    required this.text,
    required this.kind,
    required this.themeTitle,
    required this.note,
    required this.createdAt,
    required this.reviewCount,
    required this.mastered,
  });

  final String id;
  final String text;
  final ReviewItemKind kind;
  final String themeTitle;
  final String note;
  final DateTime createdAt;
  final int reviewCount;
  final bool mastered;

  factory ReviewQueueItem.fromJson(Map<String, dynamic> json) {
    return ReviewQueueItem(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      kind: ReviewItemKind.fromName(json['kind']?.toString()),
      themeTitle: json['themeTitle']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      reviewCount: _intValue(json['reviewCount']),
      mastered: json['mastered'] == true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'text': text,
      'kind': kind.name,
      'themeTitle': themeTitle,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'reviewCount': reviewCount,
      'mastered': mastered,
    };
  }

  ReviewQueueItem copyWith({int? reviewCount, bool? mastered}) {
    return ReviewQueueItem(
      id: id,
      text: text,
      kind: kind,
      themeTitle: themeTitle,
      note: note,
      createdAt: createdAt,
      reviewCount: reviewCount ?? this.reviewCount,
      mastered: mastered ?? this.mastered,
    );
  }
}

class ReviewQueueStore {
  const ReviewQueueStore({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const _itemsKey = 'review.queue.items';

  Future<List<ReviewQueueItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeItems(prefs.getString(_itemsKey));
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
          ReviewQueueItem.fromJson(item)
        else if (item is Map)
          ReviewQueueItem.fromJson(Map<String, dynamic>.from(item)),
    ].where((item) => item.id.isNotEmpty && item.text.isNotEmpty).toList();

    await _save(items);
  }

  Future<List<ReviewQueueItem>> addLesson(DailyLesson lesson) async {
    final existing = await load();
    final byId = {for (final item in existing) item.id: item};
    final now = _now();

    for (final item in _itemsForLesson(lesson, now)) {
      byId[item.id] = byId[item.id] ?? item;
    }

    final next = byId.values.toList()
      ..sort((a, b) {
        if (a.mastered != b.mastered) return a.mastered ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });
    await _save(next.take(80).toList());
    return load();
  }

  Future<List<ReviewQueueItem>> markMastered(String id) async {
    final items = await load();
    final next = [
      for (final item in items)
        if (item.id == id)
          item.copyWith(mastered: true, reviewCount: item.reviewCount + 1)
        else
          item,
    ];
    await _save(next);
    return load();
  }

  List<ReviewQueueItem> search(List<ReviewQueueItem> items, String query) {
    final normalized = query.trim().toLowerCase();
    final visible = items.where((item) => !item.mastered).toList();
    if (normalized.isEmpty) return visible;

    return visible.where((item) {
      return item.text.toLowerCase().contains(normalized) ||
          item.themeTitle.toLowerCase().contains(normalized) ||
          item.note.toLowerCase().contains(normalized) ||
          item.kind.label.toLowerCase().contains(normalized);
    }).toList();
  }

  List<ReviewQueueItem> _itemsForLesson(DailyLesson lesson, DateTime now) {
    return [
      for (final word in lesson.keyWords.take(4))
        ReviewQueueItem(
          id: _idFor(ReviewItemKind.keyword, word.word, lesson.theme.title),
          text: word.word,
          kind: ReviewItemKind.keyword,
          themeTitle: lesson.theme.title,
          note: word.meaning,
          createdAt: now,
          reviewCount: 0,
          mastered: false,
        ),
      for (final chunk in lesson.targetChunks.take(3))
        ReviewQueueItem(
          id: _idFor(ReviewItemKind.chunk, chunk, lesson.theme.title),
          text: chunk,
          kind: ReviewItemKind.chunk,
          themeTitle: lesson.theme.title,
          note: '今日目标词块',
          createdAt: now,
          reviewCount: 0,
          mastered: false,
        ),
      if (lesson.listeningLines.isNotEmpty)
        ReviewQueueItem(
          id: _idFor(
            ReviewItemKind.sentence,
            lesson.listeningLines.first,
            lesson.theme.title,
          ),
          text: lesson.listeningLines.first,
          kind: ReviewItemKind.sentence,
          themeTitle: lesson.theme.title,
          note: '今日精听句',
          createdAt: now,
          reviewCount: 0,
          mastered: false,
        ),
    ];
  }

  Future<void> _save(List<ReviewQueueItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _itemsKey,
      jsonEncode([for (final item in items) item.toJson()]),
    );
  }

  List<ReviewQueueItem> _decodeItems(String? raw) {
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>)
          ReviewQueueItem.fromJson(item)
        else if (item is Map)
          ReviewQueueItem.fromJson(Map<String, dynamic>.from(item)),
    ].where((item) => item.id.isNotEmpty && item.text.isNotEmpty).toList();
  }

  String _idFor(ReviewItemKind kind, String text, String themeTitle) {
    return '${kind.name}:${themeTitle.trim().toLowerCase()}:${text.trim().toLowerCase()}';
  }
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}
