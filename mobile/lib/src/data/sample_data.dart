import '../models/learning_models.dart';

class SampleData {
  static const themes = [
    LearningTheme(
      title: '邻里寒暄',
      stage: LearningStage.daily,
      kind: ContentKind.sitcom,
      sourceHint: 'The Neighborhood 风格',
      focus: '自然开场、接话、轻松回应',
      difficulty: 'A2-B1',
      previewTitle: '楼道里顺手打招呼',
      previewDescription: '一个邻居正准备下楼买咖啡，顺口问对方要不要带点什么。适合练自然开场和轻松回应。',
      sampleContent:
          'A: I was about to grab some coffee. Do you want anything?\n'
          'B: That makes sense. I could use one too.\n'
          'A: Do you want me to text you when I get there?\n'
          'B: Sure, thanks. I will be downstairs in ten minutes.',
      practiceSentences: [
        'I was about to grab some coffee. Do you want anything?',
        'That makes sense. I could use one too.',
        'Do you want me to text you when I get there?',
      ],
      keyVocabulary: ['grab', 'anything', 'text', 'downstairs'],
    ),
    LearningTheme(
      title: '家庭晚餐小插曲',
      stage: LearningStage.media,
      kind: ContentKind.sitcom,
      sourceHint: 'Young Sheldon 风格',
      focus: '解释原因、表达惊讶、补充细节',
      difficulty: 'B1',
      previewTitle: '餐桌上解释一个小误会',
      previewDescription: '家庭成员在晚餐时解释自己为什么迟到，语气轻松但需要补充细节。',
      sampleContent:
          'A: I did not mean to be late. I got held up after class.\n'
          'B: You could have texted us.\n'
          'A: I know. I thought I would be back in five minutes.\n'
          'B: Well, dinner is still warm.',
      practiceSentences: [
        'I did not mean to be late.',
        'I got held up after class.',
        'I thought I would be back in five minutes.',
      ],
      keyVocabulary: ['held up', 'mean to', 'texted', 'still warm'],
    ),
    LearningTheme(
      title: '热门英文歌副歌表达',
      stage: LearningStage.media,
      kind: ContentKind.song,
      sourceHint: '流行歌主题',
      focus: '情绪表达、连读、弱读',
      difficulty: 'A2-B1',
      previewTitle: '副歌式情绪表达',
      previewDescription: '不使用真实歌词，使用同类原创短句练节奏、连读和情绪表达。',
      sampleContent:
          'I keep running back to the same old place.\n'
          'I know it is late, but I still feel awake.\n'
          'If you call my name, I will find my way.',
      practiceSentences: [
        'I keep running back to the same old place.',
        'I know it is late, but I still feel awake.',
        'If you call my name, I will find my way.',
      ],
      keyVocabulary: ['running back', 'same old', 'awake', 'find my way'],
    ),
    LearningTheme(
      title: '咖啡店偶遇',
      stage: LearningStage.daily,
      kind: ContentKind.dailyLife,
      sourceHint: 'AI 生成生活场景',
      focus: '点单、寒暄、临时邀约',
      difficulty: 'A2',
      previewTitle: '咖啡店排队时偶遇同事',
      previewDescription: '适合练点单、简单寒暄和临时约时间，都是日常马上能用的句子。',
      sampleContent:
          'A: Hey, I did not expect to see you here.\n'
          'B: Same here. I am grabbing coffee before work.\n'
          'A: Do you have a minute after the meeting?\n'
          'B: Sure. Text me when you are free.',
      practiceSentences: [
        'I did not expect to see you here.',
        'I am grabbing coffee before work.',
        'Text me when you are free.',
      ],
      keyVocabulary: ['expect', 'same here', 'before work', 'free'],
    ),
    LearningTheme(
      title: '短新闻听读',
      stage: LearningStage.news,
      kind: ContentKind.news,
      sourceHint: '慢速新闻风格',
      focus: '抓主旨、数字、转折和因果',
      difficulty: 'B1-B2',
      previewTitle: '城市通勤改善计划',
      previewDescription: '一则原创慢速新闻稿，训练新闻里的数字、原因和影响。',
      sampleContent:
          'City officials announced a new public transport plan on Monday. '
          'The plan aims to reduce commute times by adding more buses during rush hour. '
          'Local residents welcomed the change, but some said the city should also improve weekend service.',
      practiceSentences: [
        'City officials announced a new public transport plan on Monday.',
        'The plan aims to reduce commute times.',
        'Some said the city should also improve weekend service.',
      ],
      keyVocabulary: ['officials', 'announced', 'commute', 'rush hour'],
    ),
    LearningTheme(
      title: '报刊观点精读',
      stage: LearningStage.reading,
      kind: ContentKind.article,
      sourceHint: '报纸/杂志评论风格',
      focus: '长句结构、观点表达、正式词汇',
      difficulty: 'B2-C1',
      previewTitle: '为什么流利度来自熟词快用',
      previewDescription: '原创观点段落，用来练正式表达、长句切分和观点复述。',
      sampleContent:
          'For many learners, fluency is less about knowing rare words and more about using familiar words quickly, accurately, and naturally. '
          'A learner who can explain simple ideas under pressure often communicates better than one who only recognizes difficult vocabulary on paper.',
      practiceSentences: [
        'Fluency is less about knowing rare words.',
        'It is more about using familiar words naturally.',
        'Simple ideas under pressure still require practice.',
      ],
      keyVocabulary: ['fluency', 'rare words', 'accurately', 'under pressure'],
    ),
  ];

