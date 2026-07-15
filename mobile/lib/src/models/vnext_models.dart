import 'dart:convert';

enum PracticeStep { listen, shadow, keywords, dictation, recall }

enum PracticeFlowStage { practice, consolidation, completion }

enum DialogueSpeaker { speakerA, speakerB }

enum ReviewCardType { keyword, chunk, sentence }

enum MaterialStatus { unpracticed, inProgress, practiced, mastered }

class KeywordNote {
  const KeywordNote({
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.wordRoot,
    required this.collocations,
    required this.confusingPoint,
    required this.example,
    this.partOfSpeech = '',
    this.collocationMeanings = const {},
  });

  final String word;
  final String phonetic;
  final String meaning;
  final String wordRoot;
  final List<String> collocations;
  final Map<String, String> collocationMeanings;
  final String confusingPoint;
  final String example;
  final String partOfSpeech;

  Map<String, String> get localizedCollocations => {
    for (final phrase in collocations)
      if ((collocationMeanings[phrase] ?? '').trim().isNotEmpty)
        phrase: collocationMeanings[phrase]!,
  };

  bool get hasEnhancedDetails =>
      wordRoot.isNotEmpty ||
      localizedCollocations.length >= 2 ||
      confusingPoint.isNotEmpty;
}

class SentenceNote {
  const SentenceNote({
    required this.id,
    required this.english,
    required this.chinese,
    required this.speaker,
    required this.role,
    required this.scenePrompt,
    required this.keywords,
    required this.chunk,
    required this.pattern,
    required this.dictationHint,
    required this.recallHint,
  });

  final String id;
  final String english;
  final String chinese;
  final DialogueSpeaker speaker;
  final String role;
  final String scenePrompt;
  final List<KeywordNote> keywords;
  final String chunk;
  final String pattern;
  final String dictationHint;
  final String recallHint;

  /// Only single lexical items belong in the vocabulary section. Older
  /// handcrafted data may still contain phrases in [keywords], so keep the
  /// split at the model boundary instead of forcing a local-data migration.
  List<KeywordNote> get focusWords => keywords
      .where(
        (item) =>
            RegExp(r"^[A-Za-z]+(?:[-'][A-Za-z]+)*$").hasMatch(item.word.trim()),
      )
      .toList(growable: false);

  /// Phrases are learned as chunks, never presented as individual words.
  List<String> get focusChunks {
    final values = <String>[
      chunk,
      ...keywords
          .where((item) => !focusWords.contains(item))
          .map((item) => item.word),
    ];
    final seen = <String>{};
    return values
        .where((item) => item.trim().isNotEmpty)
        .where((item) => seen.add(item.trim().toLowerCase()))
        .toList(growable: false);
  }
}

class ScenarioPack {
  const ScenarioPack({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.summary,
    required this.sceneDescription,
    required this.durationLabel,
    required this.reviewHeadline,
    required this.sentences,
  });

  final String id;
  final String title;
  final String category;
  final String difficulty;
  final String summary;
  final String sceneDescription;
  final String durationLabel;
  final String reviewHeadline;
  final List<SentenceNote> sentences;
}

class ReviewCard {
  const ReviewCard({
    required this.id,
    required this.type,
    required this.front,
    required this.back,
    required this.hint,
    required this.sourceSentenceId,
    required this.tags,
    required this.memoryLevel,
    required this.nextReviewAt,
    required this.lastReviewedAt,
    this.sourcePackId = '',
    this.sourcePackTitle = '',
    this.isUserAdded = false,
    this.personalNote = '',
  });

  final String id;
  final ReviewCardType type;
  final String front;
  final String back;
  final String hint;
  final String sourceSentenceId;
  final List<String> tags;
  final int memoryLevel;
  final String nextReviewAt;
  final String lastReviewedAt;
  final String sourcePackId;
  final String sourcePackTitle;
  final bool isUserAdded;
  final String personalNote;

  bool get isMastered => memoryLevel >= 1;

  ReviewCard copyWith({
    ReviewCardType? type,
    String? front,
    String? back,
    String? hint,
    String? sourceSentenceId,
    List<String>? tags,
    int? memoryLevel,
    String? nextReviewAt,
    String? lastReviewedAt,
    String? sourcePackId,
    String? sourcePackTitle,
    bool? isUserAdded,
    String? personalNote,
  }) {
    return ReviewCard(
      id: id,
      type: type ?? this.type,
      front: front ?? this.front,
      back: back ?? this.back,
      hint: hint ?? this.hint,
      sourceSentenceId: sourceSentenceId ?? this.sourceSentenceId,
      tags: tags ?? this.tags,
      memoryLevel: memoryLevel ?? this.memoryLevel,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      sourcePackId: sourcePackId ?? this.sourcePackId,
      sourcePackTitle: sourcePackTitle ?? this.sourcePackTitle,
      isUserAdded: isUserAdded ?? this.isUserAdded,
      personalNote: personalNote ?? this.personalNote,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.name,
      'front': front,
      'back': back,
      'hint': hint,
      'sourceSentenceId': sourceSentenceId,
      'tags': tags,
      'memoryLevel': memoryLevel,
      'nextReviewAt': nextReviewAt,
      'lastReviewedAt': lastReviewedAt,
      'sourcePackId': sourcePackId,
      'sourcePackTitle': sourcePackTitle,
      'isUserAdded': isUserAdded,
      'personalNote': personalNote,
    };
  }

