import 'package:flutter/material.dart';

import '../models/learning_models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class KeywordDetailPage extends StatelessWidget {
  const KeywordDetailPage({super.key, required this.word});

  final KeyWord word;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: AppScrollPage(
          title: word.word,
          leading: IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          children: [
            CardPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(word.phonetic, style: AppText.sectionBig),
                      ),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.volume_up),
                        label: const Text('读音'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(word.meaning, style: AppText.accent),
                  const SizedBox(height: 8),
                  Text(word.example, style: AppText.bodyLarge),
                  const SizedBox(height: 8),
                  Text(word.usage, style: AppText.muted),
                ],
              ),
            ),
            CardPanel(
              title: '词根和构词',
              icon: Icons.account_tree_outlined,
              child: Text(word.wordRoot),
            ),
            CardPanel(
              title: '联想记忆',
              icon: Icons.psychology_alt_outlined,
              child: Text(word.memoryHint),
            ),
            CardPanel(
              title: '常见搭配',
              icon: Icons.link,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in word.collocations) SmallChip(label: item),
                ],
              ),
            ),
            CardPanel(
              title: '拓展词',
              icon: Icons.hub_outlined,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in word.relatedWords) SmallChip(label: item),
                ],
              ),
            ),
            CardPanel(
              title: '易混点',
              icon: Icons.compare_arrows,
              child: Text(word.confusingPoint),
            ),
          ],
        ),
      ),
    );
  }
}
