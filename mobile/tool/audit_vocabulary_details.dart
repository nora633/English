// ignore_for_file: avoid_print

import 'package:english_learning_app/src/data/vnext_sample_data.dart';

void main() {
  final words = <String>{};
  final enhancedWords = <String>{};
  final categoryWords = <String, Set<String>>{};
  final categoryEnhancedWords = <String, Set<String>>{};
  final packsWithoutEnhancedWords = <String>[];

  for (final pack in VNextSampleData.packLibrary) {
    final packHasEnhancedWord = pack.sentences
        .expand((sentence) => sentence.focusWords)
        .any((word) => word.hasEnhancedDetails);
    if (!packHasEnhancedWord) packsWithoutEnhancedWords.add(pack.id);
    final wordsInCategory = categoryWords.putIfAbsent(
      pack.category,
      () => <String>{},
    );
    final enhancedInCategory = categoryEnhancedWords.putIfAbsent(
      pack.category,
      () => <String>{},
    );
    for (final sentence in pack.sentences) {
      for (final word in sentence.focusWords) {
        words.add(word.word);
        wordsInCategory.add(word.word);
        if (word.hasEnhancedDetails) {
          enhancedWords.add(word.word);
          enhancedInCategory.add(word.word);
        }
      }
    }
  }

  print('unique focus words: ${words.length}');
  print('enhanced words: ${enhancedWords.length}');
  for (final category in categoryWords.keys) {
    print(
      '$category: ${categoryEnhancedWords[category]!.length}'
      '/${categoryWords[category]!.length}',
    );
  }
  print('packs without enhanced words: ${packsWithoutEnhancedWords.length}');
  for (final packId in packsWithoutEnhancedWords) {
    print('  $packId');
  }

  print('\nFirst priority word in every generated sentence:');
  for (final pack in VNextSampleData.packLibrary.skip(3)) {
    final firstWords = pack.sentences
        .map((sentence) => sentence.focusWords.first.word)
        .join(', ');
    print('${pack.id}: $firstWords');
  }
}