  static final todayLesson = DailyLesson(
    title: '今日 15 分钟听说训练',
    durationMinutes: 15,
    completedMinutes: 0,
    theme: themes.first,
    keyWords: [
      KeyWord(
        word: 'grab',
        phonetic: '/græb/',
        meaning: '顺手买 / 拿 / 吃点',
        usage: '比 buy 更生活化，适合咖啡、午饭、东西',
        example: 'I was about to grab some coffee.',
        priority: '必练',
        wordRoot: '本义是“抓住、拿起”，口语里延伸成“顺手买/弄点”。',
        memoryHint: '想象出门前顺手“抓”一杯咖啡，不是正式购买动作，而是顺路带一下。',
        collocations: ['grab coffee', 'grab lunch', 'grab a seat'],
        relatedWords: ['get', 'pick up', 'buy'],
        confusingPoint: 'grab 比 buy 更随意；buy 强调购买，grab 强调顺手、快速、生活化。',
      ),
      KeyWord(
        word: 'about to',
        phonetic: '/əˈbaʊt tuː/',
        meaning: '正准备要做某事',
        usage: '表达马上要发生的动作，日常口语高频',
        example: 'I was about to head downstairs.',
        priority: '必练',
        wordRoot: 'about 表示“围绕/接近”，about to 表示动作已经接近发生。',
        memoryHint: '把它理解成“箭已经拉满，马上要射出去”的状态。',
        collocations: [
          'be about to leave',
          'be about to start',
          'be about to call',
        ],
        relatedWords: ['going to', 'just about to', 'almost'],
        confusingPoint: 'about to 比 going to 更近，通常是“马上就要”。',
      ),
      KeyWord(
        word: 'anything',
        phonetic: '/ˈeniθɪŋ/',
        meaning: '任何东西 / 要带什么吗',
        usage: '寒暄和顺手帮忙时很自然',
        example: 'Do you want anything?',
        priority: '听写',
        wordRoot: 'any 表示“任意”，thing 表示“东西/事情”，合起来是“任何东西”。',
        memoryHint: '把 any + thing 拆开记：我不知道你具体要什么，所以问“任何东西”。',
        collocations: ['need anything', 'want anything', 'anything else'],
        relatedWords: ['something', 'nothing', 'everything'],
        confusingPoint: '疑问句里常用 anything；肯定句里说“某个东西”更常用 something。',
      ),
      KeyWord(
        word: 'text',
        phonetic: '/tekst/',
        meaning: '发短信 / 发消息',
        usage: '日常安排、到达提醒、临时沟通',
        example: 'I can text you when I get there.',
        priority: '复用',
        wordRoot: '原本是“文本”，现代口语里直接当动词，表示“发文字消息”。',
        memoryHint: '看到 text 不只想到“课文”，也想到手机里的文字消息。',
        collocations: ['text you', 'text me back', 'send a text'],
        relatedWords: ['message', 'DM', 'call'],
        confusingPoint: 'text 通常指发文字消息；message 更宽，可以是各种平台消息。',
      ),
    ],
    grammarPoints: [
      GrammarPoint(
        pattern: 'I was about to + 动词原形',
        meaning: '我正准备做某事',
        example: 'I was about to grab some coffee.',
        note: '适合解释自己马上要做的动作，比 I will 更有现场感。',
      ),
      GrammarPoint(
        pattern: 'Do you want me to + 动词原形?',
        meaning: '你要我帮你做某事吗？',
        example: 'Do you want me to text you when I get there?',
        note: '日常帮忙、顺手询问时很自然。',
      ),
      GrammarPoint(
        pattern: 'when + 主语 + 动词',
        meaning: '当某事发生时',
        example: 'I can text you when I get there.',
        note: '口语里常用来说明时间条件。',
      ),
    ],
    targetChunks: [
      'I was about to...',
      'That makes sense.',
      'Do you want me to...?',
    ],
    listeningLines: [
      'I was about to grab some coffee. Do you want anything?',
      'That makes sense. I would probably do the same thing.',
      'Do you want me to text you when I get there?',
      'I did not mean to interrupt. I just wanted to check in.',
      'Let me know if you need anything from downstairs.',
    ],
  );

  static const speakingScore = SpeakingScore(
    clarity: 82,
    fluency: 76,
    completeness: 88,
    naturalness: 73,
    transcript:
        'I was about to get coffee and my neighbor asked me about the meeting. I said that makes sense and I can text her when I get there.',
    suggestions: [
      '把 I can text her 改成 I can text you，情景对话里更自然。',
      'about to 后面直接接动词原形，保持 I was about to get coffee。',
      '复述时可以补一句 Do you want me to grab one for you? 来增加互动感。',
    ],
  );

  static const review = ReviewSummary(
    streakDays: 3,
    completedMinutes: 45,
    reusableExpression:
        'I was about to grab some coffee. Do you want anything?',
    nextFocus: '明天重点练连读：want me to / text you when',
    recommendation: DailyRecommendation(
      title: '咖啡店偶遇',
      stage: LearningStage.daily,
      difficulty: 'A2-B1',
      reason: '今天仍在日常表达阶段，先把 about to、grab、anything 练到能听、写、说出来。',
      weakFocus: '听写复现 anything / downstairs，跟读继续练 want me to 的连读。',
      mix: '60% 复习弱项 · 30% 同级新场景 · 10% 轻挑战',
      keywords: ['grab', 'anything', 'downstairs', 'want me to'],
    ),
  );
}
