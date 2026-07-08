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
      title: '东邻西舍 S01E06 灵感：邻里帮忙的分寸',
      stage: LearningStage.media,
      kind: ContentKind.sitcom,
      sourceHint: '本地参考素材 · 不保存原台词',
      focus: '主动帮忙、解释边界、缓和尴尬',
      difficulty: 'B1',
      previewTitle: '邻居热心帮忙但有点越界',
      previewDescription: '基于第 6 集台词本做学习方向参考，练习内容为原创改写，重点是“我想帮忙”和“别让人误会”的表达。',
      sampleContent:
          'A: I was only trying to help, but I may have gone too far.\n'
          'B: I know you meant well. I just need a little space.\n'
          'A: That is fair. I did not want to come across as pushy.\n'
          'B: Thanks for saying that. We can figure it out together.',
      practiceSentences: [
        'I was only trying to help, but I may have gone too far.',
        'I know you meant well. I just need a little space.',
        'I did not want to come across as pushy.',
      ],
      keyVocabulary: ['meant well', 'go too far', 'space', 'pushy'],
    ),
    LearningTheme(
      title: '东邻西舍 S01E07 灵感：社区活动接话',
      stage: LearningStage.media,
      kind: ContentKind.sitcom,
      sourceHint: '本地参考素材 · 不保存原台词',
      focus: '参与活动、临时安排、自然接话',
      difficulty: 'B1',
      previewTitle: '社区活动前的轻松对话',
      previewDescription: '基于第 7 集台词本做学习方向参考，练习内容为原创改写，重点是参与、拒绝、补救和接话。',
      sampleContent:
          'A: Are you still coming to the block party tonight?\n'
          'B: I am trying to make it work. Things got a little busy.\n'
          'A: No pressure. We could always use another pair of hands.\n'
          'B: Count me in. Just tell me where to start.',
      practiceSentences: [
        'Are you still coming to the block party tonight?',
        'I am trying to make it work.',
        'Count me in. Just tell me where to start.',
      ],
      keyVocabulary: [
        'block party',
        'make it work',
        'no pressure',
        'count me in',
      ],
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

  static DailyLesson lessonForTheme(LearningTheme theme) {
    final lines = _listeningLinesFor(theme);
    final keywords = theme.keyVocabulary
        .take(4)
        .map((word) => _keywordFor(word, theme))
        .toList();

    return DailyLesson(
      title: '今日 15 分钟听说训练',
      durationMinutes: 15,
      completedMinutes: 0,
      theme: theme,
      keyWords: keywords.isEmpty ? todayLesson.keyWords : keywords,
      grammarPoints: _grammarFor(theme),
      targetChunks: theme.practiceSentences.take(3).toList(),
      listeningLines: lines,
    );
  }

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

  static List<String> _listeningLinesFor(LearningTheme theme) {
    return switch (theme.title) {
      '邻里寒暄' => todayLesson.listeningLines,
      '家庭晚餐小插曲' => const [
        'I did not mean to be late.',
        'I got held up after class.',
        'You could have texted us.',
        'I thought I would be back in five minutes.',
        'Well, dinner is still warm.',
      ],
      '东邻西舍 S01E06 灵感：邻里帮忙的分寸' => const [
        'I was only trying to help, but I may have gone too far.',
        'I know you meant well.',
        'I just need a little space.',
        'I did not want to come across as pushy.',
        'We can figure it out together.',
      ],
      '东邻西舍 S01E07 灵感：社区活动接话' => const [
        'Are you still coming to the block party tonight?',
        'I am trying to make it work.',
        'Things got a little busy.',
        'We could always use another pair of hands.',
        'Count me in. Just tell me where to start.',
      ],
      '热门英文歌副歌表达' => const [
        'I keep running back to the same old place.',
        'I know it is late, but I still feel awake.',
        'If you call my name, I will find my way.',
        'I do not want to lose this feeling tonight.',
        'We can take it slow and make it right.',
      ],
      '咖啡店偶遇' => const [
        'I did not expect to see you here.',
        'I am grabbing coffee before work.',
        'Do you have a minute after the meeting?',
        'Text me when you are free.',
        'Maybe we can catch up for ten minutes.',
      ],
      '短新闻听读' => const [
        'City officials announced a new public transport plan on Monday.',
        'The plan aims to reduce commute times during rush hour.',
        'More buses will be added to several busy routes.',
        'Local residents welcomed the change.',
        'Some said the city should also improve weekend service.',
      ],
      '报刊观点精读' => const [
        'Fluency is less about knowing rare words.',
        'It is more about using familiar words quickly and naturally.',
        'Simple ideas under pressure still require practice.',
        'Many learners recognize difficult vocabulary on paper.',
        'Real communication depends on words you can use right away.',
      ],
      _ => [
        ...theme.practiceSentences,
        ...todayLesson.listeningLines,
      ].take(5).toList(),
    };
  }

  static KeyWord _keywordFor(String word, LearningTheme theme) {
    final data = switch (word) {
      'held up' => (
        phonetic: '/held ʌp/',
        meaning: '被耽搁',
        usage: '解释自己迟到或事情被拖住',
        example: 'I got held up after class.',
        root: 'hold 表示“抓住/拖住”，held up 就是被事情拖住。',
        memory: '想象有人把你拦住，所以你没有按时到。',
        confusing: 'held up 强调被耽搁；late 只是结果。',
      ),
      'mean to' => (
        phonetic: '/miːn tuː/',
        meaning: '有意要做某事',
        usage: '解释“我不是故意的”',
        example: 'I did not mean to be late.',
        root: 'mean 有“意思/意图”，mean to 就是“打算”。',
        memory: '把它记成“我的意思不是要这样”。',
        confusing: 'mean to 后接动词原形；mean doing 表示“意味着”。',
      ),
      'running back' => (
        phonetic: '/ˈrʌnɪŋ bæk/',
        meaning: '一次次回到',
        usage: '表达情绪或习惯反复',
        example: 'I keep running back to the same old place.',
        root: 'run back 字面是跑回去，口语里可指反复回到某状态。',
        memory: '像副歌一样反复回到同一句旋律。',
        confusing: 'running back 更有画面感；returning 更正式。',
      ),
      'same old' => (
        phonetic: '/seɪm oʊld/',
        meaning: '老样子 / 还是那样',
        usage: '轻松描述重复的状态',
        example: 'I keep running back to the same old place.',
        root: 'same 是相同，old 是旧的，合起来就是“老一套”。',
        memory: '想到“还是那个老地方”。',
        confusing: 'same old 常带一点口语感和情绪。',
      ),
      'meant well' => (
        phonetic: '/ment wel/',
        meaning: '本意是好的',
        usage: '替别人或自己解释善意',
        example: 'I know you meant well.',
        root: 'mean 表示“意图”，meant well 就是“出发点是好的”。',
        memory: '把它理解成“你的意思是往好的方向去”。',
        confusing: 'meant well 强调动机；did well 强调结果做得好。',
      ),
      'go too far' => (
        phonetic: '/ɡoʊ tuː fɑːr/',
        meaning: '做过头 / 越界',
        usage: '解释好心帮忙但分寸过了',
        example: 'I may have gone too far.',
        root: 'far 是远，go too far 就是走得太远、超过边界。',
        memory: '想象帮忙本来是靠近，对方却觉得你走过线了。',
        confusing: 'go too far 常说行为过界；too much 更宽泛。',
      ),
      'space' => (
        phonetic: '/speɪs/',
        meaning: '空间 / 独处余地',
        usage: '委婉表达需要一点距离',
        example: 'I just need a little space.',
        root: 'space 是空间，关系里表示心理和行动上的余地。',
        memory: '不是物理房间，而是给对方喘口气的空间。',
        confusing: 'space 比 leave me alone 更温和。',
      ),
      'pushy' => (
        phonetic: '/ˈpʊʃi/',
        meaning: '过于强势 / 咄咄逼人',
        usage: '形容好心但让人有压力的态度',
        example: 'I did not want to come across as pushy.',
        root: 'push 是推，pushy 就像一直推着别人做决定。',
        memory: '你越推，对方越有压力。',
        confusing: 'pushy 是负面；helpful 是正面。',
      ),
      'block party' => (
        phonetic: '/blɑːk ˈpɑːrti/',
        meaning: '街区聚会',
        usage: '邻里社区活动的常见说法',
        example: 'Are you still coming to the block party tonight?',
        root: 'block 指街区，party 是聚会。',
        memory: '整条街区的人一起办的小聚会。',
        confusing: 'block party 是社区聚会，不是普通室内 party。',
      ),
      'make it work' => (
        phonetic: '/meɪk ɪt wɜːrk/',
        meaning: '想办法安排好 / 让它可行',
        usage: '时间紧、事情多时表达尽量协调',
        example: 'I am trying to make it work.',
        root: 'make something work 就是把事情调整到能运转。',
        memory: '像调时间表，把卡住的事情调到能跑起来。',
        confusing: 'make it work 比 can do 更强调“努力协调”。',
      ),
      'no pressure' => (
        phonetic: '/noʊ ˈpreʃər/',
        meaning: '不用有压力',
        usage: '邀请别人时降低对方负担',
        example: 'No pressure. We could always use another pair of hands.',
        root: 'pressure 是压力，no pressure 就是不施压。',
        memory: '邀请后补一句，让对方更容易舒服地回应。',
        confusing: 'no pressure 不是完全不在乎，而是不给对方压力。',
      ),
      'count me in' => (
        phonetic: '/kaʊnt miː ɪn/',
        meaning: '算我一个',
        usage: '答应参加活动或帮忙',
        example: 'Count me in. Just tell me where to start.',
        root: 'count 是计算，把我算进去就是我参加。',
        memory: '名单上加上我的名字。',
        confusing: 'count me in 是加入；count on me 是依靠我。',
      ),
      'expect' => (
        phonetic: '/ɪkˈspekt/',
        meaning: '预料 / 期待',
        usage: '表达没想到会遇见某人',
        example: 'I did not expect to see you here.',
        root: 'ex- 向外，spect 看，expect 像“向外看着等”。',
        memory: '你本来没往这个方向看，所以没想到。',
        confusing: 'expect 是预料；hope 是希望。',
      ),
      'same here' => (
        phonetic: '/seɪm hɪr/',
        meaning: '我也是',
        usage: '自然接话，表示同感',
        example: 'Same here. I am grabbing coffee before work.',
        root: 'same here 字面是“这里也一样”。',
        memory: '对方说一个状态，你把它接到自己这里。',
        confusing: 'same here 比 me too 更完整一点，适合回应整句话。',
      ),
      'officials' => (
        phonetic: '/əˈfɪʃəlz/',
        meaning: '官员 / 官方人员',
        usage: '新闻稿里说明消息来源',
        example: 'City officials announced a new public transport plan.',
        root: 'office 办公机构，official 是官方人员。',
        memory: '新闻里“谁宣布”，经常是 officials。',
        confusing: 'official 作名词是官员，作形容词是官方的。',
      ),
      'commute' => (
        phonetic: '/kəˈmjuːt/',
        meaning: '通勤',
        usage: '新闻和日常都常见',
        example: 'The plan aims to reduce commute times.',
        root: 'commute 表示规律往返，常指上下班路程。',
        memory: '每天公司和家之间来回，就是 commute。',
        confusing: 'commute 是通勤；travel 范围更大。',
      ),
      'fluency' => (
        phonetic: '/ˈfluːənsi/',
        meaning: '流利度',
        usage: '讨论语言能力时常用',
        example: 'Fluency is less about knowing rare words.',
        root: 'flu 像 flow，强调语言流动起来。',
        memory: '话能像水一样流出来，就是 fluency。',
        confusing: 'fluency 偏流畅；accuracy 偏准确。',
      ),
      'under pressure' => (
        phonetic: '/ˈʌndər ˈpreʃər/',
        meaning: '在压力下',
        usage: '描述真实交流场景',
        example: 'Simple ideas under pressure still require practice.',
        root: 'pressure 是压力，under pressure 就是在压力之下。',
        memory: '考试、开会、对话卡壳时都算 under pressure。',
        confusing: 'under pressure 强调外部压力；nervous 是自己的紧张感。',
      ),
      _ => (
        phonetic: '',
        meaning: '本素材中的关键表达',
        usage: theme.focus,
        example: theme.practiceSentences.isEmpty
            ? theme.sampleContent
            : theme.practiceSentences.first,
        root: '先把它放回完整句子里记，不孤立背单词。',
        memory: '把这个表达和“${theme.previewTitle}”这个场景绑定。',
        confusing: '优先记它在今天句子里的用法，再拓展其它意思。',
      ),
    };

    return KeyWord(
      word: word,
      phonetic: data.phonetic,
      meaning: data.meaning,
      usage: data.usage,
      example: data.example,
      priority: '必练',
      wordRoot: data.root,
      memoryHint: data.memory,
      collocations: _collocationsFor(word),
      relatedWords: const [],
      confusingPoint: data.confusing,
    );
  }

  static List<String> _collocationsFor(String word) {
    return switch (word) {
      'grab' => const ['grab coffee', 'grab lunch', 'grab a seat'],
      'anything' => const ['need anything', 'want anything', 'anything else'],
      'text' => const ['text me', 'text you later', 'send a text'],
      'held up' => const [
        'get held up',
        'held up at work',
        'held up after class',
      ],
      'meant well' => const [
        'mean well',
        'meant well',
        'I know you meant well',
      ],
      'go too far' => const ['go too far', 'went too far', 'take it too far'],
      'space' => const ['need space', 'give someone space', 'a little space'],
      'pushy' => const ['sound pushy', 'come across as pushy', 'too pushy'],
      'block party' => const [
        'block party',
        'neighborhood party',
        'street event',
      ],
      'make it work' => const [
        'make it work',
        'try to make it work',
        'make time',
      ],
      'no pressure' => const [
        'no pressure',
        'take your time',
        'only if you can',
      ],
      'count me in' => const ['count me in', 'sign me up', 'I am in'],
      'expect' => const ['expect to see', 'did not expect', 'as expected'],
      'commute' => const ['commute time', 'morning commute', 'daily commute'],
      'fluency' => const [
        'build fluency',
        'speaking fluency',
        'fluency practice',
      ],
      _ => [word],
    };
  }

  static List<GrammarPoint> _grammarFor(LearningTheme theme) {
    return switch (theme.stage) {
      LearningStage.daily => const [
        GrammarPoint(
          pattern: 'I did not expect to + 动词原形',
          meaning: '我没想到会做/看到某事',
          example: 'I did not expect to see you here.',
          note: '偶遇、惊讶、轻松开场都很好用。',
        ),
        GrammarPoint(
          pattern: 'Do you have a minute?',
          meaning: '你有空吗？',
          example: 'Do you have a minute after the meeting?',
          note: '比 Are you free 更自然、轻一点。',
        ),
      ],
      LearningStage.media => const [
        GrammarPoint(
          pattern: 'I did not mean to + 动词原形',
          meaning: '我不是故意要做某事',
          example: 'I did not mean to be late.',
          note: '解释误会时很常用。',
        ),
        GrammarPoint(
          pattern: 'I keep + 动词 ing',
          meaning: '我一直反复做某事',
          example: 'I keep running back to the same old place.',
          note: '适合表达反复发生的动作或情绪。',
        ),
      ],
      LearningStage.news => const [
        GrammarPoint(
          pattern: 'aim to + 动词原形',
          meaning: '旨在做某事',
          example: 'The plan aims to reduce commute times.',
          note: '新闻稿中解释目的很常见。',
        ),
        GrammarPoint(
          pattern: 'but some said...',
          meaning: '转折并补充不同观点',
          example: 'Some said the city should also improve weekend service.',
          note: '训练新闻里的多方意见。',
        ),
      ],
      LearningStage.reading => const [
        GrammarPoint(
          pattern: 'less about A and more about B',
          meaning: '与其说是 A，不如说是 B',
          example:
              'Fluency is less about knowing rare words and more about using familiar words naturally.',
          note: '报刊观点里很适合表达判断和取舍。',
        ),
        GrammarPoint(
          pattern: 'A learner who... often...',
          meaning: '用 who 引导从句补充说明对象',
          example:
              'A learner who can explain simple ideas often communicates better.',
          note: '长句拆分时先找主干，再看 who 补充谁。',
        ),
      ],
    };
  }
}
