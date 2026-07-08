import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/learning_models.dart';
import '../services/material_activity_store.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ThemeLibraryPage extends StatefulWidget {
  const ThemeLibraryPage({
    super.key,
    required this.materialState,
    required this.onUseTheme,
    required this.onToggleFavorite,
  });

  final MaterialActivityState materialState;
  final Future<void> Function(LearningTheme theme) onUseTheme;
  final Future<void> Function(LearningTheme theme) onToggleFavorite;

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
        _MaterialOverview(state: widget.materialState),
        for (final theme in themes)
          ThemeTile(
            theme: theme,
            isFavorite: widget.materialState.isFavorite(theme),
            wasUsed: widget.materialState.wasUsed(theme),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ThemeDetailPage(
                    theme: theme,
                    materialState: widget.materialState,
                    onUseTheme: widget.onUseTheme,
                    onToggleFavorite: widget.onToggleFavorite,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class ThemeDetailPage extends StatefulWidget {
  const ThemeDetailPage({
    super.key,
    required this.theme,
    required this.materialState,
    required this.onUseTheme,
    required this.onToggleFavorite,
  });

  final LearningTheme theme;
  final MaterialActivityState materialState;
  final Future<void> Function(LearningTheme theme) onUseTheme;
  final Future<void> Function(LearningTheme theme) onToggleFavorite;

  @override
  State<ThemeDetailPage> createState() => _ThemeDetailPageState();
}

class _ThemeDetailPageState extends State<ThemeDetailPage> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.materialState.isFavorite(widget.theme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final materialState = widget.materialState;

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
              title: theme.previewTitle,
              icon: theme.kind.icon,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.previewDescription, style: AppText.bodyLarge),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.subtle,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(theme.kind.icon, color: AppColors.teal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _previewNotice(theme.kind),
                            style: AppText.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            CardPanel(
              title: '素材状态',
              icon: Icons.insights_outlined,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SmallChip(label: isFavorite ? '已收藏' : '未收藏'),
                  SmallChip(
                    label: materialState.wasUsed(theme) ? '最近使用过' : '未生成过',
                  ),
                  SmallChip(label: '使用 ${materialState.useCount(theme)} 次'),
                ],
              ),
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
              title: '可练句子',
              icon: Icons.headphones,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in theme.practiceSentences.indexed)
                    NumberedLine(number: entry.$1 + 1, text: entry.$2),
                ],
              ),
            ),
            CardPanel(
              title: '关键词',
              icon: Icons.menu_book_outlined,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final word in theme.keyVocabulary)
                    SmallChip(label: word),
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
                    onPressed: () async {
                      await widget.onUseTheme(theme);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    icon: isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    text: isFavorite ? '取消收藏' : '收藏素材',
                    onPressed: () async {
                      await widget.onToggleFavorite(theme);
                      if (!mounted) return;
                      setState(() => isFavorite = !isFavorite);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _previewNotice(ContentKind kind) {
    return switch (kind) {
      ContentKind.sitcom => '自用版先展示原创情景片段。后续可接入你手动导入的合法短片或官方预览链接。',
      ContentKind.song => '为避免版权问题，当前展示同类原创歌词式短句，不直接内置真实歌曲歌词。',
      ContentKind.dailyLife => '生活场景使用本地原创图文对话，适合马上跟读和默写。',
      ContentKind.news => '新闻稿为原创慢速新闻风格文本，先练结构和听读方法。',
      ContentKind.article => '报刊读物为原创观点段落，先练长句拆分和正式表达。',
    };
  }
}

class _MaterialOverview extends StatelessWidget {
  const _MaterialOverview({required this.state});

  final MaterialActivityState state;

  @override
  Widget build(BuildContext context) {
    final recentTitles = state.recentUsedTitles(limit: 3);

    return CardPanel(
      title: '素材偏好',
      icon: Icons.bookmarks_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SmallChip(label: '收藏 ${state.favoriteTitles.length} 个'),
              SmallChip(label: '使用 ${state.history.length} 次'),
            ],
          ),
          if (recentTitles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('最近使用：${recentTitles.join('、')}', style: AppText.muted),
          ] else ...[
            const SizedBox(height: 10),
            const Text('还没有使用历史，推荐会先从同阶段素材里轮换。', style: AppText.muted),
          ],
        ],
      ),
    );
  }
}
