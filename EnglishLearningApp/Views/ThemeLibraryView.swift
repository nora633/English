import SwiftUI

struct ThemeLibraryView: View {
    @State private var selectedStage: LearningStage? = nil

    private var filteredThemes: [LearningTheme] {
        SampleData.themes.filter { theme in
            selectedStage == nil || theme.stage == selectedStage
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("阶段", selection: $selectedStage) {
                    Text("全部").tag(LearningStage?.none)
                    ForEach(LearningStage.allCases) { stage in
                        Text(stage.rawValue).tag(LearningStage?.some(stage))
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List(filteredThemes) { theme in
                    NavigationLink {
                        ThemeDetailView(theme: theme)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(theme.title)
                                    .font(.headline)
                                Spacer()
                                Text(theme.kind.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.teal)
                            }
                            Text(theme.stage.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.indigo)
                            Text(theme.sourceHint)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(theme.focus)
                                .font(.body)
                            Text(theme.difficulty)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("素材主题")
        }
    }
}

struct ThemeDetailView: View {
    let theme: LearningTheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                mediaPreview
                contentSection
                practiceSection
            }
            .padding(20)
        }
        .background(AppColors.pageBackground)
        .navigationTitle(theme.title)
    }

    private var mediaPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.largeTitle)
                    .foregroundStyle(.teal)
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.kind.rawValue)
                        .font(.headline)
                    Text(theme.sourceHint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Text(mediaDescription)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: contentTitle, systemImage: "doc.text")
            Text(sampleContent)
                .font(.body)
                .lineSpacing(5)
            Text("原型阶段使用 mock 内容。正式版只展示合法授权、官方预览、用户导入或用户手动粘贴的内容。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "开始学习", systemImage: "play.circle")
            Text("用这个素材生成今天的 15 分钟学习内容。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
            } label: {
                Label("生成今日 15 分钟练习", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)

            Button {
            } label: {
                Label("收藏素材", systemImage: "bookmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .cardStyle()
    }

    private var iconName: String {
        switch theme.kind {
        case .sitcom: "play.rectangle"
        case .song: "music.note"
        case .dailyLife: "message"
        case .news: "newspaper"
        case .article: "doc.richtext"
        }
    }

    private var mediaDescription: String {
        switch theme.kind {
        case .sitcom:
            "这里会展示情景剧短片段或官方预览，配合台词短摘录做精听。"
        case .song:
            "这里会展示歌曲信息和合法短歌词片段，用来练连读、弱读和情绪表达。"
        case .dailyLife:
            "这里会展示 AI 生成的生活场景图文对话。"
        case .news:
            "这里会展示短新闻正文或官方来源链接，适合练主旨和细节。"
        case .article:
            "这里会展示报刊文章摘录，适合练长句、正式词汇和观点表达。"
        }
    }

    private var contentTitle: String {
        switch theme.kind {
        case .sitcom: "片段台词"
        case .song: "歌词摘录"
        case .dailyLife: "图文对话"
        case .news: "新闻稿"
        case .article: "文章摘录"
        }
    }

    private var sampleContent: String {
        switch theme.kind {
        case .sitcom:
            "A: I was about to grab some coffee. Do you want anything?\nB: That makes sense. I could use one too.\nA: Do you want me to text you when I get there?"
        case .song:
            "A short chorus-style excerpt will appear here, focused on rhythm, connected speech, and everyday emotional phrases."
        case .dailyLife:
            "You run into a neighbor downstairs. You are about to buy coffee and offer to bring something back."
        case .news:
            "City officials announced a new public transport plan on Monday. The plan aims to reduce commute times and improve service during rush hour."
        case .article:
            "For many learners, fluency is less about knowing rare words and more about using familiar words quickly, accurately, and naturally."
        }
    }
}
