import 'dart:convert';
import 'dart:io';

import 'package:english_learning_app/src/data/vnext_sample_data.dart';

Future<void> main() async {
  final words =
      VNextSampleData.packLibrary
          .expand((pack) => pack.sentences)
          .expand((sentence) => sentence.focusWords)
          .map((word) => word.word.toLowerCase())
          .toSet()
          .toList()
        ..sort();
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  final phonetics = <String, String>{};
  final parts = <String, String>{};

  for (var index = 0; index < words.length; index += 4) {
    final batch = words.skip(index).take(4);
    await Future.wait(
      batch.map((word) async {
        try {
          final primary = await _lookupWiktionary(client, word);
          final fallback =
              primary.phonetic.isNotEmpty && primary.part.isNotEmpty
              ? (phonetic: '', part: '')
              : await _lookup(client, word);
          final detail = (
            phonetic: primary.phonetic.isNotEmpty
                ? primary.phonetic
                : fallback.phonetic,
            part: primary.part.isNotEmpty ? primary.part : fallback.part,
          );
          if (detail.phonetic.isNotEmpty) phonetics[word] = detail.phonetic;
          if (detail.part.isNotEmpty) parts[word] = _shortPart(detail.part);
        } catch (_) {
          // Coverage tests report missing entries after generation.
        }
      }),
    );
    stdout.writeln('Fetched ${index + batch.length}/${words.length}');
  }
  client.close(force: true);

  final output = StringBuffer()
    ..writeln(
      '// Generated from Wiktionary data via https://freedictionaryapi.com/.',
    )
    ..writeln('// Source data license: CC BY-SA 4.0.')
    ..writeln(
      '// Do not edit by hand; rerun tool/generate_dictionary_details.dart.',
    )
    ..writeln()
    ..writeln(_mapSource('generatedVocabularyPhonetics', phonetics))
    ..writeln()
    ..writeln(_mapSource('generatedVocabularyPartsOfSpeech', parts));
  await File(
    'lib/src/data/vnext_dictionary_details.g.dart',
  ).writeAsString(output.toString());
  stdout.writeln('phonetics=${phonetics.length}, parts=${parts.length}');
}

Future<({String phonetic, String part})> _lookupWiktionary(
  HttpClient client,
  String word,
) async {
  var bestPhonetic = '';
  var bestPart = '';
  for (final candidate in _lookupCandidates(word)) {
    final uri = Uri.https(
      'freedictionaryapi.com',
      '/api/v1/entries/en/$candidate',
    );
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != 200) continue;
    final body = await response.transform(utf8.decoder).join();
    final payload = jsonDecode(body) as Map<String, dynamic>;
    final entries = payload['entries'] as List<dynamic>? ?? const [];
    for (final item in entries) {
      final entry = item as Map<String, dynamic>;
      final pronunciations =
          entry['pronunciations'] as List<dynamic>? ?? const [];
      final phonetic = pronunciations
          .map((value) => value as Map<String, dynamic>)
          .where((value) => value['type'] == 'ipa')
          .map((value) => value['text']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .fold('', (best, value) => value.length > best.length ? value : best);
      if (phonetic.length > bestPhonetic.length) bestPhonetic = phonetic;
      bestPart = bestPart.isEmpty
          ? entry['partOfSpeech']?.toString() ?? ''
          : bestPart;
    }
    if (bestPhonetic.isNotEmpty && bestPart.isNotEmpty) break;
  }
  return (phonetic: bestPhonetic, part: bestPart);
}

Future<({String phonetic, String part})> _lookup(
  HttpClient client,
  String word,
) async {
  var bestPhonetic = '';
  var bestPart = '';
  for (final candidate in _lookupCandidates(word)) {
    final uri = Uri.https(
      'api.dictionaryapi.dev',
      '/api/v2/entries/en/$candidate',
    );
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != 200) continue;
    final body = await response.transform(utf8.decoder).join();
    final entries = jsonDecode(body) as List<dynamic>;
    if (entries.isEmpty) continue;
    final entry = entries.first as Map<String, dynamic>;
    final phonetics =
        <String>[
            entry['phonetic']?.toString() ?? '',
            ...(entry['phonetics'] as List<dynamic>? ?? const []).map(
              (item) =>
                  (item as Map<String, dynamic>)['text']?.toString() ?? '',
            ),
          ].where((value) => value.length >= 4).toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    final meanings = entry['meanings'] as List<dynamic>? ?? const [];
    final part = meanings
        .map(
          (item) =>
              (item as Map<String, dynamic>)['partOfSpeech']?.toString() ?? '',
        )
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    final phonetic = phonetics.isEmpty ? '' : phonetics.first;
    if (phonetic.length > bestPhonetic.length) bestPhonetic = phonetic;
    if (bestPart.isEmpty && part.isNotEmpty) bestPart = part;
    if (bestPhonetic.isNotEmpty && bestPart.isNotEmpty) break;
  }
  return (phonetic: bestPhonetic, part: bestPart);
}

List<String> _lookupCandidates(String word) {
  final values = <String>[word];
  const irregular = {
    'took': 'take',
    'worn': 'wear',
    'heard': 'hear',
    'forgot': 'forget',
    'meant': 'mean',
    'slipped': 'slip',
    'brought': 'bring',
  };
  if (irregular[word] case final base?) values.add(base);
  if (word.endsWith('ies') && word.length > 4) {
    values.add('${word.substring(0, word.length - 3)}y');
  }
  if (word.endsWith('ing') && word.length > 5) {
    final stem = word.substring(0, word.length - 3);
    values.addAll([stem, '${stem}e', _removeDoubleEnding(stem)]);
  }
  if (word.endsWith('ed') && word.length > 4) {
    final stem = word.substring(0, word.length - 2);
    values.addAll([stem, '${stem}e', _removeDoubleEnding(stem)]);
  }
  if (word.endsWith('es') && word.length > 4) {
    values.addAll([
      word.substring(0, word.length - 2),
      word.substring(0, word.length - 1),
    ]);
  } else if (word.endsWith('s') && word.length > 3) {
    values.add(word.substring(0, word.length - 1));
  }
  if (word.contains('-')) values.add(word.split('-').last);
  return values.toSet().toList();
}

String _removeDoubleEnding(String value) {
  if (value.length > 2 && value[value.length - 1] == value[value.length - 2]) {
    return value.substring(0, value.length - 1);
  }
  return value;
}

String _shortPart(String value) {
  return switch (value.toLowerCase()) {
    'noun' => 'n.',
    'verb' => 'v.',
    'adjective' => 'adj.',
    'adverb' => 'adv.',
    'pronoun' => 'pron.',
    'preposition' => 'prep.',
    'conjunction' => 'conj.',
    'interjection' => 'int.',
    _ => value,
  };
}

String _mapSource(String name, Map<String, String> values) {
  final entries = values.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final buffer = StringBuffer('const $name = <String, String>{\n');
  for (final entry in entries) {
    buffer.writeln("  '${_escape(entry.key)}': '${_escape(entry.value)}',");
  }
  return '${buffer.toString()}};';
}

String _escape(String value) {
  return value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}
