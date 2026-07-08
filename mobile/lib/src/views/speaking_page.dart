import 'dart:async';

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/learning_models.dart';
import '../services/audio_player_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/exercise_check_service.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class SpeakingPage extends StatefulWidget {
  const SpeakingPage({
    super.key,
    required this.recordingCompleted,
    required this.dictationCompleted,
    required this.recallCompleted,
    required this.onRecordingSaved,
    required this.onDictationChecked,
    required this.onRecallChecked,
    required this.onFinish,
    required this.lesson,
    this.audioRecorder,
    this.audioPlayer,
    this.speechClient,
    this.exerciseCheckGateway,
  });

  final RecordingClient? audioRecorder;
  final AudioPlaybackClient? audioPlayer;
  final SpeechClient? speechClient;
  final ExerciseCheckGateway? exerciseCheckGateway;
  final bool? recordingCompleted;
  final bool? dictationCompleted;
  final bool? recallCompleted;
  final VoidCallback onRecordingSaved;
  final VoidCallback onDictationChecked;
  final VoidCallback onRecallChecked;
  final VoidCallback onFinish;
  final DailyLesson lesson;

  @override
  State<SpeakingPage> createState() => _SpeakingPageState();
}

class _SpeakingPageState extends State<SpeakingPage> {
  late final RecordingClient audioRecorder;
  late final AudioPlaybackClient audioPlayer;
  late final SpeechClient speechClient;
  late final ExerciseCheckGateway exerciseCheckGateway;
  final dictation = TextEditingController();
  final recall = TextEditingController();
  Timer? recordingTimer;
  bool isRecording = false;
  bool isPlayingTarget = false;
  bool isPlayingRecording = false;
  bool hasRecordingDraft = false;
  int recordingSeconds = 0;
  String? recordingPath;
  String? recordingError;
  String? playbackError;
  bool isCheckingDictation = false;
  bool isCheckingRecall = false;
  ExerciseCheckResponse? dictationFeedback;
  ExerciseCheckResponse? recallFeedback;

  @override
  void initState() {
    super.initState();
    audioRecorder = widget.audioRecorder ?? AudioRecorderService();
    audioPlayer = widget.audioPlayer ?? AudioPlayerService();
    speechClient = widget.speechClient ?? SpeechService();
    exerciseCheckGateway =
        widget.exerciseCheckGateway ?? const ExerciseCheckGateway();
  }

  void saveRecording() {
    if (recordingPath == null || isRecording) return;

    setState(() {
      isRecording = false;
      hasRecordingDraft = true;
      playbackError = null;
    });
    widget.onRecordingSaved();
  }

