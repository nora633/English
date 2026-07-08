import 'dart:convert';

import 'package:http/http.dart' as http;

class ExerciseCheckResult {
  const ExerciseCheckResult({
    required this.score,
    required this.level,
    required this.summary,
    required this.reference,
    required this.correctedAnswer,
    required this.issues,
    required this.suggestions,
  });

  final int score;
  final ExerciseCheckLevel level;
  final String summary;
  final String reference;
  final String correctedAnswer;
  final List<String> issues;
  final List<String> suggestions;

  factory ExerciseCheckResult.fromJson(Map<String, dynamic> json) {
    return ExerciseCheckResult(
      score: _scoreFromJson(json['score']),
      level: ExerciseCheckLevel.fromJson(json['level']),
      summary: json['summary']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      correctedAnswer: json['correctedAnswer']?.toString() ?? '',
      issues: _stringListFromJson(json['issues']),
      suggestions: _stringListFromJson(json['suggestions']),
    );
  }
}

enum ExerciseCheckLevel {
  great('很好', 'great'),
  pass('基本正确', 'pass'),
  needsWork('需要修改', 'needs_work');

  const ExerciseCheckLevel(this.label, this.jsonValue);

  final String label;
  final String jsonValue;

  static ExerciseCheckLevel fromJson(Object? value) {
    return ExerciseCheckLevel.values.firstWhere(
      (level) => level.jsonValue == value,
      orElse: () => ExerciseCheckLevel.needsWork,
    );
  }
}

enum ExerciseCheckSource {
  ai('AI 检查'),
  local('本地检查'),
  localFallback('AI 暂不可用，已用本地检查');

  const ExerciseCheckSource(this.label);

  final String label;
}

class ExerciseCheckResponse {
  const ExerciseCheckResponse({required this.result, required this.source});

  final ExerciseCheckResult result;
  final ExerciseCheckSource source;
}

enum ExerciseCheckMode {
  dictation('/api/check-dictation'),
  recall('/api/check-recall');

  const ExerciseCheckMode(this.path);

  final String path;
}

class ExerciseCheckGateway {
  const ExerciseCheckGateway({
    this.remote = const RemoteExerciseCheckService(),
    this.local = const LocalExerciseCheckService(),
  });

  final RemoteExerciseCheckService remote;
  final LocalExerciseCheckService local;

  Future<ExerciseCheckResponse> check({
    required ExerciseCheckMode mode,
    required String target,
    required String answer,
    String prompt = '',
  }) async {
    if (remote.isConfigured) {
      try {
        final result = await remote.check(
          mode: mode,
          target: target,
          answer: answer,
          prompt: prompt,
        );
        return ExerciseCheckResponse(
          result: result,
          source: ExerciseCheckSource.ai,
        );
      } catch (_) {
        return ExerciseCheckResponse(
          result: local.check(mode: mode, target: target, answer: answer),
          source: ExerciseCheckSource.localFallback,
        );
      }
    }

    return ExerciseCheckResponse(
      result: local.check(mode: mode, target: target, answer: answer),
      source: ExerciseCheckSource.local,
    );
  }
}

class RemoteExerciseCheckService {
  const RemoteExerciseCheckService({
    this.baseUrl = const String.fromEnvironment('AI_TRANSLATION_API_BASE'),
    this.clientFactory = _defaultClientFactory,
  });

  final String baseUrl;
  final http.Client Function() clientFactory;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Future<ExerciseCheckResult> check({
    required ExerciseCheckMode mode,
    required String target,
    required String answer,
    String prompt = '',
  }) async {
    final endpoint = Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r'/$'), '')}${mode.path}',
    );
    final client = clientFactory();

    try {
      final response = await client.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'target': target,
          'answer': answer,
          'prompt': prompt,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ExerciseCheckException('练习检查接口返回 ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const ExerciseCheckException('练习检查接口返回格式不正确');
      }

      return ExerciseCheckResult.fromJson(body);
    } finally {
      client.close();
    }
  }
}

class LocalExerciseCheckService {
  const LocalExerciseCheckService();

  ExerciseCheckResult check({
    required ExerciseCheckMode mode,
    required String target,
    required String answer,
  }) {
    final normalizedTarget = _normalize(target);
    final normalizedAnswer = _normalize(answer);
    final targetWords = _words(normalizedTarget);
    final answerWords = _words(normalizedAnswer);
    final missingWords = targetWords
        .where((word) => !answerWords.contains(word))
        .toSet()
        .toList();
    final extraWords = answerWords
        .where((word) => !targetWords.contains(word))
        .toSet()
        .toList();
    final score = _score(
      targetWords,
      answerWords,
      normalizedTarget,
      normalizedAnswer,
    );
    final level = score >= 90
        ? ExerciseCheckLevel.great
        : score >= 70
        ? ExerciseCheckLevel.pass
        : ExerciseCheckLevel.needsWork;
    final modeText = mode == ExerciseCheckMode.dictation ? '听写' : '默写';

    return ExerciseCheckResult(
      score: score,
      level: level,
      summary: score >= 90
          ? '$modeText基本完整，可以进入下一步。'
          : score >= 70
          ? '$modeText大意接近，还需要补齐关键词。'
          : '$modeText差异较多，先对照参考句重练一遍。',
      reference: target,
      correctedAnswer: target,
      issues: [
        if (answer.trim().isEmpty) '还没有输入答案。',
        if (missingWords.isNotEmpty) '缺少：${missingWords.take(5).join(' / ')}',
        if (extraWords.isNotEmpty) '多写或疑似错词：${extraWords.take(5).join(' / ')}',
      ],
      suggestions: [
        if (missingWords.isEmpty && extraWords.isEmpty) '保持这个句子，下一步练连读和自然语调。',
        if (missingWords.contains('about') || missingWords.contains('to'))
          '注意 about to 是固定结构，表示“正准备”。',
        if (missingWords.contains('anything')) 'anything 是这句听写的关键，不要漏掉。',
        '再听一遍原句，先抓主干，再补介词和小词。',
      ],
    );
  }

  int _score(
    List<String> targetWords,
    List<String> answerWords,
    String target,
    String answer,
  ) {
    if (answer.isEmpty) return 0;
    if (target == answer) return 100;
    if (targetWords.isEmpty) return 0;

    final matched = targetWords.where(answerWords.contains).length;
    final extra = answerWords
        .where((word) => !targetWords.contains(word))
        .length;
    final ratio = matched / targetWords.length;
    final penalty = extra * 4;

    return (ratio * 100 - penalty).round().clamp(0, 100);
  }

  List<String> _words(String value) {
    if (value.isEmpty) return const [];
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class ExerciseCheckException implements Exception {
  const ExerciseCheckException(this.message);

  final String message;

  @override
  String toString() => message;
}

http.Client _defaultClientFactory() => http.Client();

int _scoreFromJson(Object? value) {
  final parsed = value is num ? value.round() : int.tryParse(value.toString());
  return (parsed ?? 0).clamp(0, 100);
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}
