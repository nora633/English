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
    required this.onReviewItemReviewed,
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
  final Future<void> Function(String id) onReviewItemReviewed;
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
  int practiceIndex = 0;
  bool revealPracticeAnswer = false;

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

  Future<void> markPracticeReviewed(ReviewQueueItem item) async {
    await widget.onReviewItemReviewed(item.id);
    if (!mounted) return;
    setState(() {
      revealPracticeAnswer = false;
      practiceIndex = 0;
    });
  }

  Future<void> markPracticeMastered(ReviewQueueItem item) async {
    await widget.onMarkReviewItemMastered(item.id);
    if (!mounted) return;
    setState(() {
      revealPracticeAnswer = false;
      practiceIndex = 0;
    });
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
    final dueReviewCount = reviewQueueStore.dueItems(widget.reviewQueue).length;
    final dueReviewItems = reviewQueueStore.dueItems(widget.reviewQueue);
    final pendingReviewCount = reviewQueueStore
        .pendingItems(widget.reviewQueue)
        .length;
    final visibleLessonHistory = lessonHistoryStore.search(
      widget.lessonHistory,
      historySearchQuery,
    );
    final masteredCount = widget.reviewQueue
        .where((item) => item.mastered)
        .length;
    final calendarDays = _buildCalendarDays(widget.stats.history);
    final safePracticeIndex = dueReviewItems.isEmpty
        ? 0
        : practiceIndex.clamp(0, dueReviewItems.length - 1);
    final practiceItem = dueReviewItems.isEmpty
        ? null
        : dueReviewItems[safePracticeIndex];

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
          title: '今日复盘练习',
          icon: Icons.psychology_alt_outlined,
          child: practiceItem == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '现在没有到期项目。今天完成跟读、听写或默写后，新的词、词块和句子会自动进来。',
                      style: AppText.muted,
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      icon: Icons.calendar_month,
                      text: '回到今日继续学',
                      onPressed: widget.onRestart,
                    ),
                  ],
                )
              : _ReviewPracticeCard(
                  item: practiceItem,
                  currentIndex: safePracticeIndex + 1,
                  totalCount: dueReviewItems.length,
                  revealAnswer: revealPracticeAnswer,
                  onRevealAnswer: () {
                    setState(() => revealPracticeAnswer = true);
                  },
                  onNextCard: dueReviewItems.length <= 1
                      ? null
                      : () {
                          setState(() {
                            revealPracticeAnswer = false;
                            practiceIndex =
                                (safePracticeIndex + 1) % dueReviewItems.length;
                          });
                        },
                  onNeedMorePractice: () => markPracticeReviewed(practiceItem),
                  onRemembered: () => markPracticeMastered(practiceItem),
                ),
        ),
        CardPanel(
          title: '学习日历',
          icon: Icons.calendar_view_week_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.stats.streakDays > 0
                    ? '你已经连续学了 ${widget.stats.streakDays} 天，尽量别让节奏断掉。'
                    : '今天先拿下一次完整练习，日历就会开始亮起来。',
                style: AppText.muted,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < calendarDays.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i == calendarDays.length - 1 ? 0 : 8,
                        ),
                        child: _CalendarDayTile(day: calendarDays[i]),
                      ),
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
                  SmallChip(label: '今日到期 $dueReviewCount 个'),
                  SmallChip(label: '未掌握 $pendingReviewCount 个'),
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
                    onReviewed: () async {
                      await widget.onReviewItemReviewed(item.id);
                    },
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

  List<_CalendarDay> _buildCalendarDays(List<DailyHistoryRecord> history) {
    final byDate = {for (final item in history) item.date: item};
    final today = DateTime.now();

    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final key = _dateKey(date);
      final record = byDate[key];
      return _CalendarDay(
        weekday: _weekdayLabel(date.weekday),
        dayLabel: date.day.toString().padLeft(2, '0'),
        completedMinutes: record?.completedMinutes ?? 0,
        completed: record?.completed ?? false,
        isToday: index == 6,
      );
    });
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return labels[weekday - 1];
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
  const _ReviewQueueTile({
    required this.item,
    required this.onReviewed,
    required this.onMastered,
  });

  final ReviewQueueItem item;
  final Future<void> Function() onReviewed;
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
          const SizedBox(height: 6),
          Text(_nextReviewLabel(item), style: AppText.muted),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('复习 ${item.reviewCount} 次', style: AppText.muted),
              TextButton.icon(
                onPressed: onReviewed,
                icon: const Icon(Icons.schedule),
                label: const Text('复习过'),
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

  String _nextReviewLabel(ReviewQueueItem item) {
    final now = DateTime.now();
    if (!item.nextReviewAt.isAfter(now)) return '下次复习：今天';

    final month = item.nextReviewAt.month.toString().padLeft(2, '0');
    final day = item.nextReviewAt.day.toString().padLeft(2, '0');
    return '下次复习：$month-$day';
  }
}

class _ReviewPracticeCard extends StatelessWidget {
  const _ReviewPracticeCard({
    required this.item,
    required this.currentIndex,
    required this.totalCount,
    required this.revealAnswer,
    required this.onRevealAnswer,
    required this.onNeedMorePractice,
    required this.onRemembered,
    this.onNextCard,
  });

