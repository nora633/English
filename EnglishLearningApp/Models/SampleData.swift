import Foundation

enum SampleData {
    static let themes: [LearningTheme] = [
        LearningTheme(
            title: "邻里寒暄",
            kind: .sitcom,
            sourceHint: "The Neighborhood 风格",
            focus: "自然开场、接话、轻松回应",
            difficulty: "A2-B1"
        ),
        LearningTheme(
            title: "家庭晚餐小插曲",
            kind: .sitcom,
            sourceHint: "Young Sheldon 风格",
            focus: "解释原因、表达惊讶、补充细节",
            difficulty: "B1"
        ),
        LearningTheme(
            title: "热门英文歌副歌表达",
            kind: .song,
            sourceHint: "流行歌主题",
            focus: "情绪表达、连读、弱读",
            difficulty: "A2-B1"
        ),
        LearningTheme(
            title: "咖啡店偶遇",
            kind: .dailyLife,
            sourceHint: "AI 生成生活场景",
            focus: "点单、寒暄、临时邀约",
            difficulty: "A2"
        )
    ]

    static let todayLesson = DailyLesson(
        title: "今日 15 分钟听说训练",
        durationMinutes: 15,
        theme: themes[0],
        targetChunks: [
            "I was about to...",
            "That makes sense.",
            "Do you want me to...?"
        ],
        listeningLines: [
            "I was about to grab some coffee. Do you want anything?",
            "That makes sense. I would probably do the same thing.",
            "Do you want me to text you when I get there?"
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

