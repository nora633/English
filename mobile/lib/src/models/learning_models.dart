import 'package:flutter/material.dart';

enum ContentKind {
  sitcom('情景剧', Icons.ondemand_video_outlined, '片段台词'),
  song('英文歌', Icons.music_note, '歌词摘录'),
  dailyLife('生活场景', Icons.chat_bubble_outline, '图文对话'),
  news('新闻稿', Icons.newspaper, '新闻稿'),
  article('报刊读物', Icons.article_outlined, '文章摘录');

  const ContentKind(this.label, this.icon, this.contentTitle);
  final String label;
  final IconData icon;
  final String contentTitle;

  static ContentKind fromName(String? value) {
    return ContentKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => ContentKind.dailyLife,
    );
  }
}

enum LearningStage {
  daily('日常表达'),
  media('影视歌曲'),
  news('新闻听读'),
  reading('报刊精读');

  const LearningStage(this.label);
  final String label;

  static LearningStage fromName(String? value) {
    return LearningStage.values.firstWhere(
      (stage) => stage.name == value,
      orElse: () => LearningStage.daily,
    );
  }
}

class LearningTheme {
  const LearningTheme({
    required this.title,
    required this.stage,
    required this.kind,
    required this.sourceHint,
    required this.focus,
    required this.difficulty,
    required this.previewTitle,
    required this.previewDescription,
    required this.sampleContent,
    required this.practiceSentences,
    required this.keyVocabulary,
  });

  final String title;
  final LearningStage stage;
  final ContentKind kind;
  final String sourceHint;
  final String focus;
  final String difficulty;
  final String previewTitle;
  final String previewDescription;
  final String sampleContent;
  final List<String> practiceSentences;
  final List<String> keyVocabulary;

  factory LearningTheme.fromJson(Map<String, dynamic> json) {
    return LearningTheme(
      title: json['title']?.toString() ?? '今日主题',
      stage: LearningStage.fromName(json['stage']?.toString()),
      kind: ContentKind.fromName(json['kind']?.toString()),
      sourceHint: json['sourceHint']?.toString() ?? 'AI 生成',
      focus: json['focus']?.toString() ?? '日常表达',
      difficulty: json['difficulty']?.toString() ?? 'A2-B1',
      previewTitle: json['previewTitle']?.toString() ?? '今日练习预览',
      previewDescription: json['previewDescription']?.toString() ?? '',
      sampleContent: json['sampleContent']?.toString() ?? '',
      practiceSentences: _stringList(json['practiceSentences']),
      keyVocabulary: _stringList(json['keyVocabulary']),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'stage': stage.name,
      'kind': kind.name,
      'sourceHint': sourceHint,
      'focus': focus,
      'difficulty': difficulty,
      'previewTitle': previewTitle,
      'previewDescription': previewDescription,
      'sampleContent': sampleContent,
      'practiceSentences': practiceSentences,
      'keyVocabulary': keyVocabulary,
    };
  }
}

class DailyLesson {
  const DailyLesson({
    required this.title,
    required this.durationMinutes,
    required this.completedMinutes,
    required this.theme,
    required this.keyWords,
    required this.grammarPoints,
    required this.targetChunks,
    required this.listeningLines,
  });

  final String title;
  final int durationMinutes;
  final int completedMinutes;
  final LearningTheme theme;
  final List<KeyWord> keyWords;
  final List<GrammarPoint> grammarPoints;
  final List<String> targetChunks;
  final List<String> listeningLines;

  factory DailyLesson.fromJson(Map<String, dynamic> json) {
    return DailyLesson(
      title: json['title']?.toString() ?? '今日 15 分钟听说训练',
      durationMinutes: _intValue(json['durationMinutes'], fallback: 15),
      completedMinutes: _intValue(json['completedMinutes'], fallback: 0),
      theme: LearningTheme.fromJson(
        json['theme'] is Map<String, dynamic>
            ? json['theme'] as Map<String, dynamic>
            : const {},
      ),
      keyWords: [
        for (final item in _mapList(json['keyWords'])) KeyWord.fromJson(item),
      ],
      grammarPoints: [
        for (final item in _mapList(json['grammarPoints']))
          GrammarPoint.fromJson(item),
      ],
      targetChunks: _stringList(json['targetChunks']),
      listeningLines: _stringList(json['listeningLines']),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'durationMinutes': durationMinutes,
      'completedMinutes': completedMinutes,
      'theme': theme.toJson(),
      'keyWords': [for (final word in keyWords) word.toJson()],
      'grammarPoints': [for (final point in grammarPoints) point.toJson()],
      'targetChunks': targetChunks,
      'listeningLines': listeningLines,
    };
  }

