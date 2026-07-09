import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_models.dart';

class LearningPreferences {
  const LearningPreferences({
    required this.dailyGoalMinutes,
    required this.preferredStage,
  });

  const LearningPreferences.defaults()
    : dailyGoalMinutes = 15,
      preferredStage = LearningStage.daily;

  final int dailyGoalMinutes;
  final LearningStage preferredStage;

  factory LearningPreferences.fromJson(Map<String, dynamic> json) {
    return LearningPreferences(
      dailyGoalMinutes: _goalValue(json['dailyGoalMinutes']),
      preferredStage: LearningStage.fromName(
        json['preferredStage']?.toString(),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'dailyGoalMinutes': dailyGoalMinutes,
      'preferredStage': preferredStage.name,
    };
  }

  LearningPreferences copyWith({
    int? dailyGoalMinutes,
    LearningStage? preferredStage,
  }) {
    return LearningPreferences(
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      preferredStage: preferredStage ?? this.preferredStage,
    );
  }
}

class LearningPreferencesStore {
  const LearningPreferencesStore();

  static const _key = 'learning.preferences';

  Future<LearningPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const LearningPreferences.defaults();

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const LearningPreferences.defaults();
    }

    return LearningPreferences.fromJson(decoded);
  }

  Future<LearningPreferences> save(LearningPreferences preferences) async {
    final normalized = LearningPreferences(
      dailyGoalMinutes: _goalValue(preferences.dailyGoalMinutes),
      preferredStage: preferences.preferredStage,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(normalized.toJson()));
    return normalized;
  }

  Future<Map<String, Object?>> exportItem() async {
    final preferences = await load();
    return preferences.toJson();
  }

  Future<void> importItem(Object? value) async {
    if (value is Map<String, dynamic>) {
      await save(LearningPreferences.fromJson(value));
    } else if (value is Map) {
      await save(
        LearningPreferences.fromJson(Map<String, dynamic>.from(value)),
      );
    }
  }
}

int _goalValue(Object? value) {
  final parsed = value is int ? value : int.tryParse(value.toString());
  return parsed == 10 ? 10 : 15;
}
