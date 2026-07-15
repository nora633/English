import 'package:english_learning_app/main.dart';
import 'package:english_learning_app/src/data/vnext_sample_data.dart';
import 'package:english_learning_app/src/models/vnext_models.dart';
import 'package:english_learning_app/src/services/speech_service.dart';
import 'package:english_learning_app/src/views/keyword_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('material catalog contains 50 complete and unique practice packs', () {
    final packs = VNextSampleData.packLibrary;
    final categoryCounts = <String, int>{};
    final packIds = <String>{};
    final titles = <String>{};
    final sentenceIds = <String>{};
    final sentencesWithoutFocusWords = <String>[];
    final focusWordCounts = <int>{};
    final incompleteGeneratedDetails = <String>[];
    final enhancedWords = <String>{};
    final enhancedWordsByCategory = <String, Set<String>>{};
    final packsWithoutEnhancedWords = <String>[];
    const handcraftedPackIds = {
      'coffee-run-001',
      'rain-plan-001',
      'coworker-help-001',
    };

    expect(packs, hasLength(50));
    for (final pack in packs) {
      categoryCounts.update(
        pack.category,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      expect(packIds.add(pack.id), isTrue, reason: '素材 ID 重复：${pack.id}');
      expect(titles.add(pack.title), isTrue, reason: '素材标题重复：${pack.title}');
      expect(pack.summary.trim(), isNotEmpty);
      expect(pack.sceneDescription.trim(), isNotEmpty);
      expect(pack.reviewHeadline.trim(), isNotEmpty);
      expect(pack.sentences, hasLength(5), reason: pack.title);

      final packWords = pack.sentences
          .expand((sentence) => sentence.focusWords)
          .toList(growable: false);
      if (!packWords.any((word) => word.hasEnhancedDetails)) {
        packsWithoutEnhancedWords.add(pack.id);
      }

      final chunks = <String>{};
      for (final sentence in pack.sentences) {
        expect(
          sentenceIds.add(sentence.id),
          isTrue,
          reason: '句子 ID 重复：${sentence.id}',
        );
        expect(sentence.english.trim(), isNotEmpty);
        expect(sentence.chinese.trim(), isNotEmpty);
        expect(sentence.role.trim(), isNotEmpty);
        expect(sentence.scenePrompt.trim(), isNotEmpty);
        focusWordCounts.add(sentence.focusWords.length);
        if (sentence.focusWords.isEmpty) {
          sentencesWithoutFocusWords.add(
            '${pack.id}/${sentence.id}: ${sentence.keywords.map((item) => item.word).join(' | ')}',
          );
        }
        expect(sentence.chunk.trim(), isNotEmpty);
        expect(sentence.pattern.trim(), isNotEmpty);
        expect(sentence.dictationHint.trim(), isNotEmpty);
        expect(sentence.recallHint.trim(), isNotEmpty);
        expect(
          chunks.add(sentence.chunk.toLowerCase()),
          isTrue,
          reason: '${pack.title} 内重点词块重复：${sentence.chunk}',
        );
        for (final keyword in sentence.keywords) {
          expect(keyword.word.trim(), isNotEmpty);
          expect(keyword.meaning.trim(), isNotEmpty);
          expect(
            keyword.meaning,
            isNot(contains('词块核心词')),
            reason: '${sentence.id} 的 ${keyword.word} 缺少独立单词释义',
          );
          expect(keyword.example.trim(), isNotEmpty);
        }
        for (final word in sentence.focusWords) {
          expect(
            RegExp(r"^[A-Za-z]+(?:[-'][A-Za-z]+)*$").hasMatch(word.word),
            isTrue,
            reason: '${sentence.id} 把词组误放进了重点单词：${word.word}',
          );
          if (!handcraftedPackIds.contains(pack.id) &&
              (word.phonetic.isEmpty || word.partOfSpeech.isEmpty)) {
            incompleteGeneratedDetails.add('${pack.id}/${word.word}');
          }
          if (word.localizedCollocations.isNotEmpty) {
            expect(word.localizedCollocations.length, greaterThanOrEqualTo(2));
            for (final meaning in word.localizedCollocations.values) {
              expect(meaning.trim(), isNotEmpty);
              expect(
                RegExp(r'[\u4e00-\u9fff]').hasMatch(meaning),
                isTrue,
                reason: '${word.word} 的搭配缺少中文释义：$meaning',
              );
            }
            expect(
              word.localizedCollocations.keys,
              isNot(contains(word.example)),
              reason: '${word.word} 把完整原句重复成了常见搭配',
            );
          }
          if (word.hasEnhancedDetails) {
            enhancedWords.add(word.word);
            enhancedWordsByCategory
                .putIfAbsent(pack.category, () => <String>{})
                .add(word.word);
          }
        }
        expect(
          sentence.focusWords.map((word) => word.meaning).toSet().length,
          sentence.focusWords.length,
          reason: '${sentence.id} 的多个重点单词共用了同一释义',
        );
      }
    }

    expect(categoryCounts, {
      '日常表达': 15,
      '邻里 / 家庭 / 同事轻场景': 15,
      '情景剧灵感改写': 12,
      '轻信息类 / 轻新闻类': 8,
    });
    expect(sentencesWithoutFocusWords, isEmpty);
    expect(focusWordCounts.length, greaterThanOrEqualTo(3));
    expect(focusWordCounts.any((count) => count > 3), isTrue);
    expect(incompleteGeneratedDetails, isEmpty);
    expect(packsWithoutEnhancedWords, isEmpty);
    expect(enhancedWords.length, greaterThanOrEqualTo(70));
    for (final category in categoryCounts.keys) {
      expect(
        enhancedWordsByCategory[category]!.length,
        greaterThanOrEqualTo(15),
        reason: '$category 的重点词详情覆盖不足',
      );
    }

    final librarySentence = packs
        .firstWhere((pack) => pack.id == 'library-hours-001')
        .sentences
        .first;
    final libraryGlosses = {
      for (final word in librarySentence.focusWords) word.word: word.meaning,
    };
    expect(libraryGlosses['extending'], '延长、扩展');
    expect(libraryGlosses['evening'], '傍晚、晚间');
    expect(libraryGlosses['hours'], '小时；这里指开放时间');

    final weatherSentence = packs
        .firstWhere((pack) => pack.id == 'heatwave-tips-001')
        .sentences
        .first;
    final stretch = weatherSentence.focusWords.firstWhere(
      (word) => word.word == 'stretch',
    );
    expect(stretch.meaning, '持续的一段时间；一段区域');

    final hybridSentence = packs
        .firstWhere((pack) => pack.id == 'remote-work-survey-001')
        .sentences
        .first;
    final hybrid = hybridSentence.focusWords.firstWhere(
      (word) => word.word == 'hybrid',
    );
    expect(hybrid.phonetic, '/ˈhaɪbrɪd/');
    expect(hybrid.partOfSpeech, 'adj.');
    expect(hybrid.collocations, hasLength(3));
    expect(hybrid.localizedCollocations['hybrid work'], '混合办公');
    expect(hybrid.wordRoot, isNotEmpty);
    expect(hybrid.confusingPoint, contains('remote'));

    final restaurantsSentence = packs
        .firstWhere((pack) => pack.id == 'food-waste-001')
        .sentences
        .first;
    final restaurants = restaurantsSentence.focusWords.firstWhere(
      (word) => word.word == 'restaurants',
    );
    expect(restaurants.localizedCollocations, {
      'local restaurants': '当地餐馆',
      'restaurant chain': '连锁餐厅',
      'restaurant industry': '餐饮行业',
    });
    expect(restaurants.collocations, isNot(contains('restaurants are')));
  });

  test(
    'personal focus cards do not mark an unpracticed material as learned',
    () {
      final state = PracticeState.initial(5).copyWith(
        reviewCards: [
          _testReviewCard(
            id: 'personal-only',
            front: 'manageable',
            memoryLevel: 1,
            isUserAdded: true,
          ),
        ],
      );

      expect(state.materialStatus, MaterialStatus.unpracticed);
      expect(state.isFullyMastered, isFalse);
    },
  );

  testWidgets('keyword detail separates word audio from sentence context', (
    tester,
  ) async {
    final sentence = VNextSampleData.packLibrary
        .firstWhere((pack) => pack.id == 'library-hours-001')
        .sentences
        .first;
    final word = sentence.focusWords.firstWhere(
      (item) => item.word == 'extending',
    );

    await tester.binding.setSurfaceSize(const Size(430, 1200));
    await tester.pumpWidget(MaterialApp(home: KeywordDetailPage(word: word)));
    await tester.pumpAndSettle();

    expect(find.text('发音与词义'), findsOneWidget);
    expect(find.text('/ɪkˈstendɪŋ/'), findsOneWidget);
    expect(find.text('v.'), findsOneWidget);
    expect(find.text('延长、扩展'), findsOneWidget);
    expect(find.text('听单词'), findsOneWidget);
    expect(find.text('原句语境'), findsOneWidget);
    expect(find.text('听原句'), findsOneWidget);
    expect(find.text('构词'), findsOneWidget);
    expect(find.text('extend opening hours'), findsOneWidget);
    expect(find.text('延长开放时间'), findsOneWidget);
    expect(find.text('易混点'), findsOneWidget);
    expect(find.text('随句听读'), findsNothing);
  });

  testWidgets('shows warmup entry on first launch', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('今日'), findsWidgets);
    expect(find.text('开始练习'), findsOneWidget);
    expect(find.text('今天 5 句'), findsOneWidget);
    expect(find.text('播放今天 5 句'), findsOneWidget);
  });

  testWidgets('can move from today to practice and open keyword detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('开始练习'));
    await tester.pumpAndSettle();

    expect(find.text('第 1 / 5 句'), findsOneWidget);
    expect(find.text('我正准备去买点咖啡。'), findsOneWidget);
    expect(find.text('添加本句重点词'), findsOneWidget);
    await tester.tap(find.text('今日'));
    await tester.pumpAndSettle();
    expect(find.text('查看意思'), findsOneWidget);
    expect(find.text('收起意思'), findsNothing);
    expect(find.text('这个场景重点练自然开场、顺手询问、确认安排。'), findsNothing);

    await tester.tap(find.text('查看意思'));
    await tester.pumpAndSettle();
    expect(find.text('收起意思'), findsOneWidget);
    expect(find.text('这个场景重点练自然开场、顺手询问、确认安排。'), findsOneWidget);
    await tester.tap(find.text('收起意思'));
    await tester.pumpAndSettle();
    expect(find.text('查看意思'), findsOneWidget);
    expect(find.text('这个场景重点练自然开场、顺手询问、确认安排。'), findsNothing);

    await tester.tap(find.text('开始练习'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('已听读，下一步'));
    await tester.pumpAndSettle();
    expect(find.text('添加本句重点词'), findsNothing);
    expect(find.text('重点单词'), findsOneWidget);
    expect(find.text('重点词块'), findsOneWidget);
    expect(find.text('句型结构'), findsOneWidget);
    await tester.tap(find.text('grab'));
    await tester.pumpAndSettle();
    expect(find.text('构词'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('我看完了，开始听写'), findsOneWidget);
  });

  testWidgets('shows consolidation before review after five sentences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.practice.coffee-run-001': encodePracticeState(
        PracticeState(
          warmupMeaningOpened: true,
          currentSentenceIndex: 4,
          currentStep: PracticeStep.recall,
          flowStage: PracticeFlowStage.consolidation,
          sentences: List<SentenceProgress>.filled(
            5,
            const SentenceProgress(
              shadowDone: true,
              dictationDone: true,
              recallDone: true,
            ),
          ),
          reviewCards: [
            _testReviewCard(
              id: 'custom.keyword.s1.grab',
              front: 'grab',
              isUserAdded: true,
            ),
          ],
          completed: false,
          lastCompletedDate: '',
        ),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 1200));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('练习'));
    await tester.pumpAndSettle();

    expect(find.text('整段巩固'), findsOneWidget);
    expect(find.text('我顺完了，完成今天练习'), findsOneWidget);

    await tester.tap(find.text('我顺完了，完成今天练习'));
    await tester.pumpAndSettle();

    expect(find.text('今日提炼'), findsOneWidget);
    expect(find.text('进入复盘'), findsOneWidget);
    expect(find.text('关键词 4'), findsOneWidget);
  });

  testWidgets('review cards can be revealed and marked remembered', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.practice.coffee-run-001': encodePracticeState(
        PracticeState(
          warmupMeaningOpened: true,
          currentSentenceIndex: 4,
          currentStep: PracticeStep.listen,
          flowStage: PracticeFlowStage.completion,
          sentences: List<SentenceProgress>.filled(
            5,
            const SentenceProgress(
              shadowDone: true,
              dictationDone: true,
              recallDone: true,
            ),
          ),
          reviewCards: const [
            ReviewCard(
              id: 'sentence.s1',
              type: ReviewCardType.sentence,
              front: '我正准备去买点咖啡。',
              back: 'I was about to grab some coffee.',
              hint: '先完整回忆英文。',
              sourceSentenceId: 's1',
              tags: ['grab some coffee'],
              memoryLevel: 0,
              nextReviewAt: '2026-07-10T00:00:00.000',
              lastReviewedAt: '',
            ),
          ],
          completed: true,
          lastCompletedDate: '2026-07-10',
        ),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 1200));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();

    expect(find.text('已学内容'), findsOneWidget);
    expect(find.text('翻开答案'), findsOneWidget);

    await tester.tap(find.text('已学内容'));
    await tester.pumpAndSettle();
    expect(find.text('未掌握'), findsOneWidget);
    expect(find.text('已掌握'), findsWidgets);
    expect(find.text('我正准备去买点咖啡。'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '词块'));
    await tester.pumpAndSettle();
    expect(find.text('这个分类里没有需要继续巩固的内容。'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('复盘练习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('翻开答案'));
    await tester.pumpAndSettle();
    expect(find.text('I was about to grab some coffee.'), findsOneWidget);

    await tester.tap(find.text('想起来了'));
    await tester.pumpAndSettle();
    expect(find.text('今天没有到期卡片'), findsOneWidget);

    await tester.tap(find.text('已学内容'));
    await tester.pumpAndSettle();
    expect(find.text('已学素材已全部掌握'), findsOneWidget);
    expect(find.text('我正准备去买点咖啡。'), findsNothing);
  });

  testWidgets('revealing one review card does not reveal other cards', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.practice.coffee-run-001': encodePracticeState(
        PracticeState(
          warmupMeaningOpened: true,
          currentSentenceIndex: 4,
          currentStep: PracticeStep.listen,
          flowStage: PracticeFlowStage.completion,
          sentences: List<SentenceProgress>.filled(
            5,
            const SentenceProgress(
              shadowDone: true,
              dictationDone: true,
              recallDone: true,
            ),
          ),
          reviewCards: const [
            ReviewCard(
              id: 'sentence.s1',
              type: ReviewCardType.sentence,
              front: '我正准备去买点咖啡。',
              back: 'I was about to grab some coffee.',
              hint: '先完整回忆英文。',
              sourceSentenceId: 's1',
              tags: ['grab some coffee'],
              memoryLevel: 0,
              nextReviewAt: '2026-07-10T00:00:00.000',
              lastReviewedAt: '',
            ),
            ReviewCard(
              id: 'sentence.s2',
              type: ReviewCardType.sentence,
              front: '你要不要我顺便带点什么？',
              back: 'Do you want anything?',
              hint: '先完整回忆英文。',
              sourceSentenceId: 's2',
              tags: ['want anything'],
              memoryLevel: 0,
              nextReviewAt: '2026-07-10T00:00:00.000',
              lastReviewedAt: '',
            ),
          ],
          completed: true,
          lastCompletedDate: '2026-07-10',
        ),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 1400));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    expect(find.text('翻开答案'), findsNWidgets(2));

    await tester.tap(find.text('翻开答案').first);
    await tester.pumpAndSettle();

    expect(find.text('I was about to grab some coffee.'), findsOneWidget);
    expect(find.text('Do you want anything?'), findsNothing);
    expect(find.text('翻开答案'), findsOneWidget);
  });

  testWidgets('unified review queue includes cards from every learned pack', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.current_pack_id': 'coffee-run-001',
      'vnext.practice.coffee-run-001': encodePracticeState(
        _completedStateWithCards([
          _testReviewCard(id: 'coffee-card', front: 'coffee review'),
        ]),
      ),
      'vnext.practice.rain-plan-001': encodePracticeState(
        _completedStateWithCards([
          _testReviewCard(id: 'rain-card', front: 'rain review'),
        ]),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 1400));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('先复习今天到期内容'), findsOneWidget);
    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();

    expect(find.text('统一复盘队列'), findsOneWidget);
    expect(find.text('coffee review'), findsOneWidget);
    expect(find.text('rain review'), findsOneWidget);
    expect(find.text('来源：邻居下楼买咖啡'), findsOneWidget);
    expect(find.text('来源：下雨临时改约'), findsOneWidget);
  });

  testWidgets('unified review queue caps daily practice at ten cards', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.practice.coffee-run-001': encodePracticeState(
        _completedStateWithCards([
          for (var i = 0; i < 6; i++)
            _testReviewCard(id: 'coffee-$i', front: 'coffee $i'),
        ]),
      ),
      'vnext.practice.rain-plan-001': encodePracticeState(
        _completedStateWithCards([
          for (var i = 0; i < 6; i++)
            _testReviewCard(id: 'rain-$i', front: 'rain $i'),
        ]),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 5000));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();

    expect(find.text('今日复盘 10'), findsOneWidget);
    expect(find.text('全部到期 12'), findsOneWidget);
    expect(find.textContaining('另有 2 张已到期卡片顺延'), findsOneWidget);
    expect(find.text('翻开答案'), findsNWidgets(10));
    expect(find.text('卡片 10/10'), findsOneWidget);
  });

  testWidgets('review result is saved back to the non-current source pack', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.current_pack_id': 'coffee-run-001',
      'vnext.practice.rain-plan-001': encodePracticeState(
        _completedStateWithCards([
          _testReviewCard(id: 'rain-only', front: 'rain source card'),
        ]),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 1400));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('翻开答案'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('想起来了'));
    await tester.pumpAndSettle();
    expect(find.text('今天没有到期卡片'), findsOneWidget);

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();
    expect(find.text('已掌握'), findsOneWidget);
  });

  testWidgets('mastered card returns after its next review date', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.practice.rain-plan-001': encodePracticeState(
        _completedStateWithCards([
          _testReviewCard(
            id: 'mastered-due',
            front: 'mastered but due',
            memoryLevel: 1,
            nextReviewAt: '2026-07-01T00:00:00.000',
          ),
        ]),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 1400));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();

    expect(find.text('mastered but due'), findsOneWidget);
    expect(find.text('今日复盘 1'), findsOneWidget);
  });

  testWidgets('hides continue practice button after today is completed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.practice.coffee-run-001': encodePracticeState(
        PracticeState(
          warmupMeaningOpened: true,
          currentSentenceIndex: 4,
          currentStep: PracticeStep.listen,
          flowStage: PracticeFlowStage.completion,
          sentences: List<SentenceProgress>.filled(
            5,
            const SentenceProgress(
              shadowDone: true,
              dictationDone: true,
              recallDone: true,
            ),
          ),
          reviewCards: const [
            ReviewCard(
              id: 'sentence.s1',
              type: ReviewCardType.sentence,
              front: '我正准备去买点咖啡。',
              back: 'I was about to grab some coffee.',
              hint: '先完整回忆英文。',
              sourceSentenceId: 's1',
              tags: ['grab some coffee'],
              memoryLevel: 0,
              nextReviewAt: '2026-07-10T00:00:00.000',
              lastReviewedAt: '',
            ),
          ],
          completed: true,
          lastCompletedDate: '2026-07-10',
        ),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 1200));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('先复习今天到期内容'), findsOneWidget);
    expect(find.text('继续今天新练习'), findsNothing);
  });

  testWidgets('unmastered learned card opens detail for review', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.practice.coffee-run-001': encodePracticeState(
        PracticeState(
          warmupMeaningOpened: true,
          currentSentenceIndex: 4,
          currentStep: PracticeStep.listen,
          flowStage: PracticeFlowStage.completion,
          sentences: List<SentenceProgress>.filled(
            5,
            const SentenceProgress(
              shadowDone: true,
              dictationDone: true,
              recallDone: true,
            ),
          ),
          reviewCards: const [
            ReviewCard(
              id: 'sentence.s1',
              type: ReviewCardType.sentence,
              front: '我正准备去买点咖啡。',
              back: 'I was about to grab some coffee.',
              hint: '先完整回忆英文。',
              sourceSentenceId: 's1',
              tags: ['grab some coffee'],
              memoryLevel: 0,
              nextReviewAt: '2026-07-10T00:00:00.000',
              lastReviewedAt: '',
            ),
          ],
          completed: true,
          lastCompletedDate: '2026-07-10',
        ),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 1200));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('已学内容'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我正准备去买点咖啡。'));
    await tester.pumpAndSettle();

    expect(find.text('卡片复习'), findsOneWidget);
    await tester.tap(find.text('翻开答案'));
    await tester.pumpAndSettle();
    expect(find.text('I was about to grab some coffee.'), findsOneWidget);

    await tester.tap(find.text('想起来了'));
    await tester.pumpAndSettle();
    expect(find.text('已学素材已全部掌握'), findsOneWidget);
    expect(find.text('我正准备去买点咖啡。'), findsNothing);
  });

  testWidgets('materials page opens pack detail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();

    expect(find.text('素材库'), findsNothing);
    expect(find.text('全部'), findsWidgets);
    expect(find.text('日常'), findsOneWidget);
    expect(find.text('轻场景'), findsWidgets);
    expect(find.text('情景剧'), findsOneWidget);
    expect(find.text('轻信息'), findsOneWidget);
    expect(find.text('今日练习'), findsOneWidget);
    expect(find.text('难易程度'), findsWidgets);
    expect(find.text('下雨临时改约'), findsOneWidget);
    expect(find.text('started pouring outside'), findsNothing);

    await tester.tap(find.text('轻场景').first);
    await tester.pumpAndSettle();

    expect(find.text('邻居下楼买咖啡'), findsOneWidget);
    expect(find.text('同事请你帮忙看一眼'), findsOneWidget);

    await tester.tap(find.text('日常'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('下雨临时改约'));
    await tester.pumpAndSettle();

    expect(find.text('素材详情'), findsNothing);
    expect(find.text('5 句总览'), findsOneWidget);
    expect(find.text('It just started pouring outside.'), findsOneWidget);
    expect(find.text('重点表达'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
    expect(find.text('设为今日练习'), findsOneWidget);
  });

  testWidgets('adds a personal focus word from any material sentence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日常'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下雨临时改约'));
    await tester.pumpAndSettle();

    expect(find.text('添加重点词'), findsNWidgets(5));
    await tester.tap(find.text('添加重点词').first);
    await tester.pumpAndSettle();
    expect(find.text('每个素材最多自选 5 个，当前 0/5。'), findsOneWidget);

    expect(find.widgetWithText(ChoiceChip, 'pouring'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'outside'));
    await tester.enterText(find.byType(TextField), '倾盆大雨');
    await tester.tap(find.text('加入复盘'));
    await tester.pumpAndSettle();

    expect(find.text('已将 outside 加入统一复盘'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'outside'), findsOneWidget);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();

    expect(find.text('outside'), findsOneWidget);
    expect(find.text('来源：下雨临时改约'), findsOneWidget);
    expect(find.text('自选'), findsOneWidget);
  });

  testWidgets('switches today pack directly when no practice progress', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日常'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下雨临时改约'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('设为今日练习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设为今日练习'));
    await tester.pumpAndSettle();

    expect(find.text('下雨临时改约'), findsOneWidget);
    expect(find.text('你和朋友原本约好出门，但突然下雨，需要自然地改时间。'), findsOneWidget);
    expect(find.text('开始练习'), findsOneWidget);
  });

  testWidgets('confirms before switching when current pack has progress', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.practice.coffee-run-001': encodePracticeState(
        PracticeState(
          warmupMeaningOpened: true,
          currentSentenceIndex: 0,
          currentStep: PracticeStep.keywords,
          flowStage: PracticeFlowStage.practice,
          sentences: const [
            SentenceProgress(shadowDone: true),
            SentenceProgress(),
            SentenceProgress(),
            SentenceProgress(),
            SentenceProgress(),
          ],
          reviewCards: const [],
          completed: false,
          lastCompletedDate: '',
        ),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 1400));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日常'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下雨临时改约'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('设为今日练习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设为今日练习'));
    await tester.pumpAndSettle();

    expect(find.text('切换今日练习？'), findsOneWidget);
    expect(find.textContaining('当前素材的今日练习进度会被清空'), findsOneWidget);

    await tester.tap(find.text('确认切换'));
    await tester.pumpAndSettle();

    expect(find.text('下雨临时改约'), findsOneWidget);
    expect(find.text('开始练习'), findsOneWidget);
  });

  testWidgets('shows material status labels from practice history', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'vnext.practice.coffee-run-001': encodePracticeState(
        PracticeState(
          warmupMeaningOpened: false,
          currentSentenceIndex: 0,
          currentStep: PracticeStep.keywords,
          flowStage: PracticeFlowStage.practice,
          sentences: const [
            SentenceProgress(shadowDone: true),
            SentenceProgress(),
            SentenceProgress(),
            SentenceProgress(),
            SentenceProgress(),
          ],
          reviewCards: const [],
          completed: false,
          lastCompletedDate: '',
        ),
      ),
      'vnext.practice.rain-plan-001': encodePracticeState(
        PracticeState(
          warmupMeaningOpened: true,
          currentSentenceIndex: 4,
          currentStep: PracticeStep.listen,
          flowStage: PracticeFlowStage.completion,
          sentences: List<SentenceProgress>.filled(
            5,
            const SentenceProgress(
              shadowDone: true,
              dictationDone: true,
              recallDone: true,
            ),
          ),
          reviewCards: const [
            ReviewCard(
              id: 'sentence.r1',
              type: ReviewCardType.sentence,
              front: '外面刚开始下大雨。',
              back: 'It just started pouring outside.',
              hint: '先完整回忆英文。',
              sourceSentenceId: 'r1',
              tags: ['started pouring outside'],
              memoryLevel: 0,
              nextReviewAt: '2026-07-10T00:00:00.000',
              lastReviewedAt: '',
            ),
          ],
          completed: true,
          lastCompletedDate: '2026-07-10',
        ),
      ),
      'vnext.practice.coworker-help-001': encodePracticeState(
        PracticeState(
          warmupMeaningOpened: true,
          currentSentenceIndex: 4,
          currentStep: PracticeStep.listen,
          flowStage: PracticeFlowStage.completion,
          sentences: List<SentenceProgress>.filled(
            5,
            const SentenceProgress(
              shadowDone: true,
              dictationDone: true,
              recallDone: true,
            ),
          ),
          reviewCards: const [
            ReviewCard(
              id: 'sentence.c1',
              type: ReviewCardType.sentence,
              front: '你能快速帮我看一眼这个吗？',
              back: 'Could you take a quick look at this?',
              hint: '先完整回忆英文。',
              sourceSentenceId: 'c1',
              tags: ['take a quick look'],
              memoryLevel: 1,
              nextReviewAt: '2026-07-14T00:00:00.000',
              lastReviewedAt: '2026-07-13T00:00:00.000',
            ),
          ],
          completed: true,
          lastCompletedDate: '2026-07-10',
        ),
      ),
    });

    await tester.binding.setSurfaceSize(const Size(430, 1400));
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();

    expect(find.text('练习中'), findsWidgets);
    expect(find.text('已练过'), findsOneWidget);
    expect(find.text('已掌握'), findsOneWidget);
  });
}

