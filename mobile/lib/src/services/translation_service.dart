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
    return _examples[normalized] ?? _fallback(source);
  }

  TranslationResult _fallback(String source) {
    return TranslationResult(
      source: source,
      english: 'I want to say: $source.',
      koreanHonorific: '$source 라고 말하고 싶어요.',
      koreanCasual: '$source 라고 말하고 싶어.',
      koreanPronunciation: '$source ra-go mal-ha-go si-peo-yo / si-peo',
      usageNote: '当前是本地规则翻译，适合先验证流程；接入 AI 后会返回更自然的真实翻译。',
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
  };
}
