import 'package:flutter/material.dart';

import '../models/learning_models.dart';
import '../models/today_flow_step.dart';
import '../services/daily_lesson_service.dart';
import '../services/local_progress_store.dart';
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
    required this.progress,
    required this.reviewQueue,
    required this.showOnboarding,
    required this.onStartSpeaking,
    required this.onChooseTheme,
    required this.onGenerateLesson,
    required this.onOpenReview,
    required this.onDismissOnboarding,
  });

  final DailyLesson lesson;
  final DailyLessonSource lessonSource;
  final bool isGeneratingLesson;
  final int completedMinutes;
  final LocalProgress progress;
  final List<ReviewQueueItem> reviewQueue;
  final bool showOnboarding;
  final VoidCallback onStartSpeaking;
  final VoidCallback onChooseTheme;
  final VoidCallback onGenerateLesson;
  final VoidCallback onOpenReview;
  final Future<void> Function() onDismissOnboarding;

  @override
  Widget build(BuildContext context) {
    final safeCompleted = completedMinutes.clamp(0, lesson.durationMinutes);
    final lessonProgress = safeCompleted / lesson.durationMinutes;
    final completed = safeCompleted >= lesson.durationMinutes;
    final pendingReviewItems = const ReviewQueueStore()
        .dueItems(reviewQueue)
        .take(3)
        .toList();
    final dueCount = const ReviewQueueStore().dueItems(reviewQueue).length;
    final flowSteps = [
      TodayFlowStep(
        title: '1. 生成今日练习',
        description: '先用当前计划生成或切换到今天要练的主题。',
        completed: true,
      ),
      TodayFlowStep(
        title: '2. 完成三项练习',
        description: '跟读、听写、默写各 5 分钟，做完就会累计进度。',
        completed:
            progress.recordingCompleted &&
            progress.dictationCompleted &&
            progress.recallCompleted,
      ),
      TodayFlowStep(
        title: '3. 去复盘加深记忆',
        description: '到期词块、精听句和错词错句会自动进复盘队列。',
        completed: completed,
      ),
    ];

    return AppScrollPage(
      title: '今日学习',
      children: [
        if (showOnboarding)
          CardPanel(
            title: '第一次来外语岛',
            icon: Icons.waving_hand_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '先别追求学很多，今天只要走完一次 15 分钟闭环：选内容、开口练、把容易忘的表达送进复盘。',
                  style: AppText.bodyLarge,
                ),
                const SizedBox(height: 12),
                const BulletLine(text: '今日页负责开始，看到三步流程直接往下做。'),
                const BulletLine(text: '跟读页做录音、听写和默写，数据只保存在本机。'),
                const BulletLine(text: '复盘页会记住你今天练过什么，明天继续接着学。'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        icon: Icons.arrow_forward,
                        text: '开始今日流程',
                        onPressed: () {
                          onDismissOnboarding();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                  value: lessonProgress,
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
          title: '今日三步流程',
          icon: Icons.route_outlined,
          child: Column(
            children: [
              for (final step in flowSteps) _TodayFlowTile(step: step),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      icon: Icons.auto_awesome,
                      text: '选素材',
                      onPressed: onChooseTheme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      icon: Icons.mic,
                      text: '继续练习',
                      onPressed: onStartSpeaking,
                    ),
                  ),
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
          title: completed ? '完成反馈' : '当前建议',
          icon: completed ? Icons.celebration_outlined : Icons.flag_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                completed
                    ? '今天这轮已经走完，可以去复盘巩固，或者换一个素材再来一轮轻练。'
                    : _nextActionText(),
                style: AppText.bodyLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SmallChip(
                    label: progress.recordingCompleted ? '跟读已完成' : '跟读待完成',
                  ),
                  SmallChip(
                    label: progress.dictationCompleted ? '听写已完成' : '听写待完成',
                  ),
                  SmallChip(
                    label: progress.recallCompleted ? '默写已完成' : '默写待完成',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                icon: completed ? Icons.repeat : Icons.play_arrow,
                text: completed ? '去复盘巩固' : '继续当前练习',
                onPressed: completed ? onOpenReview : onStartSpeaking,
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

  String _nextActionText() {
    if (!progress.recordingCompleted) {
      return '先完成一轮跟读，把耳朵和嘴先带起来，今天的学习就算真正开始了。';
    }
    if (!progress.dictationCompleted) {
      return '录音已经完成，下一步做听写，把刚才听到的细节补齐。';
    }
    if (!progress.recallCompleted) {
      return '最后做一轮默写或复述，把句子从“听懂”推进到“能自己说出来”。';
    }
    return '三项都完成后，去复盘看今天沉淀下来的表达。';
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

class _TodayFlowTile extends StatelessWidget {
  const _TodayFlowTile({required this.step});

  final TodayFlowStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: step.completed
            ? AppColors.teal.withValues(alpha: 0.10)
            : AppColors.page,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: step.completed ? AppColors.teal : AppColors.line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            step.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: step.completed ? AppColors.teal : AppColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: AppText.emphasis),
                const SizedBox(height: 4),
                Text(step.description, style: AppText.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