  factory ReviewCard.fromJson(Map<String, dynamic> json) {
    return ReviewCard(
      id: json['id']?.toString() ?? '',
      type: ReviewCardType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () => ReviewCardType.keyword,
      ),
      front: json['front']?.toString() ?? '',
      back: json['back']?.toString() ?? '',
      hint: json['hint']?.toString() ?? '',
      sourceSentenceId: json['sourceSentenceId']?.toString() ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      memoryLevel: _intValue(json['memoryLevel']),
      nextReviewAt: json['nextReviewAt']?.toString() ?? '',
      lastReviewedAt: json['lastReviewedAt']?.toString() ?? '',
      sourcePackId: json['sourcePackId']?.toString() ?? '',
      sourcePackTitle: json['sourcePackTitle']?.toString() ?? '',
      isUserAdded: json['isUserAdded'] == true,
      personalNote: json['personalNote']?.toString() ?? '',
    );
  }
}

class SentenceProgress {
  const SentenceProgress({
    this.shadowDone = false,
    this.dictationDone = false,
    this.recallDone = false,
    this.dictationInput = '',
    this.recallInput = '',
    this.dictationAttempts = 0,
    this.recallAttempts = 0,
  });

  final bool shadowDone;
  final bool dictationDone;
  final bool recallDone;
  final String dictationInput;
  final String recallInput;
  final int dictationAttempts;
  final int recallAttempts;

  bool get isComplete => shadowDone && dictationDone && recallDone;

  SentenceProgress copyWith({
    bool? shadowDone,
    bool? dictationDone,
    bool? recallDone,
    String? dictationInput,
    String? recallInput,
    int? dictationAttempts,
    int? recallAttempts,
  }) {
    return SentenceProgress(
      shadowDone: shadowDone ?? this.shadowDone,
      dictationDone: dictationDone ?? this.dictationDone,
      recallDone: recallDone ?? this.recallDone,
      dictationInput: dictationInput ?? this.dictationInput,
      recallInput: recallInput ?? this.recallInput,
      dictationAttempts: dictationAttempts ?? this.dictationAttempts,
      recallAttempts: recallAttempts ?? this.recallAttempts,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'shadowDone': shadowDone,
      'dictationDone': dictationDone,
      'recallDone': recallDone,
      'dictationInput': dictationInput,
      'recallInput': recallInput,
      'dictationAttempts': dictationAttempts,
      'recallAttempts': recallAttempts,
    };
  }

  factory SentenceProgress.fromJson(Map<String, dynamic> json) {
    return SentenceProgress(
      shadowDone: json['shadowDone'] == true,
      dictationDone: json['dictationDone'] == true,
      recallDone: json['recallDone'] == true,
      dictationInput: json['dictationInput']?.toString() ?? '',
      recallInput: json['recallInput']?.toString() ?? '',
      dictationAttempts: _intValue(json['dictationAttempts']),
      recallAttempts: _intValue(json['recallAttempts']),
    );
  }
}

class PracticeState {
  const PracticeState({
    required this.warmupMeaningOpened,
    required this.currentSentenceIndex,
    required this.currentStep,
    required this.flowStage,
    required this.sentences,
    required this.reviewCards,
    required this.completed,
    required this.lastCompletedDate,
  });

  PracticeState.initial(int sentenceCount)
    : warmupMeaningOpened = false,
      currentSentenceIndex = 0,
      currentStep = PracticeStep.listen,
      flowStage = PracticeFlowStage.practice,
      reviewCards = const [],
      completed = false,
      lastCompletedDate = '',
      sentences = List<SentenceProgress>.filled(
        sentenceCount,
        const SentenceProgress(),
      );

  final bool warmupMeaningOpened;
  final int currentSentenceIndex;
  final PracticeStep currentStep;
  final PracticeFlowStage flowStage;
  final List<SentenceProgress> sentences;
  final List<ReviewCard> reviewCards;
  final bool completed;
  final String lastCompletedDate;

  int get completedSentenceCount {
    return sentences.where((item) => item.isComplete).length;
  }

