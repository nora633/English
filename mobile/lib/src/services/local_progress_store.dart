import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalProgress {
  const LocalProgress({
    required this.recordingCompleted,
    required this.dictationCompleted,
    required this.recallCompleted,
  });

  const LocalProgress.empty()
    : recordingCompleted = false,
      dictationCompleted = false,
      recallCompleted = false;

  final bool recordingCompleted;
  final bool dictationCompleted;
  final bool recallCompleted;

  int get completedMinutes {
    return (recordingCompleted ? 5 : 0) +
        (dictationCompleted ? 5 : 0) +
        (recallCompleted ? 5 : 0);
  }

  LocalProgress copyWith({
    bool? recordingCompleted,
    bool? dictationCompleted,
    bool? recallCompleted,
  }) {
    return LocalProgress(
      recordingCompleted: recordingCompleted ?? this.recordingCompleted,
      dictationCompleted: dictationCompleted ?? this.dictationCompleted,
      recallCompleted: recallCompleted ?? this.recallCompleted,
    );
  }
}

class DailyHistoryRecord {
  const DailyHistoryRecord({
    required this.date,
    required this.completedMinutes,
    required this.completed,
  });

  final String date;
  final int completedMinutes;
  final bool completed;
}

class LocalLearningStats {
  const LocalLearningStats({
    required this.streakDays,
    required this.totalMinutes,
    required this.history,
    required this.savedTroubleSpots,
  });

  const LocalLearningStats.empty()
    : streakDays = 0,
      totalMinutes = 0,
      history = const [],
      savedTroubleSpots = const [];

  final int streakDays;
  final int totalMinutes;
  final List<DailyHistoryRecord> history;
  final List<String> savedTroubleSpots;
}

class LocalProgressStore {
  const LocalProgressStore({DateTime Function()? today})
    : _today = today ?? DateTime.now;

  final DateTime Function() _today;

