import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample_data.dart';
import '../models/learning_models.dart';
import '../services/learning_preferences_store.dart';
import '../services/lesson_history_store.dart';
import '../services/local_progress_store.dart';
import '../services/review_queue_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.completedMinutes,
    required this.preferences,
    required this.stats,
    required this.lessonHistory,
    required this.reviewQueue,
    required this.onMarkReviewItemMastered,
    required this.onPreferencesChanged,
    required this.onRestart,
    required this.onDataImported,
  });

  final int completedMinutes;
  final LearningPreferences preferences;
  final LocalLearningStats stats;
  final List<LessonHistoryRecord> lessonHistory;
  final List<ReviewQueueItem> reviewQueue;
  final Future<void> Function(String id) onMarkReviewItemMastered;
  final Future<void> Function(LearningPreferences preferences)
  onPreferencesChanged;
  final VoidCallback onRestart;
  final Future<void> Function() onDataImported;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final backupController = TextEditingController();
  final searchController = TextEditingController();
  final historySearchController = TextEditingController();
  final lessonHistoryStore = const LessonHistoryStore();
  final preferencesStore = const LearningPreferencesStore();
  final progressStore = const LocalProgressStore();
  final reviewQueueStore = const ReviewQueueStore();
  String? backupCode;
  String? backupMessage;
  String searchQuery = '';
  String historySearchQuery = '';

  @override
  void dispose() {
    backupController.dispose();
    searchController.dispose();
    historySearchController.dispose();
    super.dispose();
  }

  Future<void> exportBackup() async {
    final progressBackup = await progressStore.exportBackup();
    final decoded = jsonDecode(progressBackup);
    final lessonHistory = await lessonHistoryStore.exportItems();
    final preferences = await preferencesStore.exportItem();
    final reviewQueue = await reviewQueueStore.exportItems();
    final exported = jsonEncode({
      if (decoded is Map<String, dynamic>) ...decoded,
      'lessonHistory': lessonHistory,
      'learningPreferences': preferences,
      'reviewQueue': reviewQueue,
    });
    if (!mounted) return;

    setState(() {
      backupCode = exported;
      backupMessage = '已生成备份码。换手机后复制到导入框即可恢复。';
    });
  }

  Future<void> importBackup() async {
    try {
      final decoded = jsonDecode(backupController.text.trim());
      await progressStore.importBackup(backupController.text);
      if (decoded is Map<String, dynamic>) {
        await lessonHistoryStore.importItems(decoded['lessonHistory']);
        await preferencesStore.importItem(decoded['learningPreferences']);
        await reviewQueueStore.importItems(decoded['reviewQueue']);
      }
      await widget.onDataImported();
      if (!mounted) return;

      setState(() => backupMessage = '已导入学习数据。');
    } catch (_) {
      if (!mounted) return;
      setState(() => backupMessage = '导入失败，请确认备份码完整。');
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = SampleData.review;
    final totalMinutes = widget.stats.totalMinutes > 0
        ? widget.stats.totalMinutes
        : review.completedMinutes + widget.completedMinutes;
    final masteredExpression = widget.completedMinutes >= 5
        ? 'I was about to...'
        : '完成跟读后会出现';
    final reviewExpression = widget.stats.savedTroubleSpots.isNotEmpty
        ? widget.stats.savedTroubleSpots.first
        : 'Do you want me to...?';
    final visibleReviewItems = reviewQueueStore.search(
      widget.reviewQueue,
      searchQuery,
    );
    final visibleLessonHistory = lessonHistoryStore.search(
      widget.lessonHistory,
      historySearchQuery,
    );
    final masteredCount = widget.reviewQueue
        .where((item) => item.mastered)
        .length;

    return AppScrollPage(
      title: '学习复盘',
      children: [
        Row(
          children: [
            Expanded(
              child: MetricTile(
                title: '连续',
                value: '${widget.stats.streakDays} 天',
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                title: '累计',
                value: '$totalMinutes 分钟',
                color: AppColors.indigo,
              ),
            ),
          ],
        ),
        CardPanel(
          title: '学习计划',
          icon: Icons.tune,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('这些设置只保存在本机，会影响明天生成的今日练习。', style: AppText.muted),
              const SizedBox(height: 14),
              const Text('每日目标', style: AppText.emphasis),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in const [10, 15])
                    ChoiceChip(
                      label: Text('$minutes 分钟'),
                      selected: widget.preferences.dailyGoalMinutes == minutes,
                      onSelected: (_) {
                        widget.onPreferencesChanged(
                          widget.preferences.copyWith(
                            dailyGoalMinutes: minutes,
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('默认素材阶段', style: AppText.emphasis),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final stage in LearningStage.values)
                    ChoiceChip(
                      label: Text(stage.label),
                      selected: widget.preferences.preferredStage == stage,
                      onSelected: (_) {
                        widget.onPreferencesChanged(
                          widget.preferences.copyWith(preferredStage: stage),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        CardPanel(
          title: '最近记录',
          icon: Icons.calendar_month_outlined,
          child: widget.stats.history.isEmpty
              ? const Text('完成今天的跟读、听写或默写后，这里会留下记录。', style: AppText.muted)
              : Column(
                  children: [
                    for (final record in widget.stats.history)
                      _HistoryRecordTile(record: record),
                  ],
                ),
        ),
        CardPanel(
          title: '错词错句',
          icon: Icons.bookmark_added_outlined,
          child: widget.stats.savedTroubleSpots.isEmpty
              ? const Text('听写或默写检查后，会把容易漏掉的词和句子沉淀到这里。', style: AppText.muted)
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in widget.stats.savedTroubleSpots)
                      SmallChip(label: item),
                  ],
                ),
        ),
        CardPanel(
          title: '词块复习',
          icon: Icons.repeat,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SmallChip(label: '待复习 ${visibleReviewItems.length} 个'),
                  SmallChip(label: '已掌握 $masteredCount 个'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchController,
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: '搜索练过的词块、句子或素材',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (visibleReviewItems.isEmpty)
                const Text(
                  '完成跟读、听写或默写后，今日关键词、词块和精听句会进入这里。',
                  style: AppText.muted,
                )
              else
                for (final item in visibleReviewItems.take(10))
                  _ReviewQueueTile(
                    item: item,
                    onMastered: () async {
                      await widget.onMarkReviewItemMastered(item.id);
                    },
                  ),
            ],
          ),
        ),
        CardPanel(
          title: '练习历史搜索',
          icon: Icons.manage_search,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: historySearchController,
                onChanged: (value) =>
                    setState(() => historySearchQuery = value),
                decoration: InputDecoration(
                  hintText: '搜索练过的素材、句子、关键词',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (visibleLessonHistory.isEmpty)
                const Text('生成或使用今日练习后，这里会保留最近练过的内容。', style: AppText.muted)
              else
                for (final item in visibleLessonHistory.take(6))
                  _LessonHistoryTile(record: item),
            ],
          ),
        ),
        CardPanel(
          title: '明日推荐',
          icon: Icons.auto_awesome,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.recommendation.title,
                      style: AppText.sectionBig,
                    ),
                  ),
                  const StatusPill(text: '推荐', dark: true),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${review.recommendation.stage.label} · ${review.recommendation.difficulty}',
                style: AppText.accent,
              ),
              const SizedBox(height: 12),
              Text(review.recommendation.reason),
              const SizedBox(height: 12),
              BulletLine(text: review.recommendation.mix),
              BulletLine(text: review.recommendation.weakFocus),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final keyword in review.recommendation.keywords)
                    SmallChip(label: keyword),
                ],
              ),
            ],
          ),
        ),
        CardPanel(
          title: '可迁移表达',
          icon: Icons.sync,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(review.reusableExpression, style: AppText.sectionBig),
              const SizedBox(height: 8),
              const Text(
                '明天可以替换 coffee 为 lunch、a package、some water，练出真实反应速度。',
              ),
            ],
          ),
        ),
        CardPanel(
          title: '掌握和待复习',
          icon: Icons.fact_check_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ExpressionStatusRow(
                label: '已掌握',
                text: masteredExpression,
                color: AppColors.teal,
              ),
              _ExpressionStatusRow(
                label: '待复习',
                text: reviewExpression,
                color: AppColors.orange,
              ),
              _ExpressionStatusRow(
                label: '明天继续练',
                text: 'want me to / text you when',
                color: AppColors.indigo,
              ),
            ],
          ),
        ),
        CardPanel(
          title: '明日重点',
          icon: Icons.flag_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(review.nextFocus),
              const SizedBox(height: 12),
              PrimaryButton(
                icon: Icons.check_circle,
                text: '完成并回到今日',
                onPressed: widget.onRestart,
              ),
            ],
          ),
        ),
        CardPanel(
          title: '数据备份',
          icon: Icons.ios_share_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '现在是本地存储，不会自动同步到另一台手机。可以先用备份码在 Android 和 iPhone 之间迁移学习记录。',
                style: AppText.muted,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                icon: Icons.upload_file,
                text: '生成备份码',
                onPressed: exportBackup,
              ),
              if (backupCode != null) ...[
                const SizedBox(height: 12),
                SelectableText(backupCode!, style: AppText.muted),
                const SizedBox(height: 10),
                SecondaryButton(
                  icon: Icons.copy,
                  text: '复制备份码',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: backupCode!));
                    if (!mounted) return;
                    setState(() => backupMessage = '备份码已复制。');
                  },
                ),
              ],
              const SizedBox(height: 14),
              AppTextField(controller: backupController, hint: '粘贴备份码'),
              const SizedBox(height: 12),
              SecondaryButton(
                icon: Icons.download_done,
                text: '导入备份码',
                onPressed: importBackup,
              ),
              if (backupMessage != null) ...[
                const SizedBox(height: 10),
                Text(backupMessage!, style: AppText.accent),
              ],
            ],
          ),
        ),
        const CardPanel(
          title: '自用版状态',
          icon: Icons.info_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BulletLine(text: '可用：每日 15 分钟流程、本地进度、录音、回放、复盘、翻译和历史记录。'),
              BulletLine(text: '可用：备份码导出/导入，用于手动迁移 Android 和 iPhone 数据。'),
              BulletLine(text: '未接云端：不同手机之间不会自动同步。'),
              BulletLine(text: '未接 AI：口语评分、语音转写和翻译仍是本地原型结果。'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpressionStatusRow extends StatelessWidget {
  const _ExpressionStatusRow({
    required this.label,
    required this.text,
    required this.color,
  });

  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmallChip(label: label),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.emphasis)),
        ],
      ),
    );
  }
}

