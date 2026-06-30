import Foundation

enum ContentKind: String, CaseIterable, Identifiable {
    case sitcom = "情景剧"
    case song = "英文歌"
    case dailyLife = "生活场景"
    case news = "新闻稿"
    case article = "报刊读物"

    var id: String { rawValue }
}

enum LearningStage: String, CaseIterable, Identifiable {
    case daily = "日常表达"
    case media = "影视歌曲"
    case news = "新闻听读"
    case reading = "报刊精读"

    var id: String { rawValue }
}

struct LearningTheme: Identifiable {
    let id = UUID()
    let title: String
    let stage: LearningStage
    let kind: ContentKind
    let sourceHint: String
    let focus: String
    let difficulty: String
}

struct DailyLesson {
    let title: String
    let durationMinutes: Int
    let completedMinutes: Int
    let theme: LearningTheme
    let keyWords: [KeyWord]
    let grammarPoints: [GrammarPoint]
    let targetChunks: [String]
    let listeningLines: [String]
    let speakingPrompt: String
}

struct KeyWord: Identifiable {
    let id = UUID()
    let word: String
    let meaning: String
    let usage: String
    let example: String
    let priority: String
}

struct GrammarPoint: Identifiable {
    let id = UUID()
    let pattern: String
    let meaning: String
    let example: String
    let note: String
}

struct SpeakingScore {
    let clarity: Int
    let fluency: Int
    let completeness: Int
    let naturalness: Int
    let transcript: String
    let suggestions: [String]
}

struct ReviewSummary {
    let streakDays: Int
    let completedMinutes: Int
    let reusableExpression: String
    let nextFocus: String
}
