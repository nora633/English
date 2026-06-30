import Foundation

enum SampleData {
    static let themes: [LearningTheme] = [
        LearningTheme(
            title: "邻里寒暄",
            stage: .daily,
            kind: .sitcom,
            sourceHint: "The Neighborhood 风格",
            focus: "自然开场、接话、轻松回应",
            difficulty: "A2-B1"
        ),
        LearningTheme(
            title: "家庭晚餐小插曲",
            stage: .media,
            kind: .sitcom,
            sourceHint: "Young Sheldon 风格",
            focus: "解释原因、表达惊讶、补充细节",
            difficulty: "B1"
        ),
        LearningTheme(
            title: "热门英文歌副歌表达",
            stage: .media,
            kind: .song,
            sourceHint: "流行歌主题",
            focus: "情绪表达、连读、弱读",
            difficulty: "A2-B1"
        ),
        LearningTheme(
            title: "咖啡店偶遇",
            stage: .daily,
            kind: .dailyLife,
            sourceHint: "AI 生成生活场景",
            focus: "点单、寒暄、临时邀约",
            difficulty: "A2"
        ),
        LearningTheme(
            title: "短新闻听读",
            stage: .news,
            kind: .news,
            sourceHint: "慢速新闻风格",
            focus: "抓主旨、数字、转折和因果",
            difficulty: "B1-B2"
        ),
        LearningTheme(
            title: "报刊观点精读",
            stage: .reading,
            kind: .article,
            sourceHint: "报纸/杂志评论风格",
            focus: "长句结构、观点表达、正式词汇",
            difficulty: "B2-C1"
        )
    ]

    static let todayLesson = DailyLesson(
        title: "今日 15 分钟听说训练",
        durationMinutes: 15,
        completedMinutes: 0,
        theme: themes[0],
        keyWords: [
            KeyWord(
                word: "grab",
                meaning: "顺手买 / 拿 / 吃点",
                usage: "比 buy 更生活化，适合咖啡、午饭、东西",
                example: "I was about to grab some coffee.",
                priority: "必练"
            ),
            KeyWord(
                word: "about to",
                meaning: "正准备要做某事",
                usage: "表达马上要发生的动作，日常口语高频",
                example: "I was about to head downstairs.",
                priority: "必练"
            ),
            KeyWord(
                word: "anything",
                meaning: "任何东西 / 要带什么吗",
                usage: "寒暄和顺手帮忙时很自然",
                example: "Do you want anything?",
                priority: "听写"
            ),
            KeyWord(
                word: "text",
                meaning: "发短信 / 发消息",
                usage: "日常安排、到达提醒、临时沟通",
                example: "I can text you when I get there.",
                priority: "复用"
            )
        ],
        grammarPoints: [
            GrammarPoint(
                pattern: "I was about to + 动词原形",
                meaning: "我正准备做某事",
                example: "I was about to grab some coffee.",
                note: "适合解释自己马上要做的动作，比 I will 更有现场感。"
            ),
            GrammarPoint(
                pattern: "Do you want me to + 动词原形?",
                meaning: "你要我帮你做某事吗？",
                example: "Do you want me to text you when I get there?",
                note: "日常帮忙、顺手询问时很自然。"
            ),
            GrammarPoint(
                pattern: "when + 主语 + 动词",
                meaning: "当某事发生时",
                example: "I can text you when I get there.",
                note: "口语里常用来说明时间条件。"
            )
        ],
        targetChunks: [
            "I was about to...",
            "That makes sense.",
            "Do you want me to...?"
        ],
        listeningLines: [
            "I was about to grab some coffee. Do you want anything?",
            "That makes sense. I would probably do the same thing.",
            "Do you want me to text you when I get there?",
            "I did not mean to interrupt. I just wanted to check in.",
            "Let me know if you need anything from downstairs."
        ],
        speakingPrompt: "用今天的 3 个词块，复述一个你下楼买咖啡时遇到邻居的场景。"
    )

    static let speakingScore = SpeakingScore(
        clarity: 82,
        fluency: 76,
        completeness: 88,
        naturalness: 73,
        transcript: "I was about to get coffee and my neighbor asked me about the meeting. I said that makes sense and I can text her when I get there.",
        suggestions: [
            "把 I can text her 改成 I can text you，情景对话里更自然。",
            "about to 后面直接接动词原形，保持 I was about to get coffee。",
            "复述时可以补一句 Do you want me to grab one for you? 来增加互动感。"
        ]
    )

    static let review = ReviewSummary(
        streakDays: 3,
        completedMinutes: 45,
        reusableExpression: "I was about to grab some coffee. Do you want anything?",
        nextFocus: "明天重点练连读：want me to / text you when"
    )
}
