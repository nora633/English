import 'package:flutter/material.dart';

import '../models/learning_models.dart';
import '../services/daily_lesson_service.dart';
import '../services/review_queue_store.dart';
import '../theme/app_theme.dart';
import 'keyword_detail_page.dart';
import '../widgets/shared_widgets.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.lesson,
    required this.lessonSource,
    required this.isGeneratingLesson,
    required this.completedMinutes,
    required this.reviewQueue,
    required this.onStartSpeaking,
    required this.onChooseTheme,
    required this.onGenerateLesson,
    required this.onOpenReview,
  });

  final DailyLesson lesson;
  final DailyLessonSource lessonSource;
  final bool isGeneratingLesson;
  final int completedMinutes;
  final List<ReviewQueueItem> reviewQueue;
  final VoidCallback onStartSpeaking;
  final VoidCallback onChooseTheme;
  final VoidCallback onGenerateLesson;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    final safeCompleted = completedMinutes.clamp(0, lesson.durationMinutes);
    final progress = safeCompleted / lesson.durationMinutes;
    final completed = safeCompleted >= lesson.durationMinutes;
    final pendingReviewItems = const ReviewQueueStore()
        .dueItems(reviewQueue)
        .take(3)
        .toList();
    final dueCount = const ReviewQueueStore().dueItems(reviewQueue).length;

    return AppScrollPage(
      title: '今日学习',
      children: [
        GradientPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('${lesson.durationMinutes} 分钟'),
                  const Spacer(),
                  StatusPill(text: completed ? '已完成' : '未完成'),
                ],
              ),
              const SizedBox(height: 20),
              Text(lesson.title, style: AppText.hero),
              const SizedBox(height: 10),
              Text(
                '${lesson.theme.title} · ${lesson.theme.sourceHint}',
                style: AppText.heroSub,
              ),
              const SizedBox(height: 8),
              Text(lesson.theme.focus, style: AppText.heroMuted),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('完成进度 $safeCompleted/${lesson.durationMinutes} 分钟'),
                  const Spacer(),
                  Text(lesson.theme.difficulty),
                ],
              ),
            ],
          ),
        ),
        CardPanel(
          title: '今日练习生成',
          icon: Icons.auto_awesome,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('来源：${lessonSource.label}', style: AppText.emphasis),
              const SizedBox(height: 6),
              const Text(
                '根据当前阶段、复盘弱项和素材偏好生成当天练习。当天生成后会保存到本机。',
                style: AppText.muted,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                icon: isGeneratingLesson ? Icons.hourglass_top : Icons.refresh,
                text: isGeneratingLesson ? '生成中' : '生成今日练习',
                onPressed: isGeneratingLesson ? () {} : onGenerateLesson,
              ),
            ],
          ),
        ),
        CardPanel(
          title: '今日复习',
          icon: Icons.repeat,
          action: TextButton(onPressed: onOpenReview, child: const Text('去复盘')),
          child: pendingReviewItems.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '完成跟读、听写或默写后，今天练过的词、词块和句子会自动进入复盘。',
                      style: AppText.muted,
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      icon: Icons.mic,
                      text: '先去完成练习',
                      onPressed: onStartSpeaking,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今天有 $dueCount 条到期复习，先抓最容易忘的 3 条。',
                      style: AppText.muted,
                    ),
                    const SizedBox(height: 12),
                    for (final item in pendingReviewItems)
                      _TodayReviewItem(item: item),
                    const SizedBox(height: 4),
                    SecondaryButton(
                      icon: Icons.repeat,
                      text: '进入复盘队列',
                      onPressed: onOpenReview,
                    ),
                  ],
                ),
        ),
        CardPanel(
          title: '精听句子',
          icon: Icons.headphones,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in lesson.listeningLines.indexed)
                NumberedLine(number: entry.$1 + 1, text: entry.$2),
              const SizedBox(height: 12),
              PrimaryButton(
                icon: Icons.mic,
                text: '去跟读练习',
                onPressed: onStartSpeaking,
              ),
            ],
          ),
        ),
        CardPanel(
          title: '今日关键单词',
          icon: Icons.menu_book_outlined,
          action: IconButton(
            onPressed: onChooseTheme,
            icon: const Icon(Icons.auto_awesome),
            tooltip: '换主题',
          ),
          child: Column(
            children: [
              const Text('今天先把句子里的词练到能听出来、写出来、说出来。'),
              const SizedBox(height: 12),
              for (final word in lesson.keyWords)
                KeywordTile(
                  word: word,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => KeywordDetailPage(word: word),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        CardPanel(
          title: '日常语法结构',
          icon: Icons.text_fields,
          child: Column(
            children: [
              const Text('不背抽象规则，只练今天句子里马上能用到的结构。'),
              const SizedBox(height: 12),
              for (final point in lesson.grammarPoints)
                GrammarTile(point: point),
            ],
          ),
        ),
        CardPanel(
          title: '今日词块',
          icon: Icons.format_quote,
          child: Column(
            children: [
              for (final chunk in lesson.targetChunks) ChunkTile(text: chunk),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayReviewItem extends StatelessWidget {
  const _TodayReviewItem({required this.item});

  final ReviewQueueItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SmallChip(label: item.kind.label),
              Text(item.themeTitle, style: AppText.chip),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.text, style: AppText.sectionBig),
          const SizedBox(height: 4),
          Text(item.note, style: AppText.muted),
        ],
      ),
    );
  }
}
