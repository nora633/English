import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample_data.dart';
import '../services/local_progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.completedMinutes,
    required this.stats,
    required this.onRestart,
    required this.onDataImported,
  });

  final int completedMinutes;
  final LocalLearningStats stats;
  final VoidCallback onRestart;
  final Future<void> Function() onDataImported;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final backupController = TextEditingController();
  final progressStore = const LocalProgressStore();
  String? backupCode;
  String? backupMessage;

  @override
  void dispose() {
    backupController.dispose();
    super.dispose();
  }

  Future<void> exportBackup() async {
    final exported = await progressStore.exportBackup();
    if (!mounted) return;

    setState(() {
      backupCode = exported;
      backupMessage = '已生成备份码。换手机后复制到导入框即可恢复。';
    });
  }

  Future<void> importBackup() async {
    try {
      await progressStore.importBackup(backupController.text);
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
