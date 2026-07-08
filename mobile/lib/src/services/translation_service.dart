import 'dart:convert';

import 'package:http/http.dart' as http;

class TranslationResult {
  const TranslationResult({
    required this.source,
    required this.english,
    required this.koreanHonorific,
    required this.koreanCasual,
    required this.koreanPronunciation,
    required this.usageNote,
  });

  final String source;
  final String english;
  final String koreanHonorific;
  final String koreanCasual;
  final String koreanPronunciation;
  final String usageNote;

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      source: json['source']?.toString() ?? '',
      english: json['english']?.toString() ?? '',
      koreanHonorific: json['koreanHonorific']?.toString() ?? '',
      koreanCasual: json['koreanCasual']?.toString() ?? '',
      koreanPronunciation: json['koreanPronunciation']?.toString() ?? '',
      usageNote: json['usageNote']?.toString() ?? '',
    );
  }

  Map<String, String> toJson() {
    return {
      'source': source,
      'english': english,
      'koreanHonorific': koreanHonorific,
      'koreanCasual': koreanCasual,
      'koreanPronunciation': koreanPronunciation,
      'usageNote': usageNote,
    };
  }
}

class TranslationGateway {
  const TranslationGateway({
    this.remote = const RemoteTranslationService(),
    this.local = const TranslationService(),
  });

  final RemoteTranslationService remote;
  final TranslationService local;

  Future<TranslationResponse> translate(String text) async {
    final source = text.trim();
    if (source.isEmpty) {
      return TranslationResponse(
        result: local.translate(source),
        source: TranslationSource.local,
      );
    }

    if (remote.isConfigured) {
      try {
        final result = await remote.translate(source);
        return TranslationResponse(
          result: result,
          source: TranslationSource.ai,
        );
      } catch (_) {
        return TranslationResponse(
          result: local.translate(source),
          source: TranslationSource.localFallback,
        );
      }
    }

    return TranslationResponse(
      result: local.translate(source),
      source: TranslationSource.local,
    );
  }
}

class TranslationResponse {
  const TranslationResponse({required this.result, required this.source});

  final TranslationResult result;
  final TranslationSource source;
}

enum TranslationSource {
  ai('AI 翻译'),
  local('本地词库'),
  localFallback('AI 暂不可用，已用本地词库');

  const TranslationSource(this.label);

  final String label;
}

class RemoteTranslationService {
  const RemoteTranslationService({
    this.baseUrl = const String.fromEnvironment('AI_TRANSLATION_API_BASE'),
    this.clientFactory = _defaultClientFactory,
  });

  final String baseUrl;
  final http.Client Function() clientFactory;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Future<TranslationResult> translate(String text) async {
    final endpoint = Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/translate',
    );
    final client = clientFactory();

    try {
      final response = await client.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RemoteTranslationException('AI 翻译接口返回 ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const RemoteTranslationException('AI 翻译接口返回格式不正确');
      }

      return TranslationResult.fromJson(body);
    } finally {
      client.close();
    }
  }
}

http.Client _defaultClientFactory() => http.Client();

