import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import 'keyword_detail_page.dart';
import '../widgets/shared_widgets.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.completedMinutes,
    required this.onStartSpeaking,
    required this.onChooseTheme,
  });

  final int completedMinutes;
  final VoidCallback onStartSpeaking;
  final VoidCallback onChooseTheme;

  @override
  Widget build(BuildContext context) {
    final lesson = SampleData.todayLesson;
    final safeCompleted = completedMinutes.clamp(0, lesson.durationMinutes);
    final progress = safeCompleted / lesson.durationMinutes;
    final completed = safeCompleted >= lesson.durationMinutes;

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
