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
}

enum LearningStage {
  daily('日常表达'),
  media('影视歌曲'),
  news('新闻听读'),
  reading('报刊精读');

  const LearningStage(this.label);
  final String label;
}

class LearningTheme {
  const LearningTheme({
    required this.title,
    required this.stage,
    required this.kind,
    required this.sourceHint,
    required this.focus,
    required this.difficulty,
  });

  final String title;
  final LearningStage stage;
  final ContentKind kind;
  final String sourceHint;
  final String focus;
  final String difficulty;

  String get mediaDescription {
    return switch (kind) {
      ContentKind.sitcom => '这里会展示情景剧短片段或官方预览，配合台词短摘录做精听。',
      ContentKind.song => '这里会展示歌曲信息和合法短歌词片段，用来练连读、弱读和情绪表达。',
      ContentKind.dailyLife => '这里会展示 AI 生成的生活场景图文对话。',
      ContentKind.news => '这里会展示短新闻正文或官方来源链接，适合练主旨和细节。',
      ContentKind.article => '这里会展示报刊文章摘录，适合练长句、正式词汇和观点表达。',
    };
  }

  String get sampleContent {
    return switch (kind) {
      ContentKind.sitcom =>
        'A: I was about to grab some coffee. Do you want anything?\nB: That makes sense. I could use one too.\nA: Do you want me to text you when I get there?',
      ContentKind.song =>
        'A short chorus-style excerpt will appear here, focused on rhythm, connected speech, and everyday emotional phrases.',
      ContentKind.dailyLife =>
        'You run into a neighbor downstairs. You are about to buy coffee and offer to bring something back.',
      ContentKind.news =>
        'City officials announced a new public transport plan on Monday. The plan aims to reduce commute times and improve service during rush hour.',
      ContentKind.article =>
        'For many learners, fluency is less about knowing rare words and more about using familiar words quickly, accurately, and naturally.',
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
