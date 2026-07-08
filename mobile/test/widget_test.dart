import 'package:english_learning_app/main.dart';
import 'package:english_learning_app/src/data/sample_data.dart';
import 'package:english_learning_app/src/models/learning_models.dart';
import 'package:english_learning_app/src/services/audio_player_service.dart';
import 'package:english_learning_app/src/services/audio_recorder_service.dart';
import 'package:english_learning_app/src/services/daily_lesson_service.dart';
import 'package:english_learning_app/src/services/exercise_check_service.dart';
import 'package:english_learning_app/src/services/local_progress_store.dart';
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

  testWidgets('uses material detail as today lesson', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('素材'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('家庭晚餐小插曲'));
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