  bool get hasAnyPracticeProgress {
    if (currentSentenceIndex > 0) return true;
    if (currentStep != PracticeStep.listen) return true;
    if (flowStage != PracticeFlowStage.practice) return true;
    return sentences.any(
      (item) =>
          item.shadowDone ||
          item.dictationDone ||
          item.recallDone ||
          item.dictationInput.isNotEmpty ||
          item.recallInput.isNotEmpty ||
          item.dictationAttempts > 0 ||
          item.recallAttempts > 0,
    );
  }

  bool get hasLearningHistory {
    return completed ||
        lastCompletedDate.isNotEmpty ||
        reviewCards.any((card) => !card.isUserAdded);
  }

  bool get isActivelyPracticing {
    return !completed && hasAnyPracticeProgress;
  }

  bool get isFullyMastered {
    return reviewCards.any((card) => !card.isUserAdded) &&
        reviewCards.every((item) => item.isMastered);
  }

  MaterialStatus get materialStatus {
    if (isFullyMastered) return MaterialStatus.mastered;
    if (isActivelyPracticing) return MaterialStatus.inProgress;
    if (hasLearningHistory) return MaterialStatus.practiced;
    return MaterialStatus.unpracticed;
  }

  PracticeState resetForTodayPractice() {
    return PracticeState(
      warmupMeaningOpened: false,
      currentSentenceIndex: 0,
      currentStep: PracticeStep.listen,
      flowStage: PracticeFlowStage.practice,
      sentences: List<SentenceProgress>.filled(
        sentences.length,
        const SentenceProgress(),
      ),
      reviewCards: reviewCards,
      completed: false,
      lastCompletedDate: lastCompletedDate,
    );
  }

  PracticeState copyWith({
    bool? warmupMeaningOpened,
    int? currentSentenceIndex,
    PracticeStep? currentStep,
    PracticeFlowStage? flowStage,
    List<SentenceProgress>? sentences,
    List<ReviewCard>? reviewCards,
    bool? completed,
    String? lastCompletedDate,
  }) {
    return PracticeState(
      warmupMeaningOpened: warmupMeaningOpened ?? this.warmupMeaningOpened,
      currentSentenceIndex: currentSentenceIndex ?? this.currentSentenceIndex,
      currentStep: currentStep ?? this.currentStep,
      flowStage: flowStage ?? this.flowStage,
      sentences: sentences ?? this.sentences,
      reviewCards: reviewCards ?? this.reviewCards,
      completed: completed ?? this.completed,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'warmupMeaningOpened': warmupMeaningOpened,
      'currentSentenceIndex': currentSentenceIndex,
      'currentStep': currentStep.name,
      'flowStage': flowStage.name,
      'completed': completed,
      'lastCompletedDate': lastCompletedDate,
      'sentences': [for (final item in sentences) item.toJson()],
      'reviewCards': [for (final item in reviewCards) item.toJson()],
    };
  }

  factory PracticeState.fromJson(Map<String, dynamic> json, int sentenceCount) {
    final rawSentences = (json['sentences'] as List<dynamic>? ?? const []);
    final rawReviewCards = (json['reviewCards'] as List<dynamic>? ?? const []);
    final decodedSentences = rawSentences
        .whereType<Map<String, dynamic>>()
        .map(SentenceProgress.fromJson)
        .toList();
    final decodedReviewCards = rawReviewCards
        .whereType<Map<String, dynamic>>()
        .map(ReviewCard.fromJson)
        .where((item) => item.id.isNotEmpty)
        .toList();
    final padded = List<SentenceProgress>.generate(sentenceCount, (index) {
      if (index < decodedSentences.length) return decodedSentences[index];
      return const SentenceProgress();
    });
    return PracticeState(
      warmupMeaningOpened: json['warmupMeaningOpened'] == true,
      currentSentenceIndex: _intValue(json['currentSentenceIndex']),
      currentStep: PracticeStep.values.firstWhere(
        (item) => item.name == json['currentStep'],
        orElse: () => PracticeStep.listen,
      ),
      flowStage: PracticeFlowStage.values.firstWhere(
        (item) => item.name == json['flowStage'],
        orElse: () => PracticeFlowStage.practice,
      ),
      sentences: padded,
      reviewCards: decodedReviewCards,
      completed: json['completed'] == true,
      lastCompletedDate: json['lastCompletedDate']?.toString() ?? '',
    );
  }
}

class PracticeCheckResult {
  const PracticeCheckResult({
    required this.correct,
    required this.message,
    required this.hints,
  });

  final bool correct;
  final String message;
  final List<String> hints;
}

String encodePracticeState(PracticeState state) => jsonEncode(state.toJson());

int _intValue(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
