import Foundation

enum ContentKind: String, CaseIterable, Identifiable {
    case sitcom = "情景剧"
    case song = "英文歌"
    case dailyLife = "生活场景"

    var id: String { rawValue }
}

struct LearningTheme: Identifiable {
    let id = UUID()
    let title: String
    let kind: ContentKind
    let sourceHint: String
    let focus: String
    let difficulty: String
}

struct DailyLesson {
    let title: String
    let durationMinutes: Int
    let theme: LearningTheme
    let targetChunks: [String]
    let listeningLines: [String]
    let speakingPrompt: String
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

