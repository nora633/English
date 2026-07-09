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
    required this.customThemes,
    required this.dailyGoalMinutes,
    required this.onUseTheme,
    required this.onToggleFavorite,
    required this.onSaveCustomTheme,
  });

  final MaterialActivityState materialState;
  final List<LearningTheme> customThemes;
  final int dailyGoalMinutes;
  final Future<void> Function(LearningTheme theme) onUseTheme;
  final Future<void> Function(LearningTheme theme) onToggleFavorite;
  final Future<void> Function(LearningTheme theme) onSaveCustomTheme;

  @override
  State<ThemeLibraryPage> createState() => _ThemeLibraryPageState();
}

class _ThemeLibraryPageState extends State<ThemeLibraryPage> {
  LearningStage? stage;

  @override
  Widget build(BuildContext context) {
    final allThemes = [...SampleData.themes, ...widget.customThemes];
    final themes = allThemes
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
        _CustomMaterialEntry(
          customCount: widget.customThemes.length,
          onCreate: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CustomMaterialPage(onSave: widget.onSaveCustomTheme),
              ),
            );
          },
        ),
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
                    dailyGoalMinutes: widget.dailyGoalMinutes,
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

class CustomMaterialPage extends StatefulWidget {
  const CustomMaterialPage({super.key, required this.onSave});

  final Future<void> Function(LearningTheme theme) onSave;

  @override
  State<CustomMaterialPage> createState() => _CustomMaterialPageState();
}

class _CustomMaterialPageState extends State<CustomMaterialPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final focusController = TextEditingController();
  LearningStage stage = LearningStage.daily;
  ContentKind kind = ContentKind.dailyLife;
  String? errorText;

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: AppScrollPage(
          title: '手动素材',
          leading: IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          children: [
            CardPanel(
              title: '粘贴合法短片段',
              icon: Icons.edit_note,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '适合粘贴你自己写的对话、授权片段、官方短预览或少量学习笔记。不要保存完整剧本、完整歌词或长篇受版权保护文本。',
                    style: AppText.muted,
                  ),
                  const SizedBox(height: 14),
                  _LabeledTextField(
                    label: '标题',
                    hint: '例如：餐厅点单小片段',
                    controller: titleController,
                  ),
                  const SizedBox(height: 12),
                  _PickerRow(
                    stage: stage,
                    kind: kind,
                    onStageChanged: (value) => setState(() => stage = value),
                    onKindChanged: (value) => setState(() => kind = value),
                  ),
                  const SizedBox(height: 12),
                  _LabeledTextField(
                    label: '训练重点',
                    hint: '例如：点单、确认需求、礼貌回应',
                    controller: focusController,
                  ),
                  const SizedBox(height: 12),
                  _LabeledTextField(
                    label: '短片段内容',
                    hint: '粘贴 2-8 句英文，或一小段原创/授权内容',
                    controller: contentController,
                    minLines: 6,
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 14),
                  PrimaryButton(
                    icon: Icons.save_outlined,
                    text: '保存为素材',
                    onPressed: save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> save() async {
    final content = contentController.text.trim();
    if (content.isEmpty) {
      setState(() => errorText = '先粘贴一小段合法素材内容。');
      return;
    }

    final theme = LearningTheme(
      title: _titleFor(titleController.text, content),
      stage: stage,
      kind: kind,
      sourceHint: '手动粘贴素材',
      focus: focusController.text.trim().isEmpty
          ? '从手动片段中提炼表达、跟读和默写'
          : focusController.text.trim(),
      difficulty: _difficultyFor(stage),
      previewTitle: '你保存的短片段',
      previewDescription: '本地保存的手动素材，可直接生成今日 15 分钟练习。',
      sampleContent: content,
      practiceSentences: _practiceSentencesFor(content),
      keyVocabulary: _keywordsFor(content),
    );

    await widget.onSave(theme);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String _titleFor(String rawTitle, String content) {
    final trimmed = rawTitle.trim();
    if (trimmed.isNotEmpty) return trimmed;

    final firstLine = content
        .split(RegExp(r'[\n.!?。！？]'))
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '手动素材');
    return firstLine.length > 18
        ? '${firstLine.substring(0, 18)}...'
        : firstLine;
  }

  String _difficultyFor(LearningStage stage) {
    return switch (stage) {
      LearningStage.daily => 'A2-B1',
      LearningStage.media => 'B1',
      LearningStage.news => 'B1-B2',
      LearningStage.reading => 'B2-C1',
    };
  }

  List<String> _practiceSentencesFor(String content) {
    final sentences = content
        .split(RegExp(r'[\n。！？.!?]+'))
        .map((item) => item.trim())
        .where((item) => item.length >= 8)
        .take(5)
        .toList();
    return sentences.isEmpty ? [content] : sentences;
  }

  List<String> _keywordsFor(String content) {
    final matches = RegExp(r"[A-Za-z][A-Za-z'-]{3,}").allMatches(content);
    final words = <String>[];
    for (final match in matches) {
      final word = match.group(0)!.toLowerCase();
      if (!words.contains(word)) words.add(word);
      if (words.length == 4) break;
    }
    return words.isEmpty ? const ['expression', 'practice'] : words;
  }
}

class ThemeDetailPage extends StatefulWidget {
  const ThemeDetailPage({
    super.key,
    required this.theme,
    required this.materialState,
    required this.dailyGoalMinutes,
    required this.onUseTheme,
    required this.onToggleFavorite,
  });

  final LearningTheme theme;
  final MaterialActivityState materialState;
  final int dailyGoalMinutes;
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
              title: '内容边界',
              icon: Icons.verified_user_outlined,
              child: _ContentBoundaryNotice(theme: theme),
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
                  Text('根据当前学习计划生成 ${widget.dailyGoalMinutes} 分钟练习。'),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    icon: Icons.auto_awesome,
                    text: '生成今日 ${widget.dailyGoalMinutes} 分钟练习',
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

class _ContentBoundaryNotice extends StatelessWidget {
  const _ContentBoundaryNotice({required this.theme});

  final LearningTheme theme;

  @override
  Widget build(BuildContext context) {
    final reference = theme.sourceHint.contains('本地参考');
    final custom = theme.sourceHint.contains('手动');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reference) ...const [
          BulletLine(text: '本卡只使用本地台词本的学习方向，不保存原始台词。'),
          BulletLine(text: '精听句、词块和示例对话均为原创改写。'),
          BulletLine(text: '原始文件保留在素材来源目录，不提交 Git，也不打包进 App。'),
        ] else if (custom) ...const [
          BulletLine(text: '手动素材只保存在本机，用于生成今日练习。'),
          BulletLine(text: '请只粘贴原创、授权、官方短预览或少量学习笔记。'),
          BulletLine(text: '不要保存完整剧本、完整歌词或长篇受版权保护文本。'),
        ] else ...const [
          BulletLine(text: '当前练习内容为 App 内置原创或用户手动提供。'),
          BulletLine(text: '正式版只展示合法授权、官方预览、用户导入或手动粘贴的内容。'),
        ],
      ],
    );
  }
}

