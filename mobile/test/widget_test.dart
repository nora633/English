import 'package:english_learning_app/main.dart';
import 'package:english_learning_app/src/services/audio_player_service.dart';
import 'package:english_learning_app/src/services/audio_recorder_service.dart';
import 'package:english_learning_app/src/services/local_progress_store.dart';
import 'package:english_learning_app/src/services/speech_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    await tester.ensureVisible(find.text('去跟读练习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('去跟读练习'));
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

    await tester.ensureVisible(find.text('去跟读练习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('去跟读练习'));
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
