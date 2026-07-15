import 'package:flutter/material.dart';

import '../models/vnext_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

typedef ReviewCardAction = void Function(String sourcePackId, String cardId);

class ReviewOverviewPage extends StatefulWidget {
  const ReviewOverviewPage({
    super.key,
    required this.cards,
    required this.dailyLimit,
    required this.onRemembered,
    required this.onNeedMorePractice,
  });

  final List<ReviewCard> cards;
  final int dailyLimit;
  final ReviewCardAction onRemembered;
  final ReviewCardAction onNeedMorePractice;

  @override
  State<ReviewOverviewPage> createState() => _ReviewOverviewPageState();
}

class _ReviewOverviewPageState extends State<ReviewOverviewPage> {
  int selectedTab = 0;
  ReviewCardType? selectedType;

  @override
  Widget build(BuildContext context) {
    final hasLearnedContent = widget.cards.isNotEmpty;
    final allDueCards = widget.cards.where(_isDue).toList()
      ..sort(_compareReviewCards);
    final dueCards = allDueCards.take(widget.dailyLimit).toList();
    final deferredCount = allDueCards.length - dueCards.length;
    final masteredCards = widget.cards
        .where((item) => item.isMastered)
        .toList();
    final allLearnedContentMastered =
        widget.cards.isNotEmpty &&
        widget.cards.every((item) => item.isMastered);
    final cardsByPack = <String, List<ReviewCard>>{};
    for (final card in widget.cards) {
      cardsByPack.putIfAbsent(card.sourcePackId, () => []).add(card);
    }
    final fullyMasteredPackIds = cardsByPack.entries
        .where(
          (entry) =>
              entry.value.isNotEmpty &&
              entry.value.every((card) => card.isMastered),
        )
        .map((entry) => entry.key)
        .toSet();
    final visibleLearnedCards = widget.cards
        .where((card) => !fullyMasteredPackIds.contains(card.sourcePackId))
        .toList();
    final filteredCards = selectedType == null
        ? visibleLearnedCards
        : visibleLearnedCards
              .where((item) => item.type == selectedType)
              .toList();
    final unmasteredFilteredCards = filteredCards
        .where((item) => !item.isMastered)
        .toList();
    final masteredFilteredCards = filteredCards
        .where((item) => item.isMastered)
        .toList();

    return AppScrollPage(
      title: '复盘',
      showTitle: false,
      children: [
        _ReviewTopTabs(
          selectedTab: selectedTab,
          hasLearnedContent: hasLearnedContent,
          onSelect: (value) => setState(() => selectedTab = value),
        ),
        if (selectedTab == 0) ...[
          CardPanel(
            title: hasLearnedContent ? '统一复盘队列' : '完成后进入复盘',
            icon: Icons.repeat_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLearnedContent
                      ? '所有已练素材的到期卡片都会汇总到这里。每天最多复盘 ${widget.dailyLimit} 张，先到期的先练。'
                      : '你完成今天 5 句后，这里会自动生成复盘卡片，并且支持继续练，不只是展示。',
                  style: AppText.bodyLarge,
                ),
                if (hasLearnedContent) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SmallChip(label: '今日复盘 ${dueCards.length}'),
                      SmallChip(label: '全部到期 ${allDueCards.length}'),
                      SmallChip(label: '总卡片 ${widget.cards.length}'),
                      SmallChip(label: '已掌握 ${masteredCards.length}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!hasLearnedContent)
            const CardPanel(
              title: '复盘会沉淀什么',
              icon: Icons.layers_outlined,
              child: Text('每句会拆成关键词、重点词块、整句表达三类卡片，练完就能马上复盘。'),
            )
          else if (dueCards.isEmpty)
            const CardPanel(
              title: '今天没有到期卡片',
              icon: Icons.check_circle_outline,
              child: Text('当前卡片都已经往后排了。明天回来时，会先看到需要复习的关键词、词块和整句。'),
            )
          else ...[
            if (deferredCount > 0)
              CardPanel(
                title: '今天先练 ${dueCards.length} 张',
                icon: Icons.schedule_outlined,
                child: Text(
                  '另有 $deferredCount 张已到期卡片顺延，避免一次复盘时间过长。',
                  style: AppText.muted,
                ),
              ),
            for (final entry in dueCards.indexed)
              _ReviewCardPanel(
                key: ValueKey(
                  'review-card-${entry.$2.sourcePackId}-${entry.$2.id}',
                ),
                card: entry.$2,
                index: entry.$1 + 1,
                total: dueCards.length,
                onRemembered: () =>
                    widget.onRemembered(entry.$2.sourcePackId, entry.$2.id),
                onNeedMorePractice: () => widget.onNeedMorePractice(
                  entry.$2.sourcePackId,
                  entry.$2.id,
                ),
              ),
          ],
        ] else if (allLearnedContentMastered) ...[
          const CardPanel(
            title: '已学素材已全部掌握',
            icon: Icons.check_circle_outline,
            child: Text(
              '所有已学素材的复盘卡都已经掌握，明细不再展开；对应素材会在素材页标记为已掌握。',
              style: AppText.muted,
            ),
          ),
        ] else ...[
          CardPanel(
            title: '已学内容',
            icon: Icons.inventory_2_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '这里汇总所有素材沉淀下来的重点内容。整组已掌握的素材不再展开明细。',
                  style: AppText.muted,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('全部'),
                      selected: selectedType == null,
                      onSelected: (_) => setState(() => selectedType = null),
                    ),
                    for (final type in ReviewCardType.values)
                      ChoiceChip(
                        label: Text(_labelForType(type)),
                        selected: selectedType == type,
                        onSelected: (_) => setState(() => selectedType = type),
                      ),
                  ],
                ),
              ],
            ),
          ),
          CardPanel(
            title: '未掌握',
            icon: Icons.pending_actions_outlined,
            child: unmasteredFilteredCards.isEmpty
                ? const Text('这个分类里没有需要继续巩固的内容。', style: AppText.muted)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('还需要继续巩固的卡片会留在这里。', style: AppText.muted),
                      const SizedBox(height: 12),
                      for (final card in unmasteredFilteredCards)
                        _LearnedCardTile(
                          card: card,
                          label: _labelForType(card.type),
                          onTap: () => _openReviewCardDetail(card),
                        ),
                    ],
                  ),
          ),
          CardPanel(
            title: '已掌握',
            icon: Icons.check_circle_outline,
            child: masteredFilteredCards.isEmpty
                ? const Text('这个分类里还没有已掌握内容。', style: AppText.muted)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('这些卡片已经想起来，会从今日到期里退出。', style: AppText.muted),
                      const SizedBox(height: 12),
                      for (final card in masteredFilteredCards)
                        _LearnedCardTile(
                          card: card,
                          label: _labelForType(card.type),
                        ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }

  bool _isDue(ReviewCard card) {
    if (card.nextReviewAt.isEmpty) return true;
    final next = DateTime.tryParse(card.nextReviewAt);
    if (next == null) return true;
    return !next.isAfter(DateTime.now());
  }

  DateTime _reviewOrder(ReviewCard card) {
    return DateTime.tryParse(card.nextReviewAt) ?? DateTime(1970);
  }

  int _compareReviewCards(ReviewCard left, ReviewCard right) {
    if (left.isUserAdded != right.isUserAdded) {
      return left.isUserAdded ? -1 : 1;
    }
    return _reviewOrder(left).compareTo(_reviewOrder(right));
  }

  String _labelForType(ReviewCardType type) {
    switch (type) {
      case ReviewCardType.keyword:
        return '关键词';
      case ReviewCardType.chunk:
        return '词块';
      case ReviewCardType.sentence:
        return '整句';
    }
  }

  Future<void> _openReviewCardDetail(ReviewCard card) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewCardDetailPage(
          card: card,
          label: _labelForType(card.type),
          onRemembered: () => widget.onRemembered(card.sourcePackId, card.id),
          onNeedMorePractice: () =>
              widget.onNeedMorePractice(card.sourcePackId, card.id),
        ),
      ),
    );
  }
}