  final ReviewQueueItem item;
  final int currentIndex;
  final int totalCount;
  final bool revealAnswer;
  final VoidCallback onRevealAnswer;
  final Future<void> Function() onNeedMorePractice;
  final Future<void> Function() onRemembered;
  final VoidCallback? onNextCard;

  @override
  Widget build(BuildContext context) {
    final prompt = _practicePrompt(item);
    final guidance = _practiceGuidance(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SmallChip(label: '第 $currentIndex / $totalCount 张'),
            SmallChip(label: item.kind.label),
            SmallChip(label: item.themeTitle),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.subtle,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prompt.label, style: AppText.chip),
              const SizedBox(height: 8),
              Text(prompt.text, style: AppText.sectionBig),
              const SizedBox(height: 10),
              Text(guidance, style: AppText.muted),
              if (revealAnswer) ...[
                const SizedBox(height: 14),
                const Divider(color: AppColors.line),
                const SizedBox(height: 10),
                Text('参考答案', style: AppText.emphasis),
                const SizedBox(height: 8),
                Text(item.text, style: AppText.sectionBig),
                const SizedBox(height: 6),
                Text(item.note, style: AppText.accent),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!revealAnswer)
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  icon: Icons.visibility_outlined,
                  text: '显示答案',
                  onPressed: onRevealAnswer,
                ),
              ),
              if (onNextCard != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    icon: Icons.skip_next,
                    text: '先看下一张',
                    onPressed: onNextCard!,
                  ),
                ),
              ],
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  icon: Icons.refresh,
                  text: '还要再练',
                  onPressed: () {
                    onNeedMorePractice();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  icon: Icons.check_circle,
                  text: '想起来了',
                  onPressed: () {
                    onRemembered();
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  _PracticePrompt _practicePrompt(ReviewQueueItem item) {
    switch (item.kind) {
      case ReviewItemKind.keyword:
        return _PracticePrompt(
          label: '看到意思回想英文',
          text:
              '${item.note}\n首字母提示：${_leadingHint(item.text)}\n这个词在“${item.themeTitle}”里怎么说？',
        );
      case ReviewItemKind.chunk:
        return _PracticePrompt(
          label: '看到用途回想词块',
          text:
              '${item.note}\n遮挡提示：${_maskedText(item.text)}\n先别看答案，直接把那段顺口表达说出来。',
        );
      case ReviewItemKind.sentence:
        return _PracticePrompt(
          label: '看到场景复述整句',
          text:
              '场景：${item.themeTitle}\n骨架提示：${_sentenceSkeleton(item.text)}\n先口头复述今天那句精听句，再点开核对。',
        );
    }
  }

  String _practiceGuidance(ReviewQueueItem item) {
    switch (item.kind) {
      case ReviewItemKind.keyword:
        return '先自己说英文，再顺手带一个你能立刻用上的短句。';
      case ReviewItemKind.chunk:
        return '目标不是逐字翻译，而是把整块表达一口气拿出来。';
      case ReviewItemKind.sentence:
        return '先完整复述，再留意时态、连读和句尾的小词有没有漏掉。';
    }
  }

  String _leadingHint(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '-';
    final first = trimmed.substring(0, 1).toUpperCase();
    return '$first _ _';
  }

  String _maskedText(String text) {
    final words = text.split(' ');
    return words.map((word) {
      if (word.length <= 2) return word;
      return '${word.substring(0, 1)}${'_' * (word.length - 1)}';
    }).join(' ');
  }

  String _sentenceSkeleton(String text) {
    final words = text.split(' ');
    return words.asMap().entries.map((entry) {
      final word = entry.value;
      final lettersOnly = word.replaceAll(RegExp(r'[^A-Za-z]'), '');
      if (entry.key.isEven || lettersOnly.length <= 2) return word;
      return '_' * lettersOnly.length;
    }).join(' ');
  }
}

class _PracticePrompt {
  const _PracticePrompt({required this.label, required this.text});

  final String label;
  final String text;
}

class _CalendarDay {
  const _CalendarDay({
    required this.weekday,
    required this.dayLabel,
    required this.completedMinutes,
    required this.completed,
    required this.isToday,
  });

  final String weekday;
  final String dayLabel;
  final int completedMinutes;
  final bool completed;
  final bool isToday;
}

class _CalendarDayTile extends StatelessWidget {
  const _CalendarDayTile({required this.day});

  final _CalendarDay day;

  @override
  Widget build(BuildContext context) {
    final highlight = day.completed
        ? AppColors.teal
        : day.completedMinutes > 0
        ? AppColors.orange
        : AppColors.line;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: day.isToday
            ? AppColors.indigo.withValues(alpha: 0.10)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: day.isToday ? AppColors.indigo : highlight,
          width: day.isToday ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(day.weekday, style: AppText.muted),
          const SizedBox(height: 6),
          Text(day.dayLabel, style: AppText.emphasis),
          const SizedBox(height: 8),
          Icon(
            day.completed
                ? Icons.check_circle
                : day.completedMinutes > 0
                ? Icons.timelapse
                : Icons.radio_button_unchecked,
            size: 18,
            color: highlight,
          ),
          const SizedBox(height: 6),
          Text(
            day.completedMinutes > 0 ? '${day.completedMinutes}分' : '-',
            style: AppText.chip,
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