  DailyLesson copyWith({
    String? title,
    int? durationMinutes,
    int? completedMinutes,
    LearningTheme? theme,
    List<KeyWord>? keyWords,
    List<GrammarPoint>? grammarPoints,
    List<String>? targetChunks,
    List<String>? listeningLines,
  }) {
    return DailyLesson(
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      completedMinutes: completedMinutes ?? this.completedMinutes,
      theme: theme ?? this.theme,
      keyWords: keyWords ?? this.keyWords,
      grammarPoints: grammarPoints ?? this.grammarPoints,
      targetChunks: targetChunks ?? this.targetChunks,
      listeningLines: listeningLines ?? this.listeningLines,
    );
  }
}

class KeyWord {
  const KeyWord({
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.usage,
    required this.example,
    required this.priority,
    required this.wordRoot,
    required this.memoryHint,
    required this.collocations,
    required this.relatedWords,
    required this.confusingPoint,
  });

  final String word;
  final String phonetic;
  final String meaning;
  final String usage;
  final String example;
  final String priority;
  final String wordRoot;
  final String memoryHint;
  final List<String> collocations;
  final List<String> relatedWords;
  final String confusingPoint;

  factory KeyWord.fromJson(Map<String, dynamic> json) {
    return KeyWord(
      word: json['word']?.toString() ?? '',
      phonetic: json['phonetic']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      usage: json['usage']?.toString() ?? '',
      example: json['example']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '必练',
      wordRoot: json['wordRoot']?.toString() ?? '',
      memoryHint: json['memoryHint']?.toString() ?? '',
      collocations: _stringList(json['collocations']),
      relatedWords: _stringList(json['relatedWords']),
      confusingPoint: json['confusingPoint']?.toString() ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'word': word,
      'phonetic': phonetic,
      'meaning': meaning,
      'usage': usage,
      'example': example,
      'priority': priority,
      'wordRoot': wordRoot,
      'memoryHint': memoryHint,
      'collocations': collocations,
      'relatedWords': relatedWords,
      'confusingPoint': confusingPoint,
    };
  }
}

class GrammarPoint {
  const GrammarPoint({
    required this.pattern,
    required this.meaning,
    required this.example,
    required this.note,
  });

  final String pattern;
  final String meaning;
  final String example;
  final String note;

  factory GrammarPoint.fromJson(Map<String, dynamic> json) {
    return GrammarPoint(
      pattern: json['pattern']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      example: json['example']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'pattern': pattern,
      'meaning': meaning,
      'example': example,
      'note': note,
    };
  }
}

class SpeakingScore {
  const SpeakingScore({
    required this.clarity,
    required this.fluency,
    required this.completeness,
    required this.naturalness,
    required this.transcript,
    required this.suggestions,
  });

  final int clarity;
  final int fluency;
  final int completeness;
  final int naturalness;
  final String transcript;
  final List<String> suggestions;
}

class ReviewSummary {
  const ReviewSummary({
    required this.streakDays,
    required this.completedMinutes,
    required this.reusableExpression,
    required this.nextFocus,
    required this.recommendation,
  });

  final int streakDays;
  final int completedMinutes;
  final String reusableExpression;
  final String nextFocus;
  final DailyRecommendation recommendation;
}

class DailyRecommendation {
  const DailyRecommendation({
    required this.title,
    required this.stage,
    required this.difficulty,
    required this.reason,
    required this.weakFocus,
    required this.mix,
    required this.keywords,
  });

  final String title;
  final LearningStage stage;
  final String difficulty;
  final String reason;
  final String weakFocus;
  final String mix;
  final List<String> keywords;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map<String, dynamic>) item,
  ];
}

int _intValue(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ?? fallback;
}
