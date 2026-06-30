import SwiftUI

struct TodayView: View {
    private let lesson = SampleData.todayLesson
    var onChooseTheme: () -> Void = {}
    var onStartSpeaking: () -> Void = {}

    private var isCompleted: Bool {
        lesson.completedMinutes >= lesson.durationMinutes
    }

    private var progress: Double {
        min(Double(lesson.completedMinutes) / Double(lesson.durationMinutes), 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    listeningSection
                    keyWordsSection
                    grammarSection
                    chunkSection
                }
                .padding(20)
            }
            .background(AppColors.pageBackground)
            .navigationTitle("今日学习")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(lesson.durationMinutes) 分钟", systemImage: "clock")
                Spacer()
                Text(isCompleted ? "已完成" : "未完成")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((isCompleted ? Color.green : Color.white).opacity(0.22))
                    .clipShape(Capsule())
            }
            .font(.subheadline)

            Text(lesson.title)
                .font(.largeTitle.bold())

            Text("\(lesson.theme.title) · \(lesson.theme.sourceHint)")
                .font(.headline)

            Text(lesson.theme.focus)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

            ProgressView(value: progress)
                .tint(.white)
                .padding(.top, 4)

            HStack {
                Text("完成进度 \(lesson.completedMinutes)/\(lesson.durationMinutes) 分钟")
                Spacer()
                Text(lesson.theme.difficulty)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.86))
        }
        .foregroundStyle(.white)
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.teal, Color.indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var listeningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "精听句子", systemImage: "headphones")
            ForEach(Array(lesson.listeningLines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.indigo)
                        .clipShape(Circle())
                    Text(line)
                        .font(.body)
                }
            }
            Button {
                onStartSpeaking()
            } label: {
                Label("去跟读练习", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .padding(.top, 4)
        }
        .cardStyle()
    }

    private var keyWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(title: "今日关键单词", systemImage: "character.book.closed")
                Spacer()
                Button {
                    onChooseTheme()
                } label: {
                    Label("换主题", systemImage: "sparkles")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
            }

            Text("今天 15 分钟重点把这些词练到能听出来、写出来、说出来。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(lesson.keyWords) { item in
                KeyWordRow(item: item)
            }
        }
        .cardStyle()
    }

    private var grammarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "日常语法结构", systemImage: "textformat.abc")
            Text("不背抽象规则，只练今天句子里会马上用到的结构。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(lesson.grammarPoints) { point in
                GrammarPointRow(point: point)
            }
        }
        .cardStyle()
    }

    private var chunkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "今日词块", systemImage: "text.quote")
            ForEach(lesson.targetChunks, id: \.self) { chunk in
                Text(chunk)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.teal.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .cardStyle()
    }
}