class RemoteTranslationException implements Exception {
  const RemoteTranslationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TranslationService {
  const TranslationService();

  TranslationResult translate(String text) {
    final source = text.trim();
    if (source.isEmpty) {
      return const TranslationResult(
        source: '',
        english: '',
        koreanHonorific: '',
        koreanCasual: '',
        koreanPronunciation: '',
        usageNote: '',
      );
    }

    final normalized = source.replaceAll(RegExp(r'[。！？!?，,\s]'), '');
    return _examples[normalized] ??
        _translatePattern(normalized, source) ??
        _fallback(source);
  }

  TranslationResult? _translatePattern(String normalized, String source) {
    final wantMatch =
        RegExp(r'^我想要(.+)$').firstMatch(normalized) ??
        RegExp(r'^我要(.+)$').firstMatch(normalized);
    if (wantMatch != null) {
      final object = _objects[wantMatch.group(1)];
      if (object != null) {
        return TranslationResult(
          source: source,
          english: 'I would like ${object.english}.',
          koreanHonorific: '${object.korean} 주세요.',
          koreanCasual: '${object.korean} 줘.',
          koreanPronunciation:
              '${object.pronunciation} ju-se-yo / ${object.pronunciation} jwo',
          usageNote: '点单或提出需求时，英文用 I would like 更礼貌；韩语用 주세요 最自然。',
        );
      }
    }

    final learningMatch = RegExp(r'^我正在学习(.+)$').firstMatch(normalized);
    if (learningMatch != null) {
      final language = _languages[learningMatch.group(1)];
      if (language != null) {
        return TranslationResult(
          source: source,
          english: 'I am learning ${language.english}.',
          koreanHonorific: '저는 ${language.korean} 공부하고 있어요.',
          koreanCasual: '나는 ${language.korean} 공부하고 있어.',
          koreanPronunciation:
              'jeo-neun ${language.pronunciation} gong-bu-ha-go i-sseo-yo / na-neun ${language.pronunciation} gong-bu-ha-go i-sseo',
          usageNote: '正在学习某种语言时，这个句型很稳：I am learning + 语言。',
        );
      }
    }

    final likeMatch = RegExp(r'^我喜欢(.+)$').firstMatch(normalized);
    if (likeMatch != null) {
      final object =
          _objects[likeMatch.group(1)] ?? _topics[likeMatch.group(1)];
      if (object != null) {
        return TranslationResult(
          source: source,
          english: 'I like ${object.english}.',
          koreanHonorific: '저는 ${object.korean} 좋아해요.',
          koreanCasual: '나는 ${object.korean} 좋아해.',
          koreanPronunciation:
              'jeo-neun ${object.pronunciation} jo-a-hae-yo / na-neun ${object.pronunciation} jo-a-hae',
          usageNote: '表达喜欢时，英文直接用 I like；韩语敬语用 좋아해요。',
        );
      }
    }

    final helpMatch = RegExp(r'^请帮我(.+)$').firstMatch(normalized);
    if (helpMatch != null) {
      final action = _actions[helpMatch.group(1)];
      if (action != null) {
        return TranslationResult(
          source: source,
          english: 'Could you please ${action.english}?',
          koreanHonorific: '${action.koreanHonorific} 주시겠어요?',
          koreanCasual: '${action.koreanCasual} 줄래?',
          koreanPronunciation:
              '${action.pronunciationHonorific} ju-si-ge-sseo-yo / ${action.pronunciationCasual} jul-lae',
          usageNote: '请别人帮忙时，Could you please 比 Please help me 更自然。',
        );
      }
    }

    return null;
  }

  TranslationResult _fallback(String source) {
    return TranslationResult(
      source: source,
      english: '本地词库暂未覆盖这句话。',
      koreanHonorific: '本地词库暂未覆盖这句话。',
      koreanCasual: '本地词库暂未覆盖这句话。',
      koreanPronunciation: '未收录',
      usageNote: '为了避免给你错误翻译，自用版只返回已收录或可由本地句型规则生成的内容。后续接入 AI 后再支持任意中文翻译。',
    );
  }

  static const Map<String, TranslationResult> _examples = {
    '你好': TranslationResult(
      source: '你好',
      english: 'Hello.',
      koreanHonorific: '안녕하세요.',
      koreanCasual: '안녕.',
      koreanPronunciation: 'an-nyeong-ha-se-yo / an-nyeong',
      usageNote: '敬语用于陌生人、长辈或正式场景；平语用于朋友、同龄人和亲近关系。',
    ),
    '谢谢': TranslationResult(
      source: '谢谢',
      english: 'Thank you.',
      koreanHonorific: '감사합니다.',
      koreanCasual: '고마워.',
      koreanPronunciation: 'gam-sa-ham-ni-da / go-ma-wo',
      usageNote: '감사합니다 更正式；고마워 更亲近。',
    ),
    '我想要一杯咖啡': TranslationResult(
      source: '我想要一杯咖啡',
      english: 'I would like a cup of coffee.',
      koreanHonorific: '커피 한 잔 주세요.',
      koreanCasual: '커피 한 잔 줘.',
      koreanPronunciation: 'keo-pi han jan ju-se-yo / keo-pi han jan jwo',
      usageNote: '点单时用 주세요 很自然，比直译“我想要”更像真实场景。',
    ),
    '我要一杯咖啡': TranslationResult(
      source: '我要一杯咖啡',
      english: 'I would like a cup of coffee.',
      koreanHonorific: '커피 한 잔 주세요.',
      koreanCasual: '커피 한 잔 줘.',
      koreanPronunciation: 'keo-pi han jan ju-se-yo / keo-pi han jan jwo',
      usageNote: '点单时用 주세요 很自然，比直译“我要”更礼貌。',
    ),
    '你吃饭了吗': TranslationResult(
      source: '你吃饭了吗',
      english: 'Have you eaten?',
      koreanHonorific: '식사하셨어요?',
      koreanCasual: '밥 먹었어?',
      koreanPronunciation: 'sik-sa-ha-syeo-sseo-yo / bap meo-geo-sseo',
      usageNote: '韩语日常问候常用“吃饭了吗”，敬语和平语差异很明显。',
    ),
    '我正在学习英语': TranslationResult(
      source: '我正在学习英语',
      english: 'I am learning English.',
      koreanHonorific: '저는 영어를 공부하고 있어요.',
      koreanCasual: '나는 영어를 공부하고 있어.',
      koreanPronunciation:
          'jeo-neun yeong-eo-reul gong-bu-ha-go i-sseo-yo / na-neun yeong-eo-reul gong-bu-ha-go i-sseo',
      usageNote: '저는 更礼貌克制；나는 更随意亲近。',
    ),
    '我马上到': TranslationResult(
      source: '我马上到',
      english: 'I will be there soon.',
      koreanHonorific: '곧 도착할게요.',
      koreanCasual: '곧 도착할게.',
      koreanPronunciation: 'got do-cha-kal-ge-yo / got do-cha-kal-ge',
      usageNote: '약속、见面路上都可以用，语气自然。',
    ),
    '多少钱': TranslationResult(
      source: '多少钱',
      english: 'How much is it?',
      koreanHonorific: '얼마예요?',
      koreanCasual: '얼마야?',
      koreanPronunciation: 'eol-ma-ye-yo / eol-ma-ya',
      usageNote: '购物、点单都能用；敬语更适合店员和陌生人。',
    ),
    '卫生间在哪里': TranslationResult(
      source: '卫生间在哪里',
      english: 'Where is the restroom?',
      koreanHonorific: '화장실이 어디예요?',
      koreanCasual: '화장실 어디야?',
      koreanPronunciation: 'hwa-jang-sil-i eo-di-ye-yo / hwa-jang-sil eo-di-ya',
      usageNote: '出门旅行高频句。英文 restroom 比 toilet 更柔和。',
    ),
  };

  static const Map<String, _Term> _objects = {
    '一杯咖啡': _Term('a cup of coffee', '커피 한 잔', 'keo-pi han jan'),
    '咖啡': _Term('coffee', '커피', 'keo-pi'),
    '一杯水': _Term('a glass of water', '물 한 잔', 'mul han jan'),
    '水': _Term('water', '물', 'mul'),
    '一杯茶': _Term('a cup of tea', '차 한 잔', 'cha han jan'),
    '茶': _Term('tea', '차', 'cha'),
    '票': _Term('a ticket', '표', 'pyo'),
    '这个': _Term('this', '이거', 'i-geo'),
    '英语': _Term('English', '영어', 'yeong-eo'),
    '韩语': _Term('Korean', '한국어', 'han-gu-geo'),
  };

  static const Map<String, _Term> _topics = {
    '英语': _Term('English', '영어를', 'yeong-eo-reul'),
    '韩语': _Term('Korean', '한국어를', 'han-gu-geo-reul'),
    '咖啡': _Term('coffee', '커피를', 'keo-pi-reul'),
    '音乐': _Term('music', '음악을', 'eu-mak-eul'),
  };

  static const Map<String, _Term> _languages = {
    '英语': _Term('English', '영어를', 'yeong-eo-reul'),
    '韩语': _Term('Korean', '한국어를', 'han-gu-geo-reul'),
    '日语': _Term('Japanese', '일본어를', 'il-bo-neo-reul'),
  };

  static const Map<String, _ActionTerm> _actions = {
    '拍照': _ActionTerm(
      'take a photo for me',
      '사진을 찍어',
      '사진 찍어',
      'sa-jin-eul jji-geo',
      'sa-jin jji-geo',
    ),
    '看一下': _ActionTerm('take a look', '봐', '봐', 'bwa', 'bwa'),
    '确认一下': _ActionTerm('check it', '확인해', '확인해', 'hwa-gin-hae', 'hwa-gin-hae'),
  };
}

class _Term {
  const _Term(this.english, this.korean, this.pronunciation);

  final String english;
  final String korean;
  final String pronunciation;
}

class _ActionTerm {
  const _ActionTerm(
    this.english,
    this.koreanHonorific,
    this.koreanCasual,
    this.pronunciationHonorific,
    this.pronunciationCasual,
  );

  final String english;
  final String koreanHonorific;
  final String koreanCasual;
  final String pronunciationHonorific;
  final String pronunciationCasual;
}
