import 'package:flutter/material.dart';

import '../models/vnext_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({
    super.key,
    required this.currentPackId,
    required this.packs,
    required this.statusByPackId,
    required this.onSelectTodayPack,
    required this.onAddFocusWord,
  });

  final String currentPackId;
  final List<ScenarioPack> packs;
  final Map<String, MaterialStatus> statusByPackId;
  final ValueChanged<ScenarioPack> onSelectTodayPack;
  final void Function(ScenarioPack pack, SentenceNote sentence) onAddFocusWord;

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  static const allCategory = '全部';
  static const categories = [
    allCategory,
    '日常表达',
    '邻里 / 家庭 / 同事轻场景',
    '情景剧灵感改写',
    '轻信息类 / 轻新闻类',
  ];

  String selectedCategory = allCategory;

  @override
  Widget build(BuildContext context) {
    final filteredPacks = selectedCategory == allCategory
        ? widget.packs
        : widget.packs
              .where((item) => item.category == selectedCategory)
              .toList();

    return AppScrollPage(
      title: '素材',
      showTitle: false,
      children: [
        _MaterialCategoryTabs(
          categories: categories,
          selectedCategory: selectedCategory,
          onSelected: (value) => setState(() => selectedCategory = value),
        ),
        if (filteredPacks.isEmpty)
          CardPanel(
            title: _shortLabelForCategory(selectedCategory),
            icon: _iconForCategory(selectedCategory),
            child: const Text('这个分类的素材会陆续补充。', style: AppText.muted),
          )
        else
          CardPanel(
            title: selectedCategory == allCategory
                ? '全部素材'
                : _shortLabelForCategory(selectedCategory),
            icon: _iconForCategory(selectedCategory),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final pack in filteredPacks)
                  _MaterialListTile(
                    pack: pack,
                    current: pack.id == widget.currentPackId,
                    status:
                        widget.statusByPackId[pack.id] ??
                        MaterialStatus.unpracticed,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MaterialDetailPage(
                            pack: pack,
                            current: pack.id == widget.currentPackId,
                            status:
                                widget.statusByPackId[pack.id] ??
                                MaterialStatus.unpracticed,
                            onSelectTodayPack: widget.onSelectTodayPack,
                            onAddFocusWord: widget.onAddFocusWord,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class MaterialDetailPage extends StatelessWidget {
  const MaterialDetailPage({
    super.key,
    required this.pack,
    required this.current,
    required this.status,
    required this.onSelectTodayPack,
    required this.onAddFocusWord,
  });

  final ScenarioPack pack;
  final bool current;
  final MaterialStatus status;
  final ValueChanged<ScenarioPack> onSelectTodayPack;
  final void Function(ScenarioPack pack, SentenceNote sentence) onAddFocusWord;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: AppScrollPage(
                title: '素材详情',
                showTitle: false,
                children: [
                  CardPanel(
                    title: pack.title,
                    icon: Icons.article_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pack.sceneDescription, style: AppText.bodyLarge),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SmallChip(label: pack.category),
                            _DifficultyStars(difficulty: pack.difficulty),
                            SmallChip(label: '5 句'),
                            SmallChip(label: _materialStatusLabel(status)),
                            if (current) const SmallChip(label: '今日素材'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CardPanel(
                    title: '5 句总览',
                    icon: Icons.format_list_numbered_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in pack.sentences.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: AppColors.indigo,
                                  child: Text(
                                    '${entry.$1 + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.$2.english,
                                        style: AppText.emphasis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.$2.chinese,
                                        style: AppText.muted,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.$2.role,
                                              style: AppText.accent,
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: () =>
                                                onAddFocusWord(pack, entry.$2),
                                            icon: const Icon(
                                              Icons.bookmark_add_outlined,
                                              size: 17,
                                            ),
                                            label: const Text('添加重点词'),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  CardPanel(
                    title: '重点表达',
                    icon: Icons.label_important_outline,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in _focusExpressions(pack))
                          SmallChip(label: item),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: current
                        ? PrimaryButton(
                            icon: Icons.school_outlined,
                            text: '用这个继续今天练习',
                            onPressed: () => Navigator.of(context).pop(),
                            large: true,
                          )
                        : PrimaryButton(
                            icon: Icons.swap_horiz,
                            text: '设为今日练习',
                            onPressed: () {
                              Navigator.of(context).pop();
                              onSelectTodayPack(pack);
                            },
                            large: true,
                          ),
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

class _MaterialCategoryTabs extends StatelessWidget {
  const _MaterialCategoryTabs({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final category in categories)
            Expanded(
              child: _MaterialTabButton(
                text: _shortLabelForCategory(category),
                selected: selectedCategory == category,
                onTap: () => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _MaterialTabButton extends StatelessWidget {
  const _MaterialTabButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.text;
    return Material(
      color: selected ? AppColors.teal : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

String _shortLabelForCategory(String value) {
  switch (value) {
    case '全部':
      return '全部';
    case '日常表达':
      return '日常';
    case '邻里 / 家庭 / 同事轻场景':
      return '轻场景';
    case '情景剧灵感改写':
      return '情景剧';
    case '轻信息类 / 轻新闻类':
      return '轻信息';
    default:
      return value;
  }
}

IconData _iconForCategory(String value) {
  switch (value) {
    case '日常表达':
    case '日常':
      return Icons.chat_bubble_outline;
    case '邻里 / 家庭 / 同事轻场景':
    case '轻场景':
      return Icons.groups_2_outlined;
    case '情景剧灵感改写':
    case '情景剧':
      return Icons.movie_filter_outlined;
    case '轻信息类 / 轻新闻类':
    case '轻信息':
      return Icons.newspaper_outlined;
    default:
      return Icons.library_books_outlined;
  }
}

class _MaterialCurrentBadge extends StatelessWidget {
  const _MaterialCurrentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        '今日练习',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MaterialListTile extends StatelessWidget {
  const _MaterialListTile({
    required this.pack,
    required this.current,
    required this.status,
    required this.onTap,
  });

  final ScenarioPack pack;
  final bool current;
  final MaterialStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(pack.title, style: AppText.emphasis)),
                    const SizedBox(width: 8),
                    if (current) const _MaterialCurrentBadge(),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
                const SizedBox(height: 6),
                Text(pack.summary, style: AppText.muted),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DifficultyStars(difficulty: pack.difficulty),
                    _MaterialStatusChip(status: status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialStatusChip extends StatelessWidget {
  const _MaterialStatusChip({required this.status});

  final MaterialStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      MaterialStatus.unpracticed => (AppColors.page, AppColors.muted),
      MaterialStatus.inProgress => (const Color(0xFFFFF0D6), AppColors.orange),
      MaterialStatus.practiced => (const Color(0xFFDDF3F1), AppColors.teal),
      MaterialStatus.mastered => (const Color(0xFFE4F0FF), AppColors.indigo),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _materialStatusLabel(status),
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DifficultyStars extends StatelessWidget {
  const _DifficultyStars({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final count = switch (difficulty) {
      '基础' => 1,
      '进阶' => 2,
      '轻挑战' => 3,
      _ => 1,
    };
    return Tooltip(
      message: difficulty,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '难易程度',
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 6),
            for (var i = 0; i < count; i++)
              const Icon(Icons.star_rounded, size: 15, color: AppColors.teal),
          ],
        ),
      ),
    );
  }
}

List<String> _focusExpressions(ScenarioPack pack) {
  final chunks = pack.sentences.expand((item) => item.focusChunks);
  final keywords = pack.sentences
      .expand((item) => item.focusWords)
      .map((item) => item.word);
  return [
    ...chunks,
    ...keywords,
  ].where((item) => item.isNotEmpty).toSet().take(6).toList();
}

String _materialStatusLabel(MaterialStatus status) {
  switch (status) {
    case MaterialStatus.unpracticed:
      return '未练过';
    case MaterialStatus.inProgress:
      return '练习中';
    case MaterialStatus.practiced:
      return '已练过';
    case MaterialStatus.mastered:
      return '已掌握';
  }
}
