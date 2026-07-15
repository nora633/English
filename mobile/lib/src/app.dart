import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'services/speech_service.dart';
import 'theme/app_theme.dart';

class EnglishLearningApp extends StatelessWidget {
  const EnglishLearningApp({super.key, this.speechClient});

  final SpeechClient? speechClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '开练英语',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.page,
        fontFamily: 'System',
        useMaterial3: true,
      ),
      home: AppShell(speechClient: speechClient),
    );
  }
}

class MyApp extends EnglishLearningApp {
  const MyApp({super.key, super.speechClient});
}