  Future<void> toggleRecording() async {
    if (isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    setState(() {
      isRecording = true;
      isPlayingRecording = false;
      isPlayingTarget = false;
      hasRecordingDraft = false;
      recordingSeconds = 0;
      recordingPath = null;
      recordingError = null;
      playbackError = null;
    });

    try {
      await speechClient.stop();
      await audioPlayer.stop();
      await audioRecorder.start();
      startRecordingTimer();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isRecording = false;
        recordingError = error.toString();
      });
    }
  }

  Future<void> stopRecording() async {
    try {
      final session = await audioRecorder.stop();
      stopRecordingTimer();
      if (!mounted) return;
      setState(() {
        isRecording = false;
        hasRecordingDraft = session != null;
        recordingPath = session?.path;
        playbackError = null;
      });
    } catch (error) {
      stopRecordingTimer();
      if (!mounted) return;
      setState(() {
        isRecording = false;
        recordingError = error.toString();
      });
    }
  }

  void startRecordingTimer() {
    recordingTimer?.cancel();
    recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !isRecording) return;
      setState(() => recordingSeconds += 1);
    });
  }

  void stopRecordingTimer() {
    recordingTimer?.cancel();
    recordingTimer = null;
  }

  Future<void> playTargetSentence() async {
    final text = widget.lesson.listeningLines.first;

    try {
      await audioPlayer.stop();
      await speechClient.stop();
      setState(() {
        isPlayingTarget = true;
        isPlayingRecording = false;
        playbackError = null;
      });
      await speechClient.speak(text, locale: 'en-US');
    } catch (error) {
      if (!mounted) return;
      setState(() => playbackError = '当前设备无法朗读原句：$error');
    }
  }

  Future<void> stopTargetSentence() async {
    await speechClient.stop();
    if (!mounted) return;
    setState(() => isPlayingTarget = false);
  }

  Future<void> playRecording() async {
    final path = recordingPath;
    if (path == null) return;

    setState(() {
      isPlayingRecording = true;
      isPlayingTarget = false;
      playbackError = null;
    });

    try {
      await speechClient.stop();
      await audioPlayer.play(path);
    } catch (error) {
      if (!mounted) return;
      setState(() => playbackError = error.toString());
    }
  }

  Future<void> stopPlayback() async {
    await audioPlayer.stop();
    await speechClient.stop();
    if (!mounted) return;
    setState(() {
      isPlayingRecording = false;
      isPlayingTarget = false;
    });
  }

  Future<void> checkDictation() async {
    final lesson = widget.lesson;
    setState(() => isCheckingDictation = true);

    final feedback = await exerciseCheckGateway.check(
      mode: ExerciseCheckMode.dictation,
      target: lesson.listeningLines.first,
      answer: dictation.text,
    );
    if (!mounted) return;

    setState(() {
      dictationFeedback = feedback;
      isCheckingDictation = false;
    });
    widget.onDictationChecked();
  }

  Future<void> checkRecall() async {
    final lesson = widget.lesson;
    const prompt = '我正准备去买杯咖啡。你要带点什么吗？';
    setState(() => isCheckingRecall = true);

    final feedback = await exerciseCheckGateway.check(
      mode: ExerciseCheckMode.recall,
      target: lesson.listeningLines.first,
      answer: recall.text,
      prompt: prompt,
    );
    if (!mounted) return;

    setState(() {
      recallFeedback = feedback;
      isCheckingRecall = false;
    });
    widget.onRecallChecked();
  }

  @override
  void dispose() {
    stopRecordingTimer();
    dictation.dispose();
    recall.dispose();
    audioRecorder.dispose();
    audioPlayer.dispose();
    speechClient.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final score = SampleData.speakingScore;
    final savedRecording = widget.recordingCompleted == true;
    final showRecordingFeedback = savedRecording || hasRecordingDraft;
    final checkedDictation = widget.dictationCompleted == true;
    final checkedRecall = widget.recallCompleted == true;
    final durationText = recordingSeconds > 0 ? '$recordingSeconds 秒' : '本次';
    final recordingLabel = isRecording
        ? '正在录音 00:${recordingSeconds.toString().padLeft(2, '0')}'
        : hasRecordingDraft || savedRecording
        ? '录音已停止，可以保存或回放'
        : '点击麦克风开始跟读';

    return AppScrollPage(
      title: '跟读练习',
      children: [
        CardPanel(
          title: '目标句',
          icon: Icons.center_focus_strong,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.listeningLines.first, style: AppText.sectionBig),
              const SizedBox(height: 8),
              const Text(
                '重点：about to / grab some coffee / want anything',
                style: AppText.muted,
              ),
            ],
          ),
        ),
        CardPanel(
          child: Column(
            children: [
              IconButton(
                iconSize: 78,
                color: savedRecording
                    ? Colors.green
                    : isRecording
                    ? AppColors.orange
                    : AppColors.teal,
                onPressed: toggleRecording,
                icon: Icon(
                  isRecording
                      ? Icons.stop_circle_outlined
                      : Icons.mic_none_rounded,
                ),
              ),
              Text(
                recordingLabel,
                style: isRecording ? AppText.accent : AppText.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                '先播放原句，再录自己的声音；录音只保存在本机。',
                style: AppText.muted,
                textAlign: TextAlign.center,
              ),
              if (recordingPath != null) ...[
                const SizedBox(height: 6),
                Text('录音已保存：$recordingPath', style: AppText.muted),
              ],
              if (recordingError != null) ...[
                const SizedBox(height: 6),
                Text(recordingError!, style: AppText.accent),
              ],
              if (playbackError != null) ...[
                const SizedBox(height: 6),
                Text(playbackError!, style: AppText.accent),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      icon: isPlayingTarget ? Icons.stop : Icons.play_arrow,
                      text: isPlayingTarget ? '停止原句' : '播放原句',
                      onPressed: isPlayingTarget
                          ? stopTargetSentence
                          : playTargetSentence,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      icon: isRecording
                          ? Icons.stop_circle_outlined
                          : Icons.mic_none_rounded,
                      text: isRecording ? '停止录音' : '开始录音',
                      onPressed: toggleRecording,
                    ),
                  ),
                ],
              ),
              if (recordingPath != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        icon: isPlayingRecording
                            ? Icons.stop
                            : Icons.replay_rounded,
                        text: isPlayingRecording ? '停止录音' : '播放录音',
                        onPressed: isPlayingRecording
                            ? stopPlayback
                            : playRecording,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        icon: Icons.check,
                        text: savedRecording ? '已保存' : '保存录音',
                        onPressed: saveRecording,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (showRecordingFeedback) ...[
          CardPanel(
            title: '本地跟读记录',
            icon: Icons.fact_check_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已记录一段$durationText跟读音频。当前自用版先保存练习状态，不做伪 AI 打分。',
                  style: AppText.bodyLarge,
                ),
                const SizedBox(height: 10),
                Text('后续接入 AI 服务后，这里再显示真实转写、发音评分和改进建议。', style: AppText.muted),
              ],
            ),
          ),
          CardPanel(
            title: '今日复盘建议',
            icon: Icons.auto_fix_high,
            child: Column(
              children: [
                for (final suggestion in score.suggestions)
                  BulletLine(text: suggestion),
              ],
            ),
          ),
          CardPanel(
            title: '听写',
            icon: Icons.edit_note,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('跟读完成后，听目标句并写出你听到的英文。'),
                const SizedBox(height: 10),
                AppTextField(controller: dictation, hint: 'I was about to...'),
                const SizedBox(height: 12),
                PrimaryButton(
                  icon: isCheckingDictation
                      ? Icons.hourglass_top
                      : Icons.check_circle_outline,
                  text: isCheckingDictation ? '检查中' : '检查听写',
                  onPressed: isCheckingDictation
                      ? () {}
                      : () {
                          checkDictation();
                        },
                ),
                if (checkedDictation && dictationFeedback != null)
                  ExerciseFeedbackCard(feedback: dictationFeedback!),
              ],
            ),
          ),
        ],
        if (checkedDictation)
          CardPanel(
            title: '默写',
            icon: Icons.keyboard_alt_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('看中文提示，凭记忆写出自然英文。'),
                const SizedBox(height: 8),
                const Text('中文提示：我正准备去买杯咖啡。你要带点什么吗？', style: AppText.emphasis),
                const SizedBox(height: 10),
                AppTextField(
                  controller: recall,
                  hint: 'Write the sentence from memory',
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  icon: isCheckingRecall
                      ? Icons.hourglass_top
                      : Icons.visibility_outlined,
                  text: isCheckingRecall ? '检查中' : '检查默写',
                  onPressed: isCheckingRecall
                      ? () {}
                      : () {
                          checkRecall();
                        },
                ),
                if (checkedRecall && recallFeedback != null)
                  ExerciseFeedbackCard(feedback: recallFeedback!),
              ],
            ),
          ),
        if (checkedRecall)
          CardPanel(
            title: '下一步',
            icon: Icons.arrow_circle_right_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('把今天的词块和反馈保存到复盘里，明天继续练同一类表达。'),
                const SizedBox(height: 12),
                PrimaryButton(
                  icon: Icons.trending_up,
                  text: '进入复盘',
                  onPressed: widget.onFinish,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ExerciseFeedbackCard extends StatelessWidget {
  const ExerciseFeedbackCard({super.key, required this.feedback});

  final ExerciseCheckResponse feedback;

  @override
  Widget build(BuildContext context) {
    final result = feedback.result;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${result.level.label} · ${feedback.source.label}',
                  style: AppText.emphasis,
                ),
              ),
              SmallChip(label: '${result.score} 分'),
            ],
          ),
          const SizedBox(height: 8),
          Text(result.summary, style: AppText.bodyLarge),
          const SizedBox(height: 8),
          Text('参考：${result.reference}', style: AppText.muted),
          if (result.correctedAnswer.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('建议答案：${result.correctedAnswer}'),
          ],
          if (result.issues.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('问题', style: AppText.emphasis),
            const SizedBox(height: 6),
            for (final issue in result.issues) BulletLine(text: issue),
          ],
          if (result.suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('建议', style: AppText.emphasis),
            const SizedBox(height: 6),
            for (final suggestion in result.suggestions)
              BulletLine(text: suggestion),
          ],
        ],
      ),
    );
  }
}
