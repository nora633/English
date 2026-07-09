import 'package:flutter/material.dart';

import 'data/sample_data.dart';
import 'models/learning_models.dart';
import 'services/audio_player_service.dart';
import 'services/audio_recorder_service.dart';
import 'services/custom_material_store.dart';
import 'services/daily_lesson_service.dart';
import 'services/lesson_history_store.dart';
import 'services/local_progress_store.dart';
import 'services/material_activity_store.dart';
import 'services/review_queue_store.dart';
import 'services/speech_service.dart';
import 'theme/app_theme.dart';
import 'views/review_page.dart';
import 'views/speaking_page.dart';
import 'views/theme_library_page.dart';
import 'views/today_page.dart';
import 'views/translation_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.audioRecorder,
    this.audioPlayer,
    this.speechClient,
  });

  final RecordingClient? audioRecorder;
  final AudioPlaybackClient? audioPlayer;
  final SpeechClient? speechClient;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final progressStore = const LocalProgressStore();
  final lessonStore = const DailyLessonStore();
  final lessonGateway = const DailyLessonGateway();
  final lessonHistoryStore = const LessonHistoryStore();
  final materialStore = const MaterialActivityStore();
  final customMaterialStore = const CustomMaterialStore();
  final reviewQueueStore = const ReviewQueueStore();

  int index = 0;
  LocalProgress progress = const LocalProgress.empty();
  LocalLearningStats stats = const LocalLearningStats.empty();
  List<LessonHistoryRecord> lessonHistory = const [];
  MaterialActivityState materialState = const MaterialActivityState.empty();
  List<ReviewQueueItem> reviewQueue = const [];
  List<LearningTheme> customThemes = const [];
  DailyLesson lesson = SampleData.todayLesson;
  DailyLessonSource lessonSource = DailyLessonSource.local;
  bool isGeneratingLesson = false;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final storedProgress = await progressStore.load().catchError(
      (_) => const LocalProgress.empty(),
    );
    final storedStats = await progressStore.loadStats().catchError(
      (_) => const LocalLearningStats.empty(),
    );
    final storedLesson = await lessonStore.load().catchError((_) => null);
    final storedLessonHistory = await lessonHistoryStore.load().catchError(
      (_) => const <LessonHistoryRecord>[],
    );
    final storedMaterialState = await materialStore.load().catchError(
      (_) => const MaterialActivityState.empty(),
    );
    final storedCustomThemes = await customMaterialStore.load().catchError(
      (_) => const <LearningTheme>[],
    );
    final storedReviewQueue = await reviewQueueStore.load().catchError(
      (_) => const <ReviewQueueItem>[],
    );
    if (!mounted) return;

    setState(() {
      progress = storedProgress;
      stats = storedStats;
      lessonHistory = storedLessonHistory;
      materialState = storedMaterialState;
      reviewQueue = storedReviewQueue;
      customThemes = storedCustomThemes;
      if (storedLesson != null) {
        lesson = storedLesson.lesson;
        lessonSource = storedLesson.source;
      }
    });
  }

  void goTo(int value) => setState(() => index = value);

  Future<void> updateProgress(LocalProgress value) async {
    setState(() => progress = value);
    await progressStore.save(value).catchError((_) {});
    final storedReviewQueue = await reviewQueueStore
        .addLesson(lesson)
        .catchError((_) => reviewQueue);
    final storedStats = await progressStore.loadStats().catchError(
      (_) => const LocalLearningStats.empty(),
    );
    if (!mounted) return;

    setState(() {
      stats = storedStats;
      reviewQueue = storedReviewQueue;
    });
  }

  Future<void> generateDailyLesson() async {
    if (isGeneratingLesson) return;

    setState(() => isGeneratingLesson = true);
    final response = await lessonGateway.generate(
      stats: stats,
      materialState: materialState,
      availableThemes: [...SampleData.themes, ...customThemes],
      preferredStage: LearningStage.daily,
    );
    await lessonStore.save(response).catchError((_) {});
    final storedLessonHistory = await lessonHistoryStore
        .recordLesson(
          lesson: response.lesson,
          sourceLabel: response.source.label,
        )
        .catchError((_) => lessonHistory);
    if (!mounted) return;

    setState(() {
      lesson = response.lesson;
      lessonSource = response.source;
      lessonHistory = storedLessonHistory;
      isGeneratingLesson = false;
    });
  }

  Future<void> useThemeAsDailyLesson(LearningTheme theme) async {
    final nextMaterialState = await materialStore
        .recordUse(theme)
        .catchError((_) => materialState);
    final generated = const LocalDailyLessonService().generateFromTheme(theme);
    final response = DailyLessonResponse(
      lesson: generated,
      source: DailyLessonSource.local,
    );
    await lessonStore.save(response).catchError((_) {});
    final storedLessonHistory = await lessonHistoryStore
        .recordLesson(lesson: generated, sourceLabel: '素材生成')
        .catchError((_) => lessonHistory);
    if (!mounted) return;

    setState(() {
      lesson = generated;
      lessonSource = response.source;
      lessonHistory = storedLessonHistory;
      materialState = nextMaterialState;
      index = 0;
    });
  }

  Future<void> toggleThemeFavorite(LearningTheme theme) async {
    final nextMaterialState = await materialStore.toggleFavorite(theme);
    if (!mounted) return;

    setState(() => materialState = nextMaterialState);
  }

  Future<void> saveCustomTheme(LearningTheme theme) async {
    final nextThemes = await customMaterialStore.save(theme);
    if (!mounted) return;

    setState(() => customThemes = nextThemes);
  }

  Future<void> markReviewItemMastered(String id) async {
    final nextQueue = await reviewQueueStore.markMastered(id);
    if (!mounted) return;

    setState(() => reviewQueue = nextQueue);
  }

  @override
  Widget build(BuildContext context) {
    final completedMinutes = progress.completedMinutes;
    final pages = [
      TodayPage(
        key: const ValueKey('today-page'),
        lesson: lesson,
        lessonSource: lessonSource,
        isGeneratingLesson: isGeneratingLesson,
        completedMinutes: completedMinutes,
        reviewQueue: reviewQueue,
        onStartSpeaking: () => goTo(2),
        onChooseTheme: () => goTo(1),
        onGenerateLesson: generateDailyLesson,
        onOpenReview: () => goTo(4),
      ),
      ThemeLibraryPage(
        key: const ValueKey('theme-library-page'),
        materialState: materialState,
        customThemes: customThemes,
        onUseTheme: useThemeAsDailyLesson,
        onToggleFavorite: toggleThemeFavorite,
        onSaveCustomTheme: saveCustomTheme,
      ),
      SpeakingPage(
        key: const ValueKey('speaking-page'),
        audioRecorder: widget.audioRecorder,
        audioPlayer: widget.audioPlayer,
        speechClient: widget.speechClient,
        lesson: lesson,
        recordingCompleted: progress.recordingCompleted,
        dictationCompleted: progress.dictationCompleted,
        recallCompleted: progress.recallCompleted,
        onRecordingSaved: () =>
            updateProgress(progress.copyWith(recordingCompleted: true)),
        onDictationChecked: () =>
            updateProgress(progress.copyWith(dictationCompleted: true)),
        onRecallChecked: () =>
            updateProgress(progress.copyWith(recallCompleted: true)),
        onFinish: () => goTo(4),
      ),
      TranslationPage(
        key: const ValueKey('translation-page'),
        speechClient: widget.speechClient,
      ),
      ReviewPage(
        key: const ValueKey('review-page'),
        completedMinutes: completedMinutes,
        stats: stats,
        lessonHistory: lessonHistory,
        reviewQueue: reviewQueue,
        onMarkReviewItemMastered: markReviewItemMastered,
        onRestart: () => goTo(0),
        onDataImported: loadProgress,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 430.0
                ? constraints.maxWidth
                : 430.0;

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: pages[index]),
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
                      child: _BottomNav(index: index, onSelect: goTo),
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
  const _BottomNav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

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
          selectedIndex: index,
          onDestinationSelected: onSelect,
          indicatorColor: AppColors.teal.withValues(alpha: 0.14),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: '今日',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: '素材',
            ),
            NavigationDestination(
              icon: Icon(Icons.mic_none),
              selectedIcon: Icon(Icons.mic),
              label: '跟读',
            ),
            NavigationDestination(
              icon: Icon(Icons.translate_outlined),
              selectedIcon: Icon(Icons.translate),
              label: '翻译',
            ),
            NavigationDestination(
              icon: Icon(Icons.trending_up),
              selectedIcon: Icon(Icons.trending_up),
              label: '复盘',
            ),
          ],
        ),
      ),
    );
  }
}