class _ReviewQueueTile extends StatelessWidget {
  const _ReviewQueueTile({required this.item, required this.onMastered});

  final ReviewQueueItem item;
  final Future<void> Function() onMastered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.page,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmallChip(label: item.kind.label),
              const SizedBox(width: 8),
              Expanded(child: Text(item.text, style: AppText.emphasis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.note, style: AppText.accent),
          const SizedBox(height: 6),
          Text(item.themeTitle, style: AppText.muted),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('复习 ${item.reviewCount} 次', style: AppText.muted),
              ),
              TextButton.icon(
                onPressed: onMastered,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('标记掌握'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonHistoryTile extends StatelessWidget {
  const _LessonHistoryTile({required this.record});

  final LessonHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final lesson = record.lesson;
    final firstLine = lesson.listeningLines.isEmpty
        ? lesson.theme.sampleContent
        : lesson.listeningLines.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(lesson.theme.title, style: AppText.emphasis),
              ),
              SmallChip(label: record.sourceLabel),
            ],
          ),
          const SizedBox(height: 6),
          Text(_dateLabel(record.savedAt), style: AppText.muted),
          const SizedBox(height: 8),
          Text(firstLine),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final word in lesson.keyWords.take(3))
                SmallChip(label: word.word),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }
}

class _HistoryRecordTile extends StatelessWidget {
  const _HistoryRecordTile({required this.record});

  final DailyHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.date, style: AppText.emphasis),
                const SizedBox(height: 4),
                Text('${record.completedMinutes}/15 分钟', style: AppText.muted),
              ],
            ),
          ),
          SmallChip(label: record.completed ? '已完成' : '进行中'),
        ],
      ),
    );
  }
}