class _ReviewTopTabs extends StatelessWidget {
  const _ReviewTopTabs({
    required this.selectedTab,
    required this.hasLearnedContent,
    required this.onSelect,
  });

  final int selectedTab;
  final bool hasLearnedContent;
  final ValueChanged<int> onSelect;

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
          Expanded(
            child: _ReviewSegmentButton(
              text: '复盘练习',
              selected: selectedTab == 0,
              onTap: () => onSelect(0),
            ),
          ),
          Expanded(
            child: _ReviewSegmentButton(
              text: '已学内容',
              selected: selectedTab == 1,
              onTap: hasLearnedContent ? () => onSelect(1) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSegmentButton extends StatelessWidget {
  const _ReviewSegmentButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground = selected
        ? Colors.white
        : enabled
        ? AppColors.text
        : AppColors.muted;
    return Tooltip(
      message: enabled ? text : '完成今天练习后可查看',
      child: Material(
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
      ),
    );
  }
}

class _ReviewCardPanel extends StatefulWidget {
  const _ReviewCardPanel({
    super.key,
    required this.card,
    required this.index,
    required this.total,
    required this.onRemembered,
    required this.onNeedMorePractice,
  });

  final ReviewCard card;
  final int index;
  final int total;
  final VoidCallback onRemembered;
  final VoidCallback onNeedMorePractice;

  @override
  State<_ReviewCardPanel> createState() => _ReviewCardPanelState();
}

class _ReviewCardPanelState extends State<_ReviewCardPanel> {
  bool revealed = false;

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      title: '卡片 ${widget.index}/${widget.total}',
      icon: Icons.style_outlined,
      action: Wrap(
        spacing: 6,
        children: [
          SmallChip(label: _labelForType(widget.card.type)),
          if (widget.card.isUserAdded) const SmallChip(label: '自选'),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.card.front, style: AppText.sectionBig),
          const SizedBox(height: 8),
          Text(widget.card.hint, style: AppText.muted),
          if (widget.card.sourcePackTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('来源：${widget.card.sourcePackTitle}', style: AppText.accent),
          ],
          const SizedBox(height: 14),
          if (revealed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.page,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(widget.card.back, style: AppText.bodyLarge),
            ),
            if (widget.card.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in widget.card.tags) SmallChip(label: tag),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    icon: Icons.refresh,
                    text: '还要再练',
                    onPressed: widget.onNeedMorePractice,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    icon: Icons.check,
                    text: '想起来了',
                    onPressed: widget.onRemembered,
                  ),
                ),
              ],
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                icon: Icons.visibility_outlined,
                text: '翻开答案',
                onPressed: () => setState(() => revealed = true),
              ),
            ),
        ],
      ),
    );
  }

  String _labelForType(ReviewCardType type) {
    switch (type) {
      case ReviewCardType.keyword:
        return '关键词';
      case ReviewCardType.chunk:
        return '词块';
      case ReviewCardType.sentence:
        return '整句';
    }
  }
}

