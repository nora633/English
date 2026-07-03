import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'services/audio_player_service.dart';
import 'services/audio_recorder_service.dart';
import 'services/speech_service.dart';
import 'theme/app_theme.dart';

class EnglishLearningApp extends StatelessWidget {
  const EnglishLearningApp({
    super.key,
    this.audioRecorder,
    this.audioPlayer,
    this.speechClient,
  });

  final RecordingClient? audioRecorder;
  final AudioPlaybackClient? audioPlayer;
  final SpeechClient? speechClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'English',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.page,
        fontFamily: 'System',
        useMaterial3: true,
      ),
      home: AppShell(
        audioRecorder: audioRecorder,
        audioPlayer: audioPlayer,
        speechClient: speechClient,
      ),
    );
  }
}

class MyApp extends EnglishLearningApp {
  const MyApp({
    super.key,
    super.audioRecorder,
    super.audioPlayer,
    super.speechClient,
  });
}
