import 'package:english_learning_app/main.dart';
import 'package:english_learning_app/src/data/sample_data.dart';
import 'package:english_learning_app/src/models/learning_models.dart';
import 'package:english_learning_app/src/services/audio_player_service.dart';
import 'package:english_learning_app/src/services/audio_recorder_service.dart';
import 'package:english_learning_app/src/services/custom_material_store.dart';
import 'package:english_learning_app/src/services/daily_lesson_service.dart';
import 'package:english_learning_app/src/services/exercise_check_service.dart';
import 'package:english_learning_app/src/services/learning_preferences_store.dart';
import 'package:english_learning_app/src/services/lesson_history_store.dart';
import 'package:english_learning_app/src/services/local_progress_store.dart';
import 'package:english_learning_app/src/services/material_activity_store.dart';
import 'package:english_learning_app/src/services/review_queue_store.dart';
import 'package:english_learning_app/src/services/speech_service.dart';
import 'package:english_learning_app/src/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the cross-platform learning shell', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('今日学习'), findsOneWidget);
    expect(find.text('今日'), findsOneWidget);
    expect(find.text('素材'), findsOneWidget);
    expect(find.text('跟读'), findsOneWidget);
    expect(find.text('翻译'), findsOneWidget);
    expect(find.text('复盘'), findsOneWidget);
  });

  testWidgets('updates today progress after saving a recording', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('完成进度 0/15 分钟'), findsOneWidget);

    await tester.tap(find.text('跟读'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('开始录音'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始录音'));
    await tester.pump();
    await tester.tap(find.text('停止录音'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存录音'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日'));
    await tester.pumpAndSettle();

    expect(find.text('完成进度 5/15 分钟'), findsOneWidget);
  });

  testWidgets('shows recording draft state while practicing speaking', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('跟读'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始录音'));
    await tester.pump();

    expect(find.text('正在录音 00:00'), findsOneWidget);
    expect(find.text('先播放原句，再录自己的声音；录音只保存在本机。'), findsOneWidget);

    await tester.tap(find.text('停止录音'));
    await tester.pumpAndSettle();

    expect(find.text('录音已停止，可以保存或回放'), findsOneWidget);
    expect(find.text('录音已保存：test-recording.m4a'), findsOneWidget);
    expect(find.text('播放录音'), findsOneWidget);
    expect(find.text('保存录音'), findsOneWidget);
  });

  testWidgets('loads saved local progress when the app starts', (tester) async {
    final dateKey = const LocalProgressStore().dateKey;
    SharedPreferences.setMockInitialValues({
      'daily.$dateKey.recordingCompleted': true,
      'daily.$dateKey.dictationCompleted': false,
      'daily.$dateKey.recallCompleted': false,
    });

    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('完成进度 5/15 分钟'), findsOneWidget);
  });

  test('local progress is separated by date', () async {
    SharedPreferences.setMockInitialValues({});
    final todayStore = LocalProgressStore(today: () => DateTime(2026, 7, 2));
    final tomorrowStore = LocalProgressStore(today: () => DateTime(2026, 7, 3));

    await todayStore.save(
      const LocalProgress(
        recordingCompleted: true,
        dictationCompleted: false,
        recallCompleted: false,
      ),
    );

    expect((await todayStore.load()).completedMinutes, 5);
    expect((await tomorrowStore.load()).completedMinutes, 0);
  });

  test('local stats include streak, history, and trouble spots', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalProgressStore(today: () => DateTime(2026, 7, 2));

    await store.save(
      const LocalProgress(
        recordingCompleted: true,
        dictationCompleted: true,
        recallCompleted: true,
      ),
    );

    final stats = await store.loadStats();

    expect(stats.streakDays, 1);
    expect(stats.totalMinutes, 15);
    expect(stats.history.single.date, '2026-07-02');
    expect(stats.history.single.completed, isTrue);
    expect(stats.savedTroubleSpots, contains('anything'));
    expect(
      stats.savedTroubleSpots,
      contains('Do you want me to text you when I get there?'),
    );
  });

  test('local progress can be exported and imported as a backup', () async {
    SharedPreferences.setMockInitialValues({});
    final sourceStore = LocalProgressStore(today: () => DateTime(2026, 7, 2));

    await sourceStore.save(
      const LocalProgress(
        recordingCompleted: true,
        dictationCompleted: true,
        recallCompleted: false,
      ),
    );

    final backup = await sourceStore.exportBackup();

    SharedPreferences.setMockInitialValues({});
    final targetStore = LocalProgressStore(today: () => DateTime(2026, 7, 2));
    await targetStore.importBackup(backup);

    final importedProgress = await targetStore.load();
    final importedStats = await targetStore.loadStats();

    expect(importedProgress.completedMinutes, 10);
    expect(importedStats.totalMinutes, 10);
    expect(importedStats.history.single.date, '2026-07-02');
  });

  test('remote translation service parses AI backend response', () async {
    final service = RemoteTranslationService(
      baseUrl: 'http://localhost:8787',
      clientFactory: () => MockClient((request) async {
        expect(request.url.path, '/api/translate');
        return http.Response(
          '''
          {
            "source": "我想要一杯咖啡",
            "english": "I'd like a cup of coffee.",
            "koreanHonorific": "커피 한 잔 주세요.",
            "koreanCasual": "커피 한 잔 줘.",
            "koreanPronunciation": "keo-pi han jan ju-se-yo / keo-pi han jan jwo",
            "usageNote": "点单时这样说更自然。"
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await service.translate('我想要一杯咖啡');

    expect(result.english, "I'd like a cup of coffee.");
    expect(result.koreanHonorific, '커피 한 잔 주세요.');
    expect(result.koreanPronunciation, contains('ju-se-yo'));
  });

  test('remote exercise check service parses AI backend response', () async {
    final service = RemoteExerciseCheckService(
      baseUrl: 'http://localhost:8787',
      clientFactory: () => MockClient((request) async {
        expect(request.url.path, '/api/check-dictation');
        return http.Response(
          '''
          {
            "score": 86,
            "level": "pass",
            "summary": "大意正确，但漏了 anything。",
            "reference": "I was about to grab some coffee. Do you want anything?",
            "correctedAnswer": "I was about to grab some coffee. Do you want anything?",
            "issues": ["缺少 anything"],
            "suggestions": ["再听一遍句尾。"]
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await service.check(
      mode: ExerciseCheckMode.dictation,
      target: 'I was about to grab some coffee. Do you want anything?',
      answer: 'I was about to grab some coffee.',
    );

    expect(result.score, 86);
    expect(result.level, ExerciseCheckLevel.pass);
    expect(result.issues, contains('缺少 anything'));
  });

  test('local exercise check highlights missing words', () {
    final result = const LocalExerciseCheckService().check(
      mode: ExerciseCheckMode.dictation,
      target: 'I was about to grab some coffee. Do you want anything?',
      answer: 'I was about to grab coffee',
    );

    expect(result.score, lessThan(100));
    expect(result.issues.join(' '), contains('anything'));
    expect(result.reference, contains('Do you want anything'));
  });

  test('remote daily lesson service parses AI backend response', () async {
    final service = RemoteDailyLessonService(
      baseUrl: 'http://localhost:8787',
      clientFactory: () => MockClient((request) async {
        expect(request.url.path, '/api/generate-daily-lesson');
        return http.Response(
          '''
          {
            "title": "今日 15 分钟听说训练",
            "durationMinutes": 15,
            "completedMinutes": 0,
            "theme": {
              "title": "电梯偶遇",
              "stage": "daily",
              "kind": "dailyLife",
              "sourceHint": "AI 生成生活场景",
              "focus": "寒暄、回应、顺手帮忙",
              "difficulty": "A2-B1",
              "previewTitle": "电梯里偶遇邻居",
              "previewDescription": "短暂寒暄并顺手提供帮助。",
              "sampleContent": "A: Morning. Are you heading out?\\nB: Yes, I am grabbing coffee.",
              "practiceSentences": ["Are you heading out?", "I am grabbing coffee."],
              "keyVocabulary": ["heading out", "grab", "neighbor"]
            },
            "keyWords": [
              {
                "word": "heading out",
                "phonetic": "/ˈhedɪŋ aʊt/",
                "meaning": "准备出门",
                "usage": "日常问对方是不是要出门",
                "example": "Are you heading out?",
                "priority": "必练",
                "wordRoot": "head 表示朝某方向去",
                "memoryHint": "头已经朝门口了，就是准备出门。",
                "collocations": ["head out", "head downstairs"],
                "relatedWords": ["leave", "go out"],
                "confusingPoint": "head out 比 leave 更口语。"
              }
            ],
            "grammarPoints": [
              {
                "pattern": "Are you + 动词 ing?",
                "meaning": "你正在/准备做某事吗？",
                "example": "Are you heading out?",
                "note": "日常寒暄很自然。"
              }
            ],
            "targetChunks": ["Are you heading out?"],
            "listeningLines": [
              "Are you heading out?",
              "I am grabbing coffee before work.",
              "Do you want me to bring you one?",
              "That would be great, thanks.",
              "I will text you when I get back."
            ]
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final lesson = await service.generate(
      stats: const LocalLearningStats.empty(),
      preferredStage: LearningStage.daily,
    );

    expect(lesson.theme.title, '电梯偶遇');
    expect(lesson.listeningLines, hasLength(5));
    expect(lesson.keyWords.first.word, 'heading out');
  });

  test('local daily lesson uses selected theme content', () {
    final service = const LocalDailyLessonService();
    final lesson = service.generateFromTheme(SampleData.themes[1]);

    expect(lesson.theme.title, '家庭晚餐小插曲');
    expect(lesson.listeningLines, contains('I got held up after class.'));
    expect(
      lesson.listeningLines,
      isNot(contains('I was about to grab some coffee. Do you want anything?')),
    );
    expect(lesson.keyWords.map((word) => word.word), contains('held up'));
  });

  test('reference episode cards generate original practice lessons', () {
    final service = const LocalDailyLessonService();
    final episodeSix = SampleData.themes.firstWhere(
      (theme) => theme.title.contains('S01E06'),
    );
    final episodeSeven = SampleData.themes.firstWhere(
      (theme) => theme.title.contains('S01E07'),
    );

    final lessonSix = service.generateFromTheme(episodeSix);
    final lessonSeven = service.generateFromTheme(episodeSeven);

    expect(episodeSix.sourceHint, contains('不保存原台词'));
    expect(episodeSeven.sourceHint, contains('不保存原台词'));
    expect(lessonSix.listeningLines.first, contains('trying to help'));
    expect(lessonSix.keyWords.map((word) => word.word), contains('meant well'));
    expect(lessonSeven.listeningLines.first, contains('block party'));
    expect(
      lessonSeven.keyWords.map((word) => word.word),
      contains('count me in'),
    );
  });

  test('material activity store keeps favorites and usage history', () async {
    final store = MaterialActivityStore(now: () => DateTime(2026, 7, 8, 9));
    final theme = SampleData.themes.firstWhere(
      (theme) => theme.title == '咖啡店偶遇',
    );

    final favorited = await store.toggleFavorite(theme);
    expect(favorited.isFavorite(theme), isTrue);

    final used = await store.recordUse(theme);
    expect(used.history.single.themeTitle, '咖啡店偶遇');
    expect(used.recentUsedTitles(), contains('咖啡店偶遇'));

    final unfavorited = await store.toggleFavorite(theme);
    expect(unfavorited.isFavorite(theme), isFalse);
    expect(unfavorited.history.single.themeTitle, '咖啡店偶遇');
  });

  test('custom material store saves pasted themes locally', () async {
    final store = const CustomMaterialStore();
    final theme = LearningTheme(
      title: '机场问路片段',
      stage: LearningStage.daily,
      kind: ContentKind.dailyLife,
      sourceHint: '手动粘贴素材',
      focus: '问路和确认方向',
      difficulty: 'A2-B1',
      previewTitle: '你保存的短片段',
      previewDescription: '本地保存的手动素材',
      sampleContent: 'Could you tell me where gate B12 is?',
      practiceSentences: const ['Could you tell me where gate B12 is?'],
      keyVocabulary: const ['could', 'tell', 'gate'],
    );

    final saved = await store.save(theme);
    final loaded = await store.load();

    expect(saved.single.title, '机场问路片段');
    expect(loaded.single.sampleContent, contains('gate B12'));
  });

  test('learning preferences store saves goal and preferred stage', () async {
    const store = LearningPreferencesStore();

    final saved = await store.save(
      const LearningPreferences(
        dailyGoalMinutes: 10,
        preferredStage: LearningStage.media,
      ),
    );
    final loaded = await store.load();

    expect(saved.dailyGoalMinutes, 10);
    expect(loaded.dailyGoalMinutes, 10);
    expect(loaded.preferredStage, LearningStage.media);
  });

  test('review queue stores lesson expressions and supports mastery', () async {
    final store = ReviewQueueStore(now: () => DateTime(2026, 7, 8, 9));

    final added = await store.addLesson(SampleData.todayLesson);
    expect(added.map((item) => item.text), contains('grab'));
    expect(added.map((item) => item.text), contains('I was about to...'));
    expect(
      added.map((item) => item.text),
      contains('I was about to grab some coffee. Do you want anything?'),
    );

    final searched = store.search(added, 'grab');
    expect(searched, isNotEmpty);
    expect(searched.every((item) => item.mastered == false), isTrue);

    final mastered = await store.markMastered(searched.first.id);
    expect(
      mastered.firstWhere((item) => item.id == searched.first.id).mastered,
      isTrue,
    );
  });

  test('review queue can be exported and imported', () async {
    final sourceStore = ReviewQueueStore(now: () => DateTime(2026, 7, 8, 9));
    await sourceStore.addLesson(SampleData.todayLesson);
    final exported = await sourceStore.exportItems();

    SharedPreferences.setMockInitialValues({});
    const targetStore = ReviewQueueStore();
    await targetStore.importItems(exported);
    final imported = await targetStore.load();

    expect(imported.map((item) => item.text), contains('grab'));
    expect(imported.map((item) => item.text), contains('I was about to...'));
  });

  test('lesson history stores and searches practiced lessons', () async {
    final store = LessonHistoryStore(now: () => DateTime(2026, 7, 8, 9));

    final history = await store.recordLesson(
      lesson: SampleData.todayLesson,
      sourceLabel: '本地推荐',
    );
    expect(history.single.lesson.theme.title, '邻里寒暄');
    expect(store.search(history, 'grab'), hasLength(1));
    expect(store.search(history, 'not-found'), isEmpty);

    final exported = await store.exportItems();
    SharedPreferences.setMockInitialValues({});
    const targetStore = LessonHistoryStore();
    await targetStore.importItems(exported);
    final imported = await targetStore.load();
    expect(imported.single.lesson.listeningLines.first, contains('coffee'));
  });

  test('local daily recommendation avoids recently used materials', () {
    final service = const LocalDailyLessonService();
    final lesson = service.generate(
      stats: const LocalLearningStats.empty(),
      preferredStage: LearningStage.daily,
      materialState: MaterialActivityState(
        favoriteTitles: const [],
        history: [
          MaterialUsageRecord(
            themeTitle: SampleData.themes.first.title,
            stage: LearningStage.daily,
            kind: ContentKind.sitcom,
            usedAt: DateTime(2026, 7, 8),
          ),
        ],
      ),
    );

    expect(lesson.theme.title, '咖啡店偶遇');
  });

  test('local daily recommendation can use custom favorite materials', () {
    final customTheme = LearningTheme(
      title: '机场问路片段',
      stage: LearningStage.daily,
      kind: ContentKind.dailyLife,
      sourceHint: '手动粘贴素材',
      focus: '问路和确认方向',
      difficulty: 'A2-B1',
      previewTitle: '你保存的短片段',
      previewDescription: '本地保存的手动素材',
      sampleContent:
          'Could you tell me where gate B12 is? I need to get there before boarding.',
      practiceSentences: const [
        'Could you tell me where gate B12 is?',
        'I need to get there before boarding.',
      ],
      keyVocabulary: const ['could', 'gate', 'boarding'],
    );

    final lesson = const LocalDailyLessonService().generate(
      stats: const LocalLearningStats.empty(),
      preferredStage: LearningStage.daily,
      availableThemes: [...SampleData.themes, customTheme],
      materialState: const MaterialActivityState(
        favoriteTitles: ['机场问路片段'],
        history: [],
      ),
    );

    expect(lesson.theme.title, '机场问路片段');
    expect(lesson.listeningLines.first, contains('gate B12'));
  });

  testWidgets('opens keyword detail from today word card', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('grab'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('grab'));
    await tester.pumpAndSettle();

    expect(find.text('词根和构词'), findsOneWidget);
    expect(find.text('联想记忆'), findsOneWidget);
    expect(find.text('常见搭配'), findsOneWidget);
  });

  testWidgets(
    'review page shows expression status instead of duplicated chunks',
    (tester) async {
      await tester.pumpWidget(testApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('复盘'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('掌握和待复习'),
        360,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('掌握和待复习'), findsOneWidget);
      expect(find.text('已掌握'), findsOneWidget);
      expect(find.text('待复习'), findsOneWidget);
      expect(find.text('今日词块'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('数据备份'),
        360,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('生成备份码'), findsOneWidget);
      expect(find.text('导入备份码'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('自用版状态'),
        360,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('未接云端：不同手机之间不会自动同步。'), findsOneWidget);
    },
  );

  testWidgets('adds completed lesson expressions to review queue', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('跟读'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始录音'));
    await tester.pump();
    await tester.tap(find.text('停止录音'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存录音'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存录音'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('今日'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('今日复习'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('今日复习'), findsOneWidget);
    expect(find.text('grab'), findsOneWidget);

    await tester.tap(find.text('进入复盘队列'));
    await tester.pumpAndSettle();

    expect(find.text('学习复盘'), findsOneWidget);

    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('词块复习'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('词块复习'), findsOneWidget);
    expect(find.textContaining('待复习'), findsWidgets);
    expect(find.text('grab'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'about');
    await tester.pumpAndSettle();
    expect(find.text('I was about to...'), findsOneWidget);

    await tester.tap(find.text('标记掌握').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('已掌握'), findsWidgets);
  });

  testWidgets('records used lessons in searchable lesson history', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('东邻西舍 S01E07 灵感：社区活动接话'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('东邻西舍 S01E07 灵感：社区活动接话'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('生成今日 15 分钟练习'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成今日 15 分钟练习'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('练习历史搜索'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('练习历史搜索'), findsOneWidget);
    expect(find.textContaining('社区活动接话'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'block party');
    await tester.pumpAndSettle();
    expect(find.textContaining('社区活动接话'), findsWidgets);
  });

  testWidgets('translates Chinese into English and Korean variants', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('翻译'));
    await tester.pumpAndSettle();

    expect(find.text('英文'), findsOneWidget);
    expect(find.text('韩文敬语'), findsOneWidget);
    expect(find.text('I would like a cup of coffee.'), findsOneWidget);
    expect(find.text('커피 한 잔 주세요.'), findsOneWidget);
    expect(find.text('读音：keo-pi han jan ju-se-yo'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('韩文平语'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('韩文平语'), findsOneWidget);
    expect(find.text('커피 한 잔 줘.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('朗读英文'),
      -260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('朗读英文'));
    await tester.pumpAndSettle();
  });

  testWidgets('keeps recent translation history', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('翻译'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '谢谢');
    await tester.tap(find.text('生成翻译'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('最近翻译'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('最近翻译'), findsOneWidget);
    expect(find.text('谢谢'), findsOneWidget);
    expect(find.text('Thank you.'), findsWidgets);
  });

  testWidgets('shows dictation feedback after checking an answer', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('跟读'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始录音'));
    await tester.pump();
    await tester.tap(find.text('停止录音'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存录音'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存录音'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('检查听写'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'I was about to grab coffee',
    );
    await tester.tap(find.text('检查听写'));
    await tester.pumpAndSettle();

    expect(find.textContaining('本地检查'), findsOneWidget);
    expect(find.textContaining('分'), findsWidgets);
    expect(find.textContaining('anything'), findsWidgets);
  });

  testWidgets('generates and shows a saved local daily lesson', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('今日练习生成'), findsOneWidget);
    expect(find.text('来源：本地推荐'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('生成今日练习'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成今日练习'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('来源：本地推荐'), findsOneWidget);
    expect(find.text('精听句子'), findsOneWidget);
  });

  testWidgets('uses local learning plan when generating today lesson', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('复盘'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('学习计划'),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('10 分钟'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('影视歌曲'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('今日'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('生成今日练习'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成今日练习'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('完成进度 0/10 分钟'),
      -420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('今日 10 分钟听说训练'), findsOneWidget);
    expect(find.textContaining('家庭晚餐小插曲'), findsWidgets);
    expect(find.text('完成进度 0/10 分钟'), findsOneWidget);
  });

  testWidgets('uses material detail as today lesson', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('家庭晚餐小插曲'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('家庭晚餐小插曲'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('生成今日 15 分钟练习'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成今日 15 分钟练习'));
    await tester.pumpAndSettle();

    expect(find.text('今日学习'), findsOneWidget);
    expect(find.textContaining('家庭晚餐小插曲'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('I got held up after class.'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('I got held up after class.'), findsWidgets);
  });

  testWidgets('uses episode six reference card as today lesson', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('东邻西舍 S01E06 灵感：邻里帮忙的分寸'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('东邻西舍 S01E06 灵感：邻里帮忙的分寸'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.textContaining('练习内容为原创改写'), findsOneWidget);
    expect(find.text('内容边界'), findsOneWidget);
    expect(find.text('本卡只使用本地台词本的学习方向，不保存原始台词。'), findsOneWidget);
    expect(find.text('原始文件保留在素材来源目录，不提交 Git，也不打包进 App。'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('生成今日 15 分钟练习'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成今日 15 分钟练习'));
    await tester.pumpAndSettle();

    expect(find.text('今日学习'), findsOneWidget);
    expect(find.textContaining('邻里帮忙的分寸'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('I know you meant well.'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('I know you meant well.'), findsWidgets);
  });

  testWidgets('favorites a material from detail page', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();
    expect(find.text('收藏 0 个'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('咖啡店偶遇'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('咖啡店偶遇'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('收藏素材'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('收藏素材'));
    await tester.pumpAndSettle();

    expect(find.text('取消收藏'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('素材状态'),
      -320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('已收藏'), findsOneWidget);

    Navigator.of(tester.element(find.text('素材状态'))).pop();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('收藏 1 个'),
      -320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('收藏 1 个'), findsOneWidget);
  });

  testWidgets('creates a pasted material and uses it as today lesson', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('粘贴新素材'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '机场问路片段');
    await tester.enterText(find.byType(TextField).at(1), '问路和确认方向');
    await tester.enterText(
      find.byType(TextField).at(2),
      'Could you tell me where gate B12 is?\nI need to get there before boarding.',
    );
    await tester.scrollUntilVisible(
      find.text('保存为素材'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存为素材'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('机场问路片段'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('机场问路片段'), findsOneWidget);

    await tester.tap(find.text('机场问路片段'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('生成今日 15 分钟练习'),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成今日 15 分钟练习'));
    await tester.pumpAndSettle();

    expect(find.text('今日学习'), findsOneWidget);
    expect(find.textContaining('机场问路片段'), findsWidgets);
  });
}

Widget testApp() {
  return MyApp(
    audioRecorder: FakeRecordingClient(),
    audioPlayer: FakeAudioPlaybackClient(),
    speechClient: FakeSpeechClient(),
  );
}

class FakeRecordingClient implements RecordingClient {
  @override
  Future<void> start() async {}

  @override
  Future<RecordingSession?> stop() async {
    return const RecordingSession(path: 'test-recording.m4a');
  }

  @override
  Future<void> dispose() async {}
}

class FakeSpeechClient implements SpeechClient {
  @override
  Future<void> speak(String text, {required String locale}) async {}

  @override
  Future<void> stop() async {}
}

class FakeAudioPlaybackClient implements AudioPlaybackClient {
  @override
  Future<void> play(String path) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
