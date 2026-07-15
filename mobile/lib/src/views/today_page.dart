import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/vnext_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.pack,
    required this.state,
    required this.dueReviewCount,
    required this.isPlaying,
    required this.audioError,
    required this.onOpenWarmup,
    required this.onContinuePractice,
    required this.onOpenReview,
    required this.onPlayPreview,
    required this.onOpenMeaning,
    required this.onSkipToReviewForTesting,
  });

  final ScenarioPack pack;
  final PracticeState state;
  final int dueReviewCount;
  final bool isPlaying;
  final String? audioError;
  final VoidCallback onOpenWarmup;
  final VoidCallback onContinuePractice;
  final VoidCallback onOpenReview;
  final VoidCallback onPlayPreview;
  final VoidCallback onOpenMeaning;
  final VoidCallback onSkipToReviewForTesting;

  @override
  Widget build(BuildContext context) {
    return AppScrollPage(
      title: '今日',
      showTitle: false,
      children: [
        GradientPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dueReviewCount > 0) ...[
                const StatusPill(text: '今天有到期复习'),
                const SizedBox(height: 12),
              ],
              Text(pack.title, style: AppText.hero),
              const SizedBox(height: 8),
              Text(pack.summary, style: AppText.heroMuted),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroMetaPill(
                    label:
                        '当前进度 ${state.completedSentenceCount}/${pack.sentences.length} 句',
                  ),
                  _HeroMetaPill(label: state.completed ? '已完成' : '今日新练习'),
                ],
              ),
            ],
          ),
        ),
        CardPanel(
          title: '今天 5 句',
          icon: Icons.headphones_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('先看一遍，感受今天这段你能理解多少。', style: AppText.bodyLarge),
              const SizedBox(height: 14),
              for (var i = 0; i < pack.sentences.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. ', style: AppText.emphasis),
                      Expanded(
                        child: Text(
                          pack.sentences[i].english,
                          style: AppText.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              if (audioError != null) ...[
                const SizedBox(height: 4),
                Text(
                  audioError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      icon: isPlaying
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_fill,
                      text: isPlaying ? '停止播放' : '播放今天 5 句',
                      onPressed: onPlayPreview,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryButton(
                      icon: Icons.visibility_outlined,
                      text: state.warmupMeaningOpened ? '收起意思' : '查看意思',
                      onPressed: onOpenMeaning,
                    ),
                  ),
                ],
              ),
              if (!state.warmupMeaningOpened) ...[
                const SizedBox(height: 12),
                const Text('需要时再看中文理解。', style: AppText.muted),
              ] else ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Text(pack.sceneDescription, style: AppText.bodyLarge),
                const SizedBox(height: 14),
                for (var i = 0; i < pack.sentences.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ', style: AppText.emphasis),
                        Expanded(
                          child: Text(
                            pack.sentences[i].chinese,
                            style: AppText.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              icon: _mainButtonIcon(),
              text: _mainButtonText(),
              onPressed: _mainAction(),
              large: true,
            ),
            if (dueReviewCount > 0 && _hasNewPracticeToContinue()) ...[
              const SizedBox(height: 10),
              SecondaryButton(
                icon: Icons.school_outlined,
                text: '继续今天新练习',
                onPressed: _newPracticeAction(),
              ),
            ],
            if (_showLightHint()) ...[
              const SizedBox(height: 12),
              Text(_lightHintText(), style: AppText.muted),
            ],
            if (kDebugMode && !state.completed) ...[
              const SizedBox(height: 12),
              SecondaryButton(
                icon: Icons.bolt_outlined,
                text: '测试：直接生成复盘',
                onPressed: onSkipToReviewForTesting,
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _mainButtonText() {
    if (dueReviewCount > 0) return '先复习今天到期内容';
    if (state.completed) return '进入复盘';
    if (state.completedSentenceCount == 0) return '开始练习';
    return '继续今天练习';
  }

  IconData _mainButtonIcon() {
    if (dueReviewCount > 0 || state.completed) return Icons.repeat;
    return Icons.school_outlined;
  }

  VoidCallback _mainAction() {
    if (dueReviewCount > 0) return onOpenReview;
    if (state.completed) return onOpenReview;
    return _newPracticeAction();
  }

  VoidCallback _newPracticeAction() {
    if (state.completedSentenceCount == 0) return onOpenWarmup;
    return onContinuePractice;
  }

  bool _showLightHint() {
    return !state.completed && state.completedSentenceCount == 0;
  }

  bool _hasNewPracticeToContinue() {
    return !state.completed;
  }

  String _lightHintText() {
    return '先看今天 5 句，再开始第 1 句。';
  }
}

class _HeroMetaPill extends StatelessWidget {
  const _HeroMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
