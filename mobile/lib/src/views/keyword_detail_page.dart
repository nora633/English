import 'package:flutter/material.dart';

import '../models/vnext_models.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class KeywordDetailPage extends StatefulWidget {
  const KeywordDetailPage({super.key, required this.word});

  final KeywordNote word;

  @override
  State<KeywordDetailPage> createState() => _KeywordDetailPageState();
}

class _KeywordDetailPageState extends State<KeywordDetailPage> {
  final SpeechClient _speech = SpeechService();
  String? _playingTarget;

  Future<void> _play(String text, String target) async {
    if (_playingTarget == target) {
      await _speech.stop();
      if (mounted) {
        setState(() => _playingTarget = null);
      }
      return;
    }
    try {
      setState(() => _playingTarget = target);
      await _speech.stop();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await _speech.speak(text, locale: 'en-US');
    } finally {
      if (mounted && _playingTarget == target) {
        setState(() => _playingTarget = null);
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: AppScrollPage(
          title: widget.word.word,
          leading: IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          children: [
            CardPanel(
              title: '发音与词义',
              icon: Icons.record_voice_over_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.word.phonetic.isNotEmpty ||
                      widget.word.partOfSpeech.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.word.phonetic.isNotEmpty)
                          SmallChip(label: widget.word.phonetic),
                        if (widget.word.partOfSpeech.isNotEmpty)
                          SmallChip(label: widget.word.partOfSpeech),
                      ],
                    )
                  else
                    const Text('点击下方按钮听单词发音。', style: AppText.muted),
                  const SizedBox(height: 12),
                  Text(widget.word.meaning, style: AppText.accent),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    icon: _playingTarget == 'word'
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_outlined,
                    text: _playingTarget == 'word' ? '停止播放' : '听单词',
                    onPressed: () => _play(widget.word.word, 'word'),
                  ),
                ],
              ),
            ),
            CardPanel(
              title: '原句语境',
              icon: Icons.format_quote_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedSentence(
                    sentence: widget.word.example,
                    word: widget.word.word,
                  ),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    icon: _playingTarget == 'sentence'
                        ? Icons.stop_circle_outlined
                        : Icons.hearing_outlined,
                    text: _playingTarget == 'sentence' ? '停止播放' : '听原句',
                    onPressed: () => _play(widget.word.example, 'sentence'),
                  ),
                ],
              ),
            ),
            if (widget.word.wordRoot.isNotEmpty)
              CardPanel(
                title: '构词',
                icon: Icons.account_tree_outlined,
                child: Text(widget.word.wordRoot),
              ),
            if (widget.word.localizedCollocations.length >= 2)
              CardPanel(
                title: '常见搭配',
                icon: Icons.link_outlined,
                child: Column(
                  children: [
                    for (final item
                        in widget.word.localizedCollocations.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CollocationTile(
                          phrase: item.key,
                          meaning: item.value,
                        ),
                      ),
                  ],
                ),
              ),
            if (widget.word.confusingPoint.isNotEmpty)
              CardPanel(
                title: '易混点',
                icon: Icons.compare_arrows_outlined,
                child: Text(widget.word.confusingPoint),
              ),
          ],
        ),
      ),
    );
  }
}

class _CollocationTile extends StatelessWidget {
  const _CollocationTile({required this.phrase, required this.meaning});

  final String phrase;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phrase,
            style: AppText.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(meaning, style: AppText.accent),
        ],
      ),
    );
  }
}

class _HighlightedSentence extends StatelessWidget {
  const _HighlightedSentence({required this.sentence, required this.word});

  final String sentence;
  final String word;

  @override
  Widget build(BuildContext context) {
    final index = sentence.toLowerCase().indexOf(word.toLowerCase());
    if (index < 0) return Text(sentence, style: AppText.bodyLarge);

    return Text.rich(
      TextSpan(
        style: AppText.bodyLarge,
        children: [
          TextSpan(text: sentence.substring(0, index)),
          TextSpan(
            text: sentence.substring(index, index + word.length),
            style: AppText.accent.copyWith(fontWeight: FontWeight.w900),
          ),
          TextSpan(text: sentence.substring(index + word.length)),
        ],
      ),
    );
  }
}
