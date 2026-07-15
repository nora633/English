import 'package:flutter/material.dart';

import '../models/vnext_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class WarmupPage extends StatelessWidget {
  const WarmupPage({
    super.key,
    required this.pack,
    required this.meaningOpened,
    required this.isPlaying,
    required this.audioError,
    required this.onToggleMeaning,
    required this.onPlayAll,
    required this.onStopAudio,
    required this.onStartPractice,
  });

  final ScenarioPack pack;
  final bool meaningOpened;
  final bool isPlaying;
  final String? audioError;
  final VoidCallback onToggleMeaning;
  final VoidCallback onPlayAll;
  final VoidCallback onStopAudio;
  final VoidCallback onStartPractice;

  @override
  Widget build(BuildContext context) {
    return AppScrollPage(
      title: '预热',
      children: [
        GradientPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusPill(text: '先听英文再看意思'),
              const SizedBox(height: 18),
              Text(pack.title, style: AppText.hero),
              const SizedBox(height: 8),
              Text(
                '${pack.sentences.length} 句 · ${pack.durationLabel}',
                style: AppText.heroMuted,
              ),
              const SizedBox(height: 12),
              Text(
                '先听一遍，看看今天这段你能听懂多少',
                style: AppText.heroSub.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        CardPanel(
          title: '5 句英文总览',
          icon: Icons.headphones_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < pack.sentences.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                      onPressed: isPlaying ? onStopAudio : onPlayAll,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryButton(
                      icon: Icons.visibility_outlined,
                      text: meaningOpened ? '已查看意思' : '查看意思',
                      onPressed: onToggleMeaning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (meaningOpened)
          Column(
            children: [
              CardPanel(
                title: '理解信息',
                icon: Icons.lightbulb_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pack.sceneDescription, style: AppText.bodyLarge),
                    const SizedBox(height: 16),
                    for (var i = 0; i < pack.sentences.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '第 ${i + 1} 句：${pack.sentences[i].role}',
                              style: AppText.emphasis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pack.sentences[i].chinese,
                              style: AppText.muted,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  icon: Icons.school_outlined,
                  text: '开始第 1 句练习',
                  onPressed: onStartPractice,
                  large: true,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