  String get dateKey {
    final now = _today();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  String get _recordingKey => 'daily.$dateKey.recordingCompleted';
  String get _dictationKey => 'daily.$dateKey.dictationCompleted';
  String get _recallKey => 'daily.$dateKey.recallCompleted';
  String get _completedDateKey => 'daily.$dateKey.completed';
  String get _minutesKey => 'daily.$dateKey.minutes';
  String get _troubleSpotsKey => 'daily.$dateKey.troubleSpots';

  static const _historyDatesKey = 'daily.historyDates';

  Future<LocalProgress> load() async {
    final prefs = await SharedPreferences.getInstance();

    return LocalProgress(
      recordingCompleted: prefs.getBool(_recordingKey) ?? false,
      dictationCompleted: prefs.getBool(_dictationKey) ?? false,
      recallCompleted: prefs.getBool(_recallKey) ?? false,
    );
  }

  Future<void> save(LocalProgress progress, {int targetMinutes = 15}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_recordingKey, progress.recordingCompleted);
    await prefs.setBool(_dictationKey, progress.dictationCompleted);
    await prefs.setBool(_recallKey, progress.recallCompleted);
    await prefs.setBool(
      _completedDateKey,
      progress.completedMinutes >= targetMinutes,
    );
    await prefs.setInt(_minutesKey, progress.completedMinutes);

    if (progress.completedMinutes > 0) {
      await _rememberDate(prefs, dateKey);
    }

    final troubleSpots = <String>[
      if (progress.dictationCompleted) ...['anything', 'downstairs'],
      if (progress.recallCompleted)
        'Do you want me to text you when I get there?',
    ];
    await prefs.setStringList(_troubleSpotsKey, troubleSpots);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_recordingKey);
    await prefs.remove(_dictationKey);
    await prefs.remove(_recallKey);
    await prefs.remove(_completedDateKey);
    await prefs.remove(_minutesKey);
    await prefs.remove(_troubleSpotsKey);
  }

  Future<String> exportBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final dates = prefs.getStringList(_historyDatesKey) ?? const [];
    final exportDates = <String>{...dates, dateKey}.toList()..sort();

    final daily = <String, Map<String, Object?>>{
      for (final date in exportDates)
        date: {
          'recordingCompleted':
              prefs.getBool('daily.$date.recordingCompleted') ?? false,
          'dictationCompleted':
              prefs.getBool('daily.$date.dictationCompleted') ?? false,
          'recallCompleted':
              prefs.getBool('daily.$date.recallCompleted') ?? false,
          'completed': prefs.getBool('daily.$date.completed') ?? false,
          'minutes': prefs.getInt('daily.$date.minutes') ?? 0,
          'troubleSpots':
              prefs.getStringList('daily.$date.troubleSpots') ?? const [],
        },
    };

    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'historyDates': exportDates,
      'daily': daily,
    });
  }

  Future<void> importBackup(String backupText) async {
    final decoded = jsonDecode(backupText.trim());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('备份内容格式不正确。');
    }

    final daily = decoded['daily'];
    if (daily is! Map<String, dynamic>) {
      throw const FormatException('备份内容缺少学习记录。');
    }

    final prefs = await SharedPreferences.getInstance();
    final historyDates = <String>[];

    for (final entry in daily.entries) {
      final date = entry.key;
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;

      await prefs.setBool(
        'daily.$date.recordingCompleted',
        value['recordingCompleted'] == true,
      );
      await prefs.setBool(
        'daily.$date.dictationCompleted',
        value['dictationCompleted'] == true,
      );
      await prefs.setBool(
        'daily.$date.recallCompleted',
        value['recallCompleted'] == true,
      );
      await prefs.setBool('daily.$date.completed', value['completed'] == true);
      await prefs.setInt(
        'daily.$date.minutes',
        value['minutes'] is int ? value['minutes'] as int : 0,
      );

      final troubleSpots = value['troubleSpots'];
      await prefs.setStringList(
        'daily.$date.troubleSpots',
        troubleSpots is List
            ? troubleSpots.whereType<String>().toList()
            : const [],
      );

      if ((value['minutes'] is int && (value['minutes'] as int) > 0) ||
          value['completed'] == true) {
        historyDates.add(date);
      }
    }

    historyDates.sort();
    await prefs.setStringList(_historyDatesKey, historyDates);
  }

  Future<LocalLearningStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final dates = prefs.getStringList(_historyDatesKey) ?? const [];
    final sortedDates = [...dates]..sort((a, b) => b.compareTo(a));
    final history = [
      for (final date in sortedDates.take(7))
        DailyHistoryRecord(
          date: date,
          completedMinutes: prefs.getInt('daily.$date.minutes') ?? 0,
          completed: prefs.getBool('daily.$date.completed') ?? false,
        ),
    ];
    final totalMinutes = dates.fold<int>(
      0,
      (sum, date) => sum + (prefs.getInt('daily.$date.minutes') ?? 0),
    );
    final savedTroubleSpots = <String>{
      for (final date in sortedDates.take(7))
        ...(prefs.getStringList('daily.$date.troubleSpots') ?? const []),
    }.toList();

    final completedDates = {
      for (final date in dates)
        if (prefs.getBool('daily.$date.completed') == true) date,
    };

    return LocalLearningStats(
      streakDays: _calculateStreak(completedDates),
      totalMinutes: totalMinutes,
      history: history,
      savedTroubleSpots: savedTroubleSpots,
    );
  }

  Future<void> _rememberDate(SharedPreferences prefs, String date) async {
    final dates = prefs.getStringList(_historyDatesKey) ?? const [];
    if (dates.contains(date)) return;

    await prefs.setStringList(_historyDatesKey, [...dates, date]);
  }

  int _calculateStreak(Set<String> dates) {
    var cursor = _today();
    var streak = 0;

    while (dates.contains(_formatDate(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }
}
