import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../services/audio_player_service.dart';
import '../services/audio_recorder_service.dart';
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
    this.audioRecorder,
    this.audioPlayer,
  });

  final RecordingClient? audioRecorder;
  final AudioPlaybackClient? audioPlayer;
  final bool? recordingCompleted;
  final bool? dictationCompleted;
  final bool? recallCompleted;
  final VoidCallback onRecordingSaved;
  final VoidCallback onDictationChecked;
  final VoidCallback onRecallChecked;
  final VoidCallback onFinish;

  @override
  State<SpeakingPage> createState() => _SpeakingPageState();
}

class _SpeakingPageState extends State<SpeakingPage> {
  late final RecordingClient audioRecorder;
  late final AudioPlaybackClient audioPlayer;
  final dictation = TextEditingController();
  final recall = TextEditingController();
  bool isRecording = false;
  bool isPlayingRecording = false;
  bool hasRecordingDraft = false;
  int recordingSeconds = 0;
  String? recordingPath;
  String? recordingError;
  String? playbackError;

  @override
  void initState() {
    super.initState();
    audioRecorder = widget.audioRecorder ?? AudioRecorderService();
    audioPlayer = widget.audioPlayer ?? AudioPlayerService();
  }

  void saveRecording() {
    setState(() {
      isRecording = false;
      hasRecordingDraft = true;
      recordingSeconds = recordingSeconds == 0 ? 8 : recordingSeconds;
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
      hasRecordingDraft = false;
      recordingSeconds = 0;
      recordingPath = null;
      recordingError = null;
      playbackError = null;
    });

    try {
      await audioRecorder.start();
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
      if (!mounted) return;
      setState(() {
        isRecording = false;
        hasRecordingDraft = session != null;
        recordingPath = session?.path;
        recordingSeconds = recordingSeconds == 0 ? 8 : recordingSeconds;
        playbackError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isRecording = false;
        recordingError = error.toString();
      });
    }
  }

  Future<void> playRecording() async {
    final path = recordingPath;
    if (path == null) return;

    setState(() {
      isPlayingRecording = true;
      playbackError = null;
    });

    try {
      await audioPlayer.play(path);
    } catch (error) {
      if (!mounted) return;
      setState(() => playbackError = error.toString());
    } finally {
      if (mounted) {
        setState(() => isPlayingRecording = false);
      }
    }
  }

  void checkDictation() {
    widget.onDictationChecked();
  }

  void checkRecall() {
    widget.onRecallChecked();
  }

  @override
  void dispose() {
    dictation.dispose();
    recall.dispose();
    audioRecorder.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = SampleData.todayLesson;
    final score = SampleData.speakingScore;
    final savedRecording = widget.recordingCompleted == true;
    final showRecordingFeedback = savedRecording || hasRecordingDraft;
    final checkedDictation = widget.dictationCompleted == true;
    final checkedRecall = widget.recallCompleted == true;
    final recordingLabel = isRecording
        ? '正在录音 00:${recordingSeconds.toString().padLeft(2, '0')}'
        : hasRecordingDraft || savedRecording
        ? '已生成一段录音草稿'
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
                  savedRecording
                      ? Icons.check_circle
                      : isRecording
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
                '会申请麦克风权限，录音会先保存到本机临时文件。',
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
                      icon: Icons.play_arrow,
                      text: '播放原句',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      icon: Icons.check,
                      text: '保存录音',
                      onPressed: saveRecording,
                    ),
                  ),
                ],
              ),
              if (recordingPath != null) ...[
                const SizedBox(height: 10),
                SecondaryButton(
                  icon: isPlayingRecording
                      ? Icons.hourglass_bottom
                      : Icons.replay_rounded,
                  text: isPlayingRecording ? '正在播放' : '播放录音',
                  onPressed: playRecording,
                ),
              ],
            ],
          ),
        ),
        if (showRecordingFeedback) ...[
          CardPanel(
            title: '口语评分',
            icon: Icons.speed,
            child: Column(
              children: [
                ScoreBar(label: '清晰度', value: score.clarity),
                ScoreBar(label: '流利度', value: score.fluency),
                ScoreBar(label: '完整度', value: score.completeness),
                ScoreBar(label: '自然度', value: score.naturalness),
              ],
            ),
          ),
          CardPanel(
            title: '转写文本',
            icon: Icons.chat_bubble_outline,
            child: Text(score.transcript),
          ),
          CardPanel(
            title: '改进建议',
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
                  icon: Icons.check_circle_outline,
                  text: '检查听写',
                  onPressed: checkDictation,
                ),
                if (checkedDictation)
                  WritingFeedback(
                    title: '听写反馈',
                    reference: lesson.listeningLines.first,
                    note: '重点检查 about to、grab、anything 是否写完整。',
                  ),
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
                  icon: Icons.visibility_outlined,
                  text: '检查默写',
                  onPressed: checkRecall,
                ),
                if (checkedRecall)
                  WritingFeedback(
                    title: '默写反馈',
                    reference: lesson.listeningLines.first,
                    note: '后续会加入相似度评分、漏词提醒和自然表达建议。',
                  ),
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
