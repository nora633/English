import 'package:flutter/material.dart';

import 'data/vnext_sample_data.dart';
import 'models/vnext_models.dart';
import 'services/speech_service.dart';
import 'services/vnext_practice_store.dart';
import 'theme/app_theme.dart';
import 'views/materials_page.dart';
import 'views/practice_page.dart';
import 'views/review_overview_page.dart';
import 'views/today_page.dart';

enum AppTab { today, practice, materials, review }

const _dailyReviewLimit = 10;
const _personalFocusLimitPerPack = 5;

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.speechClient});

  final SpeechClient? speechClient;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final SpeechClient speech;
  late final Map<String, ScenarioPack> packById;
  late final Map<String, VNextPracticeStore> storesById;

  Map<String, PracticeState> statesByPackId = {};
  late String currentPackId;
  AppTab tab = AppTab.today;
  bool isPlaying = false;
  String? audioError;

  ScenarioPack get pack => packById[currentPackId]!;
  PracticeState? get state => statesByPackId[currentPackId];

  @override
  void initState() {
    super.initState();
    speech = widget.speechClient ?? SpeechService();
    packById = {for (final item in VNextSampleData.packLibrary) item.id: item};
    storesById = {
      for (final item in VNextSampleData.packLibrary)
        item.id: VNextPracticeStore(
          storageKey: 'vnext.practice.${item.id}',
          sentenceCount: item.sentences.length,
        ),
    };
    currentPackId = VNextSampleData.todayPack.id;
    _load();
  }

  Future<void> _load() async {
    final savedCurrentPackId = await VNextPracticeStore.loadCurrentPackId();
    final nextCurrentPackId = packById.containsKey(savedCurrentPackId)
        ? savedCurrentPackId!
        : VNextSampleData.todayPack.id;

    final loadedStates = <String, PracticeState>{};
    for (final entry in storesById.entries) {
      loadedStates[entry.key] = await entry.value.load();
    }

    if (!mounted) return;
    setState(() {
      currentPackId = nextCurrentPackId;
      statesByPackId = loadedStates;
    });
  }

  Future<void> _persistCurrentPackId() {
    return VNextPracticeStore.saveCurrentPackId(currentPackId);
  }

  void _persistStateFor(String packId, PracticeState next) {
    statesByPackId = {...statesByPackId, packId: next};
    storesById[packId]!.save(next);
  }

  void _updateState(PracticeState next) {
    setState(() {
      statesByPackId = {...statesByPackId, currentPackId: next};
    });
    _persistStateFor(currentPackId, next);
  }

  PracticeState _stateForPack(String packId) {
    return statesByPackId[packId] ??
        PracticeState.initial(packById[packId]!.sentences.length);
  }

  MaterialStatus _statusForPack(String packId) {
    return _stateForPack(packId).materialStatus;
  }

  Future<void> _playText(String text) async {
    try {
      await speech.stop();
      if (!mounted) return;
      setState(() {
        isPlaying = true;
        audioError = null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await speech.speak(text, locale: 'en-US');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        audioError = '当前设备暂时无法播放今日句子，但不影响继续练习。';
      });
    } finally {
      if (mounted) {
        setState(() => isPlaying = false);
      }
    }
  }

  Future<void> _playLines(List<String> texts) async {
    try {
      await speech.stop();
      if (!mounted) return;
      setState(() {
        isPlaying = true;
        audioError = null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await speech.speakLines(texts, locale: 'en-US');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        audioError = '当前设备暂时无法播放今日句子，但不影响继续练习。';
      });
    } finally {
      if (mounted) {
        setState(() => isPlaying = false);
      }
    }
  }

  Future<void> _stopAudio() async {
    await speech.stop();
    if (!mounted) return;
    setState(() => isPlaying = false);
  }

  Future<void> _togglePlayText(String text) async {
    if (isPlaying) {
      await _stopAudio();
      return;
    }
    await _playText(text);
  }

  Future<void> _togglePlayLines(List<String> texts) async {
    if (isPlaying) {
      await _stopAudio();
      return;
    }
    await _playLines(texts);
  }

  void _toggleMeaning() {
    final current = state!;
    _updateState(
      current.copyWith(warmupMeaningOpened: !current.warmupMeaningOpened),
    );
  }

  Future<void> _startPracticeFromToday() async {
    await speech.stop();
    if (!mounted) return;
    setState(() {
      isPlaying = false;
      tab = AppTab.practice;
    });
  }

  void _markShadowDone() {
    speech.stop();
    if (mounted) {
      setState(() => isPlaying = false);
    }
    final current = state!;
    final updated = [...current.sentences];
    final sentence = updated[current.currentSentenceIndex];
    updated[current.currentSentenceIndex] = sentence.copyWith(shadowDone: true);
    _updateState(
      current.copyWith(sentences: updated, currentStep: PracticeStep.keywords),
    );
  }

  void _advanceFromKeywords() {
    speech.stop();
    if (mounted) {
      setState(() => isPlaying = false);
    }
    _updateState(state!.copyWith(currentStep: PracticeStep.dictation));
  }

  Future<void> _completeDictationStep() async {
    final current = state!;
    _updateState(current.copyWith(currentStep: PracticeStep.recall));
  }

  Future<void> _completeRecallStep() async {
    final current = state!;
    final index = current.currentSentenceIndex;
    if (index == pack.sentences.length - 1) {
      _updateState(
        current.copyWith(flowStage: PracticeFlowStage.consolidation),
      );
      return;
    }

    final next = current.copyWith(
      currentSentenceIndex: index + 1,
      currentStep: PracticeStep.listen,
      flowStage: PracticeFlowStage.practice,
    );
    await speech.stop();
    if (mounted) {
      setState(() => isPlaying = false);
    }
    _updateState(next);
  }

  void _completeConsolidation() {
    final current = state!;
    final reviewCards = _buildReviewCards(current.reviewCards);
    final next = current.copyWith(
      flowStage: PracticeFlowStage.completion,
      reviewCards: reviewCards,
      completed: true,
      lastCompletedDate: DateTime.now().toIso8601String().split('T').first,
    );
    _updateState(next);
  }

  void _openReviewAfterCompletion() {
    setState(() => tab = AppTab.review);
  }

  void _backToTodayAfterCompletion() {
    setState(() => tab = AppTab.today);
  }

  void _skipToReviewForTesting() {
    final current = state!;
    final completedSentences = [
      for (final progress in current.sentences)
        progress.copyWith(
          shadowDone: true,
          dictationDone: true,
          recallDone: true,
        ),
    ];
    final next = current.copyWith(
      warmupMeaningOpened: true,
      currentSentenceIndex: pack.sentences.length - 1,
      currentStep: PracticeStep.recall,
      flowStage: PracticeFlowStage.completion,
      sentences: completedSentences,
      reviewCards: _buildReviewCards(current.reviewCards),
      completed: true,
      lastCompletedDate: DateTime.now().toIso8601String().split('T').first,
    );
    _updateState(next);
    setState(() => tab = AppTab.review);
  }

  void _changeDictation(String value) {
    final current = state!;
    final updated = [...current.sentences];
    updated[current.currentSentenceIndex] =
        updated[current.currentSentenceIndex].copyWith(dictationInput: value);
    _updateState(current.copyWith(sentences: updated));
  }

  void _changeRecall(String value) {
    final current = state!;
    final updated = [...current.sentences];
    updated[current.currentSentenceIndex] =
        updated[current.currentSentenceIndex].copyWith(recallInput: value);
    _updateState(current.copyWith(sentences: updated));
  }

  PracticeCheckResult _buildCheckResult({
    required String answer,
    required String target,
    required int attempts,
    required String firstWrong,
    required String softHint,
    required String strongHint,
  }) {
    if (_normalize(answer) == _normalize(target)) {
      return const PracticeCheckResult(
        correct: true,
        message: '这一步完成了，可以继续。',
        hints: [],
      );
    }
    if (attempts == 1) {
      return PracticeCheckResult(
        correct: false,
        message: firstWrong,
        hints: const [],
      );
    }
    if (attempts == 2) {
      return PracticeCheckResult(
        correct: false,
        message: '还差一点，再补齐关键信息。',
        hints: [softHint],
      );
    }
    return PracticeCheckResult(
      correct: false,
      message: '继续调整，但这次还不会直接给完整答案。',
      hints: [softHint, strongHint],
    );
  }

  PracticeCheckResult _checkDictation() {
    final current = state!;
    final index = current.currentSentenceIndex;
    final note = pack.sentences[index];
    final progress = current.sentences[index];
    final attempts = progress.dictationAttempts + 1;
    final result = _buildCheckResult(
      answer: progress.dictationInput,
      target: note.english,
      attempts: attempts,
      firstWrong: '这次听写还没对上。',
      softHint: note.dictationHint,
      strongHint: '先抓主干，再补小词和时态。',
    );
    final updated = [...current.sentences];
    updated[index] = progress.copyWith(
      dictationAttempts: attempts,
      dictationDone: result.correct,
    );
    _updateState(
      current.copyWith(sentences: updated, currentStep: PracticeStep.dictation),
    );
    return result;
  }

  PracticeCheckResult _checkRecall() {
    final current = state!;
    final index = current.currentSentenceIndex;
    final note = pack.sentences[index];
    final progress = current.sentences[index];
    final attempts = progress.recallAttempts + 1;
    final result = _buildCheckResult(
      answer: progress.recallInput,
      target: note.english,
      attempts: attempts,
      firstWrong: '这次表达还不完整。',
      softHint: note.recallHint,
      strongHint: '把句子的主干、时间点和关键词块都带上。',
    );
    final updated = [...current.sentences];
    updated[index] = progress.copyWith(
      recallAttempts: attempts,
      recallDone: result.correct,
    );
    _updateState(
      current.copyWith(sentences: updated, currentStep: PracticeStep.recall),
    );
    return result;
  }

  Future<void> _openPersonalFocusDialog(
    ScenarioPack sourcePack,
    SentenceNote sentence,
  ) async {
    final noteController = TextEditingController();
    String? selectedWord;
    String? statusMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final ownerState = _stateForPack(sourcePack.id);
            final personalCards = ownerState.reviewCards
                .where((card) => card.isUserAdded)
                .toList();
            final sentenceCards = personalCards
                .where((card) => card.sourceSentenceId == sentence.id)
                .toList();
            final addedWords = sentenceCards
                .map((card) => card.front.toLowerCase())
                .toSet();
            final defaultKeywords = sentence.focusWords
                .map((keyword) => keyword.word.toLowerCase())
                .toSet();
            final candidates = _wordChoices(sentence.english)
                .where(
                  (word) =>
                      !addedWords.contains(word.toLowerCase()) &&
                      !defaultKeywords.contains(word.toLowerCase()),
                )
                .toList();
            final atLimit = personalCards.length >= _personalFocusLimitPerPack;

            return AlertDialog(
              title: const Text('添加重点词'),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sentence.english, style: AppText.emphasis),
                      const SizedBox(height: 6),
                      Text(sentence.chinese, style: AppText.muted),
                      const SizedBox(height: 14),
                      Text(
                        '每个素材最多自选 $_personalFocusLimitPerPack 个，当前 ${personalCards.length}/$_personalFocusLimitPerPack。',
                        style: AppText.muted,
                      ),
                      if (sentenceCards.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('本句已添加', style: AppText.emphasis),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final card in sentenceCards)
                              InputChip(
                                label: Text(card.front),
                                avatar: const Icon(Icons.bookmark, size: 16),
                                onDeleted: () {
                                  _removePersonalFocusWord(
                                    sourcePack.id,
                                    card.id,
                                  );
                                  setDialogState(() {
                                    statusMessage = '已从复盘中移除 ${card.front}';
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text('选择一个单词', style: AppText.emphasis),
                      const SizedBox(height: 8),
                      if (candidates.isEmpty)
                        const Text('这句话里的单词都已经添加。', style: AppText.muted)
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final word in candidates)
                              ChoiceChip(
                                label: Text(word),
                                selected: selectedWord == word,
                                onSelected: atLimit
                                    ? null
                                    : (_) => setDialogState(() {
                                        selectedWord = word;
                                        statusMessage = null;
                                      }),
                              ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: noteController,
                        enabled: !atLimit,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: '我的中文备注（可选）',
                          hintText: '例如：持续一段时间',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (atLimit) ...[
                        const SizedBox(height: 10),
                        const Text(
                          '已达到本素材上限，可先移除一个自选词。',
                          style: TextStyle(color: AppColors.orange),
                        ),
                      ] else if (statusMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(statusMessage!, style: AppText.accent),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('完成'),
                ),
                FilledButton.icon(
                  onPressed: selectedWord == null || atLimit
                      ? null
                      : () {
                          final word = selectedWord!;
                          _addPersonalFocusWord(
                            sourcePack,
                            sentence,
                            word,
                            noteController.text.trim(),
                          );
                          noteController.clear();
                          setDialogState(() {
                            selectedWord = null;
                            statusMessage = '已将 $word 加入统一复盘';
                          });
                        },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('加入复盘'),
                ),
              ],
            );
          },
        );
      },
    );
    noteController.dispose();
  }

  void _addPersonalFocusWord(
    ScenarioPack sourcePack,
    SentenceNote sentence,
    String word,
    String personalNote,
  ) {
    final ownerState = _stateForPack(sourcePack.id);
    final normalizedWord = _normalizeFocusWord(word);
    final id = 'custom.keyword.${sentence.id}.$normalizedWord';
    final personalCards = ownerState.reviewCards
        .where((card) => card.isUserAdded)
        .toList();
    if (personalCards.length >= _personalFocusLimitPerPack ||
        ownerState.reviewCards.any((card) => card.id == id)) {
      return;
    }

    final contextAnswer = '${sentence.english}\n${sentence.chinese}';
    final card = ReviewCard(
      id: id,
      type: ReviewCardType.keyword,
      front: word,
      back: personalNote.isEmpty
          ? contextAnswer
          : '$personalNote\n$contextAnswer',
      hint: '先回忆这个词在原句里的意思，再翻开核对。',
      sourceSentenceId: sentence.id,
      tags: [sentence.chunk, '自选'],
      memoryLevel: 0,
      nextReviewAt: DateTime.now().toIso8601String(),
      lastReviewedAt: '',
      sourcePackId: sourcePack.id,
      sourcePackTitle: sourcePack.title,
      isUserAdded: true,
      personalNote: personalNote,
    );
    _updateStateForPack(
      sourcePack.id,
      ownerState.copyWith(reviewCards: [...ownerState.reviewCards, card]),
    );
  }

  void _removePersonalFocusWord(String sourcePackId, String cardId) {
    final ownerState = _stateForPack(sourcePackId);
    _updateStateForPack(
      sourcePackId,
      ownerState.copyWith(
        reviewCards: ownerState.reviewCards
            .where((card) => !(card.isUserAdded && card.id == cardId))
            .toList(),
      ),
    );
  }

  void _markReviewRemembered(String sourcePackId, String cardId) {
    final ownerPackId = packById.containsKey(sourcePackId)
        ? sourcePackId
        : currentPackId;
    final ownerState = _stateForPack(ownerPackId);
    final now = DateTime.now();
    final updated = [
      for (final card in ownerState.reviewCards)
        if (card.id == cardId)
          card.copyWith(
            memoryLevel: 1,
            lastReviewedAt: now.toIso8601String(),
            nextReviewAt: now
                .add(Duration(days: _nextIntervalDays(1)))
                .toIso8601String(),
          )
        else
          card,
    ];
    _updateStateForPack(ownerPackId, ownerState.copyWith(reviewCards: updated));
  }

  void _markReviewNeedsPractice(String sourcePackId, String cardId) {
    final ownerPackId = packById.containsKey(sourcePackId)
        ? sourcePackId
        : currentPackId;
    final ownerState = _stateForPack(ownerPackId);
    final now = DateTime.now();
    final updated = [
      for (final card in ownerState.reviewCards)
        if (card.id == cardId)
          card.copyWith(
            memoryLevel: 0,
            lastReviewedAt: now.toIso8601String(),
            nextReviewAt: now.add(const Duration(minutes: 1)).toIso8601String(),
          )
        else
          card,
    ];
    _updateStateForPack(ownerPackId, ownerState.copyWith(reviewCards: updated));
  }

  void _updateStateForPack(String packId, PracticeState next) {
    setState(() {
      statesByPackId = {...statesByPackId, packId: next};
    });
    _persistStateFor(packId, next);
  }

  List<ReviewCard> _buildReviewCards(List<ReviewCard> existing) {
    final existingById = {for (final item in existing) item.id: item};
    final personalCards = existing.where((item) => item.isUserAdded).toList();
    final now = DateTime.now().toIso8601String();
    final cards = <ReviewCard>[];

    final primaryKeywordPicks = pack.sentences
        .where((sentence) => sentence.focusWords.isNotEmpty)
        .map(
          (sentence) =>
              (sentence: sentence, keyword: sentence.focusWords.first),
        );
    final additionalKeywordPicks = pack.sentences.expand(
      (sentence) => sentence.focusWords
          .skip(1)
          .map((keyword) => (sentence: sentence, keyword: keyword)),
    );
    final keywordPicks = [
      ...primaryKeywordPicks,
      ...additionalKeywordPicks,
    ].take(3);
    for (final pick in keywordPicks) {
      final id = 'keyword.${pick.sentence.id}.${pick.keyword.word}';
      cards.add(
        existingById[id] ??
            ReviewCard(
              id: id,
              type: ReviewCardType.keyword,
              front: pick.keyword.word,
              back: '${pick.keyword.meaning}\n${pick.keyword.example}',
              hint: '先回忆它在今天哪一句里出现、是什么意思。',
              sourceSentenceId: pick.sentence.id,
              tags: [pick.sentence.chunk, pick.sentence.chinese],
              memoryLevel: 0,
              nextReviewAt: now,
              lastReviewedAt: '',
              sourcePackId: pack.id,
              sourcePackTitle: pack.title,
            ),
      );
    }

    final chunkPicks = pack.sentences.take(2);
    for (final sentence in chunkPicks) {
      final id = 'chunk.${sentence.id}';
      cards.add(
        existingById[id] ??
            ReviewCard(
              id: id,
              type: ReviewCardType.chunk,
              front: sentence.chunk,
              back: '${sentence.english}\n${sentence.chinese}',
              hint: '先想这个词块通常接在哪个句子主干里。',
              sourceSentenceId: sentence.id,
              tags: [sentence.pattern],
              memoryLevel: 0,
              nextReviewAt: now,
              lastReviewedAt: '',
              sourcePackId: pack.id,
              sourcePackTitle: pack.title,
            ),
      );
    }

    final sentencePicks = [
      pack.sentences.first,
      if (pack.sentences.length > 1) pack.sentences.last,
    ];
    for (final sentence in sentencePicks) {
      final id = 'sentence.${sentence.id}';
      cards.add(
        existingById[id] ??
            ReviewCard(
              id: id,
              type: ReviewCardType.sentence,
              front: sentence.chinese,
              back: sentence.english,
              hint: '先完整回忆英文，再核对时间点、词块和语气。',
              sourceSentenceId: sentence.id,
              tags: [sentence.chunk, sentence.pattern],
              memoryLevel: 0,
              nextReviewAt: now,
              lastReviewedAt: '',
              sourcePackId: pack.id,
              sourcePackTitle: pack.title,
            ),
      );
    }

    return [...cards, ...personalCards];
  }

  int get _dueReviewCount {
    return _allReviewCards.where(_isCardDue).take(_dailyReviewLimit).length;
  }

  List<ReviewCard> get _allReviewCards {
    final cards = <ReviewCard>[];
    for (final entry in statesByPackId.entries) {
      final sourcePack = packById[entry.key];
      if (sourcePack == null) continue;
      cards.addAll(
        entry.value.reviewCards.map(
          (card) => card.copyWith(
            sourcePackId: sourcePack.id,
            sourcePackTitle: sourcePack.title,
          ),
        ),
      );
    }
    cards.sort((left, right) {
      if (left.isUserAdded != right.isUserAdded) {
        return left.isUserAdded ? -1 : 1;
      }
      final leftAt = DateTime.tryParse(left.nextReviewAt);
      final rightAt = DateTime.tryParse(right.nextReviewAt);
      if (leftAt == null && rightAt == null) return 0;
      if (leftAt == null) return -1;
      if (rightAt == null) return 1;
      return leftAt.compareTo(rightAt);
    });
    return cards;
  }

  bool _isCardDue(ReviewCard card) {
    if (card.nextReviewAt.isEmpty) return true;
    final next = DateTime.tryParse(card.nextReviewAt);
    if (next == null) return true;
    return !next.isAfter(DateTime.now());
  }

  int _nextIntervalDays(int level) {
    return 1;
  }

  Future<void> _applyPackAsToday(String nextPackId) async {
    if (nextPackId == currentPackId) {
      setState(() => tab = AppTab.today);
      return;
    }

    final currentState = state!;
    final previousPackId = currentPackId;
    final nextState = _stateForPack(nextPackId).resetForTodayPractice();
    final previousNextState = currentState.hasAnyPracticeProgress
        ? currentState.resetForTodayPractice()
        : currentState;

    await speech.stop();
    if (!mounted) return;

    setState(() {
      isPlaying = false;
      audioError = null;
      currentPackId = nextPackId;
      tab = AppTab.today;
      statesByPackId = {
        ...statesByPackId,
        previousPackId: previousNextState,
        nextPackId: nextState,
      };
    });

    _persistStateFor(previousPackId, previousNextState);
    _persistStateFor(nextPackId, nextState);
    await _persistCurrentPackId();
  }

  Future<void> _selectPackAsToday(ScenarioPack nextPack) async {
    final currentState = state!;
    final needsConfirmation =
        nextPack.id != currentPackId && currentState.hasAnyPracticeProgress;

    if (needsConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('切换今日练习？'),
            content: Text(
              '切换到“${nextPack.title}”后，当前素材的今日练习进度会被清空。复盘卡和已掌握状态会保留。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('先不切换'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确认切换'),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !mounted) return;
    }

    await _applyPackAsToday(nextPack.id);
  }

  @override
  Widget build(BuildContext context) {
    final current = state;
    if (current == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final body = IndexedStack(
      index: tab.index,
      children: [
        TodayPage(
          pack: pack,
          state: current,
          dueReviewCount: _dueReviewCount,
          isPlaying: isPlaying,
          audioError: audioError,
          onOpenWarmup: _startPracticeFromToday,
          onContinuePractice: () => setState(() => tab = AppTab.practice),
          onOpenReview: () => setState(() => tab = AppTab.review),
          onPlayPreview: () => _togglePlayLines(
            pack.sentences.map((item) => item.english).toList(),
          ),
          onOpenMeaning: _toggleMeaning,
          onSkipToReviewForTesting: _skipToReviewForTesting,
        ),
        PracticePage(
          pack: pack,
          state: current,
          reviewCards: current.reviewCards,
          isPlaying: isPlaying,
          audioError: audioError,
          onPlaySentence: () => _togglePlayText(
            pack.sentences[current.currentSentenceIndex].english,
          ),
          onPlayScenario: () => _togglePlayLines(
            pack.sentences.map((item) => item.english).toList(),
          ),
          onStopAudio: _stopAudio,
          onMarkShadowDone: _markShadowDone,
          onAdvanceFromKeywords: _advanceFromKeywords,
          onDictationChanged: _changeDictation,
          onRecallChanged: _changeRecall,
          onCheckDictation: _checkDictation,
          onCheckRecall: _checkRecall,
          onCompleteDictation: _completeDictationStep,
          onCompleteRecall: _completeRecallStep,
          onCompleteConsolidation: _completeConsolidation,
          onOpenReviewAfterCompletion: _openReviewAfterCompletion,
          onBackToTodayAfterCompletion: _backToTodayAfterCompletion,
          onAddFocusWord: () => _openPersonalFocusDialog(
            pack,
            pack.sentences[current.currentSentenceIndex],
          ),
        ),
        MaterialsPage(
          currentPackId: currentPackId,
          packs: VNextSampleData.packLibrary,
          statusByPackId: {
            for (final item in VNextSampleData.packLibrary)
              item.id: _statusForPack(item.id),
          },
          onSelectTodayPack: _selectPackAsToday,
          onAddFocusWord: _openPersonalFocusDialog,
        ),
        ReviewOverviewPage(
          cards: _allReviewCards,
          dailyLimit: _dailyReviewLimit,
          onRemembered: _markReviewRemembered,
          onNeedMorePractice: _markReviewNeedsPractice,
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 430
                ? constraints.maxWidth
                : 430.0;
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: body),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 130,
                      child: _BottomNavBackdrop(),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 14,
                      child: _BottomNav(
                        current: tab,
                        onSelect: (value) {
                          setState(() => tab = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

List<String> _wordChoices(String sentence) {
  final words = RegExp(
    r"[A-Za-z]+(?:'[A-Za-z]+)?",
  ).allMatches(sentence).map((match) => match.group(0)!).toList();
  final seen = <String>{};
  return [
    for (final word in words)
      if (seen.add(word.toLowerCase())) word,
  ];
}

String _normalizeFocusWord(String word) {
  return word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
}

class _BottomNavBackdrop extends StatelessWidget {
  const _BottomNavBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.page.withValues(alpha: 0),
              AppColors.page.withValues(alpha: 0.96),
              AppColors.page,
            ],
            stops: const [0, 0.38, 1],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: NavigationBar(
          height: 72,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: current.index,
          onDestinationSelected: (index) => onSelect(AppTab.values[index]),
          indicatorColor: AppColors.teal.withValues(alpha: 0.14),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: '今日',
              tooltip: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.mic_none),
              selectedIcon: Icon(Icons.mic),
              label: '练习',
              tooltip: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: '素材',
              tooltip: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.repeat_outlined),
              selectedIcon: Icon(Icons.repeat),
              label: '复盘',
              tooltip: '',
            ),
          ],
        ),
      ),
    );
  }
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