PracticeState _completedStateWithCards(List<ReviewCard> cards) {
  return PracticeState(
    warmupMeaningOpened: true,
    currentSentenceIndex: 4,
    currentStep: PracticeStep.listen,
    flowStage: PracticeFlowStage.completion,
    sentences: List<SentenceProgress>.filled(
      5,
      const SentenceProgress(
        shadowDone: true,
        dictationDone: true,
        recallDone: true,
      ),
    ),
    reviewCards: cards,
    completed: true,
    lastCompletedDate: '2026-07-12',
  );
}

ReviewCard _testReviewCard({
  required String id,
  required String front,
  int memoryLevel = 0,
  String nextReviewAt = '2026-07-01T00:00:00.000',
  bool isUserAdded = false,
}) {
  return ReviewCard(
    id: id,
    type: ReviewCardType.keyword,
    front: front,
    back: '$front answer',
    hint: '先回忆答案。',
    sourceSentenceId: 'source-$id',
    tags: const [],
    memoryLevel: memoryLevel,
    nextReviewAt: nextReviewAt,
    lastReviewedAt: '',
    isUserAdded: isUserAdded,
  );
}

Widget testApp() {
  return const EnglishLearningApp(speechClient: FakeSpeechClient());
}

class FakeSpeechClient implements SpeechClient {
  const FakeSpeechClient();

  @override
  Future<void> speak(String text, {required String locale}) async {}

  @override
  Future<void> speakLines(List<String> texts, {required String locale}) async {}

  @override
  Future<void> stop() async {}
}
