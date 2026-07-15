import 'package:flutter/material.dart';

import '../models/vnext_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'keyword_detail_page.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({
    super.key,
    required this.pack,
    required this.state,
    required this.isPlaying,
    required this.audioError,
    required this.onPlaySentence,
    required this.onPlayScenario,
    required this.onStopAudio,
    required this.onMarkShadowDone,
    required this.onAdvanceFromKeywords,
    required this.onDictationChanged,
    required this.onRecallChanged,
    required this.onCheckDictation,
    required this.onCheckRecall,
    required this.onCompleteDictation,
    required this.onCompleteRecall,
    required this.onCompleteConsolidation,
    required this.onOpenReviewAfterCompletion,
    required this.onBackToTodayAfterCompletion,
    required this.onAddFocusWord,
    required this.reviewCards,
  });

  final ScenarioPack pack;
  final PracticeState state;
  final bool isPlaying;
  final String? audioError;
  final VoidCallback onPlaySentence;
  final VoidCallback onPlayScenario;
  final VoidCallback onStopAudio;
  final VoidCallback onMarkShadowDone;
  final VoidCallback onAdvanceFromKeywords;
  final ValueChanged<String> onDictationChanged;
  final ValueChanged<String> onRecallChanged;
  final PracticeCheckResult Function() onCheckDictation;
  final PracticeCheckResult Function() onCheckRecall;
  final Future<void> Function() onCompleteDictation;
  final Future<void> Function() onCompleteRecall;
  final VoidCallback onCompleteConsolidation;
  final VoidCallback onOpenReviewAfterCompletion;
  final VoidCallback onBackToTodayAfterCompletion;
  final VoidCallback onAddFocusWord;
  final List<ReviewCard> reviewCards;

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  late final TextEditingController _dictationController;
  late final TextEditingController _recallController;
  PracticeCheckResult? _dictationResult;
  PracticeCheckResult? _recallResult;
  bool _showSuccess = false;
  bool _showAllFocusWords = false;
  String _successTitle = '';
  String _successSubtitle = '';

  @override
  void initState() {
    super.initState();
    _dictationController = TextEditingController();
    _recallController = TextEditingController();
    _dictationController.addListener(() {
      widget.onDictationChanged(_dictationController.text);
    });
    _recallController.addListener(() {
      widget.onRecallChanged(_recallController.text);
    });
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant PracticePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentSentenceIndex !=
        widget.state.currentSentenceIndex) {
      _dictationResult = null;
      _recallResult = null;
      _showAllFocusWords = false;
    }
    _syncControllers();
  }

  void _syncControllers() {
    final progress = widget.state.sentences[widget.state.currentSentenceIndex];
    if (_dictationController.text != progress.dictationInput) {
      _dictationController.value = TextEditingValue(
        text: progress.dictationInput,
        selection: TextSelection.collapsed(
          offset: progress.dictationInput.length,
        ),
      );
    }
    if (_recallController.text != progress.recallInput) {
      _recallController.value = TextEditingValue(
        text: progress.recallInput,
        selection: TextSelection.collapsed(offset: progress.recallInput.length),
      );
    }
  }

  @override
  void dispose() {
    _dictationController.dispose();
    _recallController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.state.currentSentenceIndex;
    final sentence = widget.pack.sentences[index];
    final progress = widget.state.sentences[index];
    final flowStage = widget.state.flowStage;

    return Stack(
      children: [
        AppScrollPage(
          title: '单句练习',
          showTitle: false,
          children: [
            if (flowStage == PracticeFlowStage.consolidation)
              _buildConsolidation()
            else if (flowStage == PracticeFlowStage.completion)
              _buildCompletion()
            else ...[
              if (_showHero(widget.state.currentStep))
                GradientPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '第 ${index + 1} / ${widget.pack.sentences.length} 句',
                        style: AppText.heroMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(sentence.english, style: AppText.hero),
                      const SizedBox(height: 10),
                      Text(
                        sentence.chinese,
                        style: AppText.heroMuted.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: widget.isPlaying
                              ? widget.onStopAudio
                              : widget.onPlaySentence,
                          icon: Icon(
                            widget.isPlaying
                                ? Icons.stop_circle_outlined
                                : Icons.volume_up_outlined,
                            color: Colors.white,
                          ),
                          label: Text(
                            widget.isPlaying ? '停止播放' : '再听一遍',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      if (widget.audioError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.audioError!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              if (_showHero(widget.state.currentStep)) ...[
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    icon: Icons.bookmark_add_outlined,
                    text: '添加本句重点词',
                    onPressed: widget.onAddFocusWord,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildCurrentStep(context, sentence, progress),
            ],
          ],
        ),
        if (_showSuccess)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: _SuccessToast(
                  title: _successTitle,
                  subtitle: _successSubtitle,
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _showHero(PracticeStep step) {
    return step == PracticeStep.listen || step == PracticeStep.shadow;
  }

  Widget _buildCurrentStep(
    BuildContext context,
    SentenceNote sentence,
    SentenceProgress progress,
  ) {
    switch (widget.state.currentStep) {
      case PracticeStep.listen:
      case PracticeStep.shadow:
        return Column(
          children: [
            _StepCard(
              title: '1. 听读一遍',
              active: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sentence.scenePrompt, style: AppText.bodyLarge),
                  const SizedBox(height: 8),
                  const Text(
                    '先听原句，再自己开口读一遍。这里不做评分，读完就继续。',
                    style: AppText.muted,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    icon: widget.isPlaying
                        ? Icons.stop_circle_outlined
                        : Icons.play_arrow,
                    text: widget.isPlaying ? '停止播放' : '播放原句',
                    onPressed: widget.isPlaying
                        ? widget.onStopAudio
                        : widget.onPlaySentence,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                icon: Icons.check_circle_outline,
                text: '已听读，下一步',
                onPressed: widget.onMarkShadowDone,
                large: true,
              ),
            ),
          ],
        );
      case PracticeStep.keywords:
        final focusWords = sentence.focusWords;
        final personalWords = widget.reviewCards
            .where(
              (card) =>
                  card.isUserAdded && card.sourceSentenceId == sentence.id,
            )
            .toList(growable: false);
        final visibleWords = _showAllFocusWords
            ? focusWords
            : focusWords.take(3).toList(growable: false);
        return Column(
          children: [
            _StepCard(
              title: '2. 重点单词 + 词块 + 句型',
              active: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('重点单词', style: AppText.emphasis),
                  const SizedBox(height: 8),
                  if (personalWords.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final card in personalWords)
                          SmallChip(label: '${card.front} · 自选'),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (visibleWords.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        '这句没有需要单独记忆的单词，重点练下面的词块。',
                        style: AppText.muted,
                      ),
                    ),
                  for (final keyword in visibleWords)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: AppColors.subtle,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    KeywordDetailPage(word: keyword),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        keyword.word,
                                        style: AppText.sectionBig,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        keyword.meaning,
                                        style: AppText.accent,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (focusWords.length > 3)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(
                          () => _showAllFocusWords = !_showAllFocusWords,
                        ),
                        icon: Icon(
                          _showAllFocusWords
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        label: Text(
                          _showAllFocusWords
                              ? '收起更多词汇'
                              : '展开更多词汇（${focusWords.length - 3}）',
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text('重点词块', style: AppText.emphasis),
                  const SizedBox(height: 8),
                  for (final chunk in sentence.focusChunks)
                    ChunkTile(text: chunk),
                  Text('句型结构', style: AppText.emphasis),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.page,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sentence.pattern, style: AppText.emphasis),
                        const SizedBox(height: 6),
                        Text(sentence.chinese, style: AppText.muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                icon: Icons.keyboard_outlined,
                text: '我看完了，开始听写',
                onPressed: widget.onAdvanceFromKeywords,
                large: true,
              ),
            ),
          ],
        );
      case PracticeStep.dictation:
        return Column(
          children: [
            _StepCard(
              title: '3. 听写',
              active: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('先听一句，再把英文完整输入出来。', style: AppText.muted),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _dictationController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '听原句后输入英文',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    icon: widget.isPlaying
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_outlined,
                    text: widget.isPlaying ? '停止播放' : '播放句子',
                    onPressed: widget.onPlaySentence,
                  ),
                  const SizedBox(height: 10),
                  _FeedbackBox(result: _dictationResult),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                icon: Icons.check,
                text: '确认',
                onPressed: () async {
                  late final PracticeCheckResult result;
                  setState(() {
                    result = _dictationResult = widget.onCheckDictation();
                  });
                  if (result.correct) {
                    await _showSuccessTick(title: '听写正确', subtitle: '马上进入默写');
                    await widget.onCompleteDictation();
                  }
                },
                large: true,
              ),
            ),
          ],
        );
      case PracticeStep.recall:
        return Column(
          children: [
            _StepCard(
              title: '4. 默写',
              active: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sentence.chinese, style: AppText.bodyLarge),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _recallController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '根据中文意思输入英文',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FeedbackBox(result: _recallResult),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                icon: Icons.check,
                text: '确认',
                onPressed: () async {
                  late final PracticeCheckResult result;
                  setState(() {
                    result = _recallResult = widget.onCheckRecall();
                  });
                  if (result.correct) {
                    final isLastSentence =
                        widget.state.currentSentenceIndex ==
                        widget.pack.sentences.length - 1;
                    await _showSuccessTick(
                      title: isLastSentence ? '5 句完成' : '默写正确',
                      subtitle: isLastSentence ? '进入整段巩固' : '进入下一句',
                    );
                    await widget.onCompleteRecall();
                  }
                },
                large: true,
              ),
            ),
          ],
        );
    }
  }

  Future<void> _showSuccessTick({
    required String title,
    required String subtitle,
  }) async {
    if (!mounted) return;
    setState(() {
      _successTitle = title;
      _successSubtitle = subtitle;
      _showSuccess = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() => _showSuccess = false);
  }

  Widget _buildConsolidation() {
    return Column(
      children: [
        GradientPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('5 句已完成', style: AppText.heroMuted),
              const SizedBox(height: 10),
              Text(widget.pack.title, style: AppText.hero),
              const SizedBox(height: 10),
              Text(
                '把今天这 5 句重新顺成一个完整场景，再给今天一个自然收口。',
                style: AppText.heroSub.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        CardPanel(
          title: '整段巩固',
          icon: Icons.auto_stories_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in widget.pack.sentences.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.$1 + 1}. ', style: AppText.emphasis),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.$2.english, style: AppText.bodyLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  icon: widget.isPlaying
                      ? Icons.stop_circle_outlined
                      : Icons.play_arrow,
                  text: widget.isPlaying ? '停止播放' : '播放整段',
                  onPressed: widget.isPlaying
                      ? widget.onStopAudio
                      : widget.onPlayScenario,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            icon: Icons.check_circle,
            text: '我顺完了，完成今天练习',
            onPressed: widget.onCompleteConsolidation,
            large: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletion() {
    return Column(
      children: [
        GradientPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('今天完成了', style: AppText.heroMuted),
              const SizedBox(height: 10),
              Text(widget.pack.title, style: AppText.hero),
              const SizedBox(height: 10),
              Text(
                '你已经把今天 5 句完整练完，重点内容已经准备好进入复盘。',
                style: AppText.heroSub.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        CardPanel(
          title: '今日提炼',
          icon: Icons.lightbulb_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.pack.reviewHeadline, style: AppText.bodyLarge),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SmallChip(
                    label:
                        '关键词 ${widget.reviewCards.where((item) => item.type == ReviewCardType.keyword).length}',
                  ),
                  SmallChip(
                    label:
                        '词块 ${widget.reviewCards.where((item) => item.type == ReviewCardType.chunk).length}',
                  ),
                  SmallChip(
                    label:
                        '整句 ${widget.reviewCards.where((item) => item.type == ReviewCardType.sentence).length}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (widget.reviewCards.isNotEmpty)
                Column(
                  children: [
                    for (final item in widget.reviewCards.take(4))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SmallChip(label: item.front),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            icon: Icons.repeat,
            text: '进入复盘',
            onPressed: widget.onOpenReviewAfterCompletion,
            large: true,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SecondaryButton(
            icon: Icons.today_outlined,
            text: '回到今日',
            onPressed: widget.onBackToTodayAfterCompletion,
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.active,
    required this.child,
  });

  final String title;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      title: title,
      icon: active ? Icons.play_circle_fill : Icons.check_circle_outline,
      child: Opacity(opacity: active ? 1 : 0.78, child: child),
    );
  }
}

class _SuccessToast extends StatelessWidget {
  const _SuccessToast({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFF19B55B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppText.sectionTitle),
            const SizedBox(height: 4),
            Text(subtitle, style: AppText.muted),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  const _FeedbackBox({required this.result});

  final PracticeCheckResult? result;

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: result!.correct
            ? AppColors.teal.withValues(alpha: 0.10)
            : AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result!.message, style: AppText.emphasis),
          for (final hint in result!.hints) ...[
            const SizedBox(height: 6),
            Text('• $hint'),
          ],
        ],
      ),
    );
  }
}
