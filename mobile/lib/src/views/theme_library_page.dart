import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/learning_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ThemeLibraryPage extends StatefulWidget {
  const ThemeLibraryPage({super.key});

  @override
  State<ThemeLibraryPage> createState() => _ThemeLibraryPageState();
}

class _ThemeLibraryPageState extends State<ThemeLibraryPage> {
  LearningStage? stage;

  @override
  Widget build(BuildContext context) {
    final themes = SampleData.themes
        .where((theme) => stage == null || theme.stage == stage)
        .toList();

    return AppScrollPage(
      title: '素材主题',
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              StageChip(
                label: '全部',
                selected: stage == null,
                onTap: () => setState(() => stage = null),
              ),
              for (final item in LearningStage.values)
                StageChip(
                  label: item.label,
                  selected: stage == item,
                  onTap: () => setState(() => stage = item),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        for (final theme in themes)
          ThemeTile(
            theme: theme,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ThemeDetailPage(theme: theme),
                ),
              );
            },
          ),
      ],
    );
  }
}

class ThemeDetailPage extends StatelessWidget {
  const ThemeDetailPage({super.key, required this.theme});

  final LearningTheme theme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: AppScrollPage(
          title: theme.title,
          leading: IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          children: [
            CardPanel(
              title: theme.kind.label,
              icon: theme.kind.icon,
              child: Text(theme.mediaDescription),
            ),
            CardPanel(
              title: theme.kind.contentTitle,
              icon: Icons.description_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.sampleContent, style: AppText.bodyLarge),
                  const SizedBox(height: 12),
                  const Text(
                    '正式版只展示合法授权、官方预览、用户导入或用户手动粘贴的内容。',
                    style: AppText.muted,
                  ),
                ],
              ),
            ),
            CardPanel(
              title: '生成今日练习',
              icon: Icons.play_circle_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('根据“先日常、再影视歌曲、再新闻、最后报刊精读”的路径生成 15 分钟练习。'),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    icon: Icons.auto_awesome,
                    text: '生成今日 15 分钟练习',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    icon: Icons.bookmark_border,
                    text: '收藏素材',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
