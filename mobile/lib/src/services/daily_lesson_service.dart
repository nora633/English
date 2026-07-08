import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../models/learning_models.dart';
import 'local_progress_store.dart';
import 'material_activity_store.dart';

class DailyLessonResponse {
  const DailyLessonResponse({required this.lesson, required this.source});

  final DailyLesson lesson;
  final DailyLessonSource source;
}

enum DailyLessonSource {
  ai('AI 生成'),
  local('本地推荐'),
  localFallback('AI 暂不可用，已用本地推荐'),
  cached('今日已保存');

  const DailyLessonSource(this.label);

  final String label;
}

class DailyLessonGateway {
  const DailyLessonGateway({
    this.remote = const RemoteDailyLessonService(),
    this.local = const LocalDailyLessonService(),
  });

  final RemoteDailyLessonService remote;
  final LocalDailyLessonService local;

  Future<DailyLessonResponse> generate({
    required LocalLearningStats stats,
    MaterialActivityState materialState = const MaterialActivityState.empty(),
    List<LearningTheme> availableThemes = SampleData.themes,
    LearningStage preferredStage = LearningStage.daily,
  }) async {
    if (remote.isConfigured) {
      try {
        final lesson = await remote.generate(
          stats: stats,
          materialState: materialState,
          availableThemes: availableThemes,
          preferredStage: preferredStage,
        );
        return DailyLessonResponse(
          lesson: lesson,
          source: DailyLessonSource.ai,
        );
      } catch (_) {
        return DailyLessonResponse(
          lesson: local.generate(
            stats: stats,
            materialState: materialState,
            availableThemes: availableThemes,
            preferredStage: preferredStage,
          ),
          source: DailyLessonSource.localFallback,
        );
      }
    }

    return DailyLessonResponse(
      lesson: local.generate(
        stats: stats,
        materialState: materialState,
        availableThemes: availableThemes,
        preferredStage: preferredStage,
      ),
      source: DailyLessonSource.local,
    );
  }
}

class RemoteDailyLessonService {
  const RemoteDailyLessonService({
    this.baseUrl = const String.fromEnvironment('AI_TRANSLATION_API_BASE'),
    this.clientFactory = _defaultClientFactory,
  });

  final String baseUrl;
  final http.Client Function() clientFactory;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Future<DailyLesson> generate({
    required LocalLearningStats stats,
    MaterialActivityState materialState = const MaterialActivityState.empty(),
    List<LearningTheme> availableThemes = SampleData.themes,
    required LearningStage preferredStage,
  }) async {
    final endpoint = Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/generate-daily-lesson',
    );
    final client = clientFactory();

    try {
      final response = await client.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'preferredStage': preferredStage.name,
          'durationMinutes': 15,
          'troubleSpots': stats.savedTroubleSpots,
          'recentHistory': [
            for (final record in stats.history)
              {
                'date': record.date,
                'completedMinutes': record.completedMinutes,
                'completed': record.completed,
              },
          ],
          'favoriteMaterials': materialState.favoriteTitles,
          'recentMaterials': materialState.recentUsedTitles(limit: 5),
          'availableMaterials': [
            for (final theme in availableThemes)
              {
                'title': theme.title,
                'stage': theme.stage.name,
                'kind': theme.kind.name,
                'sourceHint': theme.sourceHint,
                'focus': theme.focus,
              },
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DailyLessonException('每日练习接口返回 ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const DailyLessonException('每日练习接口返回格式不正确');
      }

      return _normalizeLesson(DailyLesson.fromJson(body));
    } finally {
      client.close();
    }
  }
}

class LocalDailyLessonService {
  const LocalDailyLessonService();

  DailyLesson generate({
    required LocalLearningStats stats,
    MaterialActivityState materialState = const MaterialActivityState.empty(),
    List<LearningTheme> availableThemes = SampleData.themes,
    required LearningStage preferredStage,
  }) {
    if (stats.savedTroubleSpots.contains('anything') &&
        materialState.history.isEmpty) {
      return SampleData.lessonForTheme(SampleData.themes.first);
    }

    final theme = _pickTheme(
      preferredStage: preferredStage,
      materialState: materialState,
      availableThemes: availableThemes,
    );

    return generateFromTheme(theme);
  }

  DailyLesson generateFromTheme(LearningTheme theme) {
    return SampleData.lessonForTheme(theme);
  }

  LearningTheme _pickTheme({
    required LearningStage preferredStage,
    required MaterialActivityState materialState,
    required List<LearningTheme> availableThemes,
  }) {
    final themes = availableThemes.isEmpty
        ? SampleData.themes
        : availableThemes;
    final stageThemes = themes
        .where((item) => item.stage == preferredStage)
        .toList();
    final candidates = stageThemes.isEmpty ? themes : stageThemes;
    final recentTitles = materialState.recentUsedTitles().toSet();
    final fresh = candidates
        .where((theme) => !recentTitles.contains(theme.title))
        .toList();
    final pool = fresh.isEmpty ? candidates : fresh;
    final favoritePool = pool
        .where((theme) => materialState.isFavorite(theme))
        .toList();
    final ranked = favoritePool.isEmpty ? pool : favoritePool;
    final sorted = [...ranked]
      ..sort((a, b) {
        final useComparison = materialState
            .useCount(a)
            .compareTo(materialState.useCount(b));
        if (useComparison != 0) return useComparison;
        return candidates.indexOf(a).compareTo(candidates.indexOf(b));
      });

    return sorted.first;
  }
}

class DailyLessonStore {
  const DailyLessonStore({DateTime Function()? today})
    : _today = today ?? DateTime.now;

  final DateTime Function() _today;

  String get dateKey {
    final now = _today();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  String get _lessonKey => 'daily.$dateKey.lesson';
  String get _sourceKey => 'daily.$dateKey.lessonSource';

  Future<DailyLessonResponse?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lessonKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    return DailyLessonResponse(
      lesson: _normalizeLesson(DailyLesson.fromJson(decoded)),
      source: DailyLessonSource.cached,
    );
  }

  Future<void> save(DailyLessonResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lessonKey, jsonEncode(response.lesson.toJson()));
    await prefs.setString(_sourceKey, response.source.name);
  }
}

class DailyLessonException implements Exception {
  const DailyLessonException(this.message);

  final String message;

  @override
  String toString() => message;
}

http.Client _defaultClientFactory() => http.Client();

DailyLesson _normalizeLesson(DailyLesson lesson) {
  if (lesson.listeningLines.length >= 5 &&
      lesson.keyWords.isNotEmpty &&
      lesson.grammarPoints.isNotEmpty &&
      lesson.targetChunks.isNotEmpty) {
    return lesson;
  }

  return SampleData.todayLesson.copyWith(
    title: lesson.title.isEmpty ? SampleData.todayLesson.title : lesson.title,
    theme: lesson.theme,
    listeningLines: lesson.listeningLines.isEmpty
        ? SampleData.todayLesson.listeningLines
        : lesson.listeningLines,
    keyWords: lesson.keyWords.isEmpty
        ? SampleData.todayLesson.keyWords
        : lesson.keyWords,
    grammarPoints: lesson.grammarPoints.isEmpty
        ? SampleData.todayLesson.grammarPoints
        : lesson.grammarPoints,
    targetChunks: lesson.targetChunks.isEmpty
        ? SampleData.todayLesson.targetChunks
        : lesson.targetChunks,
  );
}