class _CustomMaterialEntry extends StatelessWidget {
  const _CustomMaterialEntry({
    required this.customCount,
    required this.onCreate,
  });

  final int customCount;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      title: '手动素材',
      icon: Icons.post_add,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customCount == 0
                ? '粘贴一小段合法内容，保存成本地素材，再生成今日练习。'
                : '已保存 $customCount 个手动素材，可和内置素材一起轮换推荐。',
            style: AppText.muted,
          ),
          const SizedBox(height: 12),
          SecondaryButton(icon: Icons.add, text: '粘贴新素材', onPressed: onCreate),
        ],
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.minLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.emphasis),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : 10,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.stage,
    required this.kind,
    required this.onStageChanged,
    required this.onKindChanged,
  });

  final LearningStage stage;
  final ContentKind kind;
  final ValueChanged<LearningStage> onStageChanged;
  final ValueChanged<ContentKind> onKindChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _DropdownBox<LearningStage>(
          label: '阶段',
          value: stage,
          items: LearningStage.values,
          itemLabel: (item) => item.label,
          onChanged: onStageChanged,
        ),
        _DropdownBox<ContentKind>(
          label: '类型',
          value: kind,
          items: ContentKind.values,
          itemLabel: (item) => item.label,
          onChanged: onKindChanged,
        ),
      ],
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  const _DropdownBox({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.emphasis),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            initialValue: value,
            items: [
              for (final item in items)
                DropdownMenuItem(value: item, child: Text(itemLabel(item))),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