class ReviewCardDetailPage extends StatefulWidget {
  const ReviewCardDetailPage({
    super.key,
    required this.card,
    required this.label,
    required this.onRemembered,
    required this.onNeedMorePractice,
  });

  final ReviewCard card;
  final String label;
  final VoidCallback onRemembered;
  final VoidCallback onNeedMorePractice;

  @override
  State<ReviewCardDetailPage> createState() => _ReviewCardDetailPageState();
}

class _ReviewCardDetailPageState extends State<ReviewCardDetailPage> {
  bool revealed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: AppScrollPage(
          title: '卡片复习',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          children: [
            CardPanel(
              title: widget.label,
              icon: Icons.style_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.card.front, style: AppText.sectionTitle),
                  const SizedBox(height: 10),
                  Text(widget.card.hint, style: AppText.muted),
                  if (widget.card.sourcePackTitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '来源：${widget.card.sourcePackTitle}',
                      style: AppText.accent,
                    ),
                  ],
                  if (widget.card.isUserAdded) ...[
                    const SizedBox(height: 8),
                    const SmallChip(label: '自选重点词'),
                  ],
                  if (widget.card.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in widget.card.tags)
                          SmallChip(label: tag),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (revealed)
              CardPanel(
                title: '答案',
                icon: Icons.visibility_outlined,
                child: Text(widget.card.back, style: AppText.bodyLarge),
              )
            else
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  icon: Icons.visibility_outlined,
                  text: '翻开答案',
                  onPressed: () => setState(() => revealed = true),
                  large: true,
                ),
              ),
            if (revealed)
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      icon: Icons.refresh,
                      text: '还要再练',
                      onPressed: () {
                        widget.onNeedMorePractice();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      icon: Icons.check,
                      text: '想起来了',
                      onPressed: () {
                        widget.onRemembered();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LearnedCardTile extends StatelessWidget {
  const _LearnedCardTile({required this.card, required this.label, this.onTap});

  final ReviewCard card;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.front, style: AppText.emphasis),
                const SizedBox(height: 6),
                Text(
                  [
                    _statusText(card),
                    if (card.sourcePackTitle.isNotEmpty)
                      '来源：${card.sourcePackTitle}',
                    if (card.isUserAdded) '自选',
                  ].join(' · '),
                  style: AppText.muted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SmallChip(label: label),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: onTap == null
          ? tile
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: tile,
              ),
            ),
    );
  }

  String _statusText(ReviewCard card) {
    if (card.isMastered) return '已掌握';
    if (card.lastReviewedAt.isEmpty) return '待首次复盘';
    return '继续复习中';
  }
}
