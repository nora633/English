import SwiftUI

struct TodayView: View {
    private let lesson = SampleData.todayLesson

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    taskTimeline
                    chunkSection
                    listeningSection
                    promptSection
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
                Text(lesson.theme.difficulty)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2))
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

    private var taskTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "15 分钟流程", systemImage: "list.bullet.clipboard")
            TimelineRow(minutes: "2", title: "选择主题", detail: "确认今天练邻里寒暄")
            TimelineRow(minutes: "4", title: "精听短句", detail: "抓住弱读和连读")
            TimelineRow(minutes: "4", title: "影子跟读", detail: "录音并获得转写")
            TimelineRow(minutes: "3", title: "情景复述", detail: "复用当天表达")
            TimelineRow(minutes: "2", title: "保存复盘", detail: "留下明天要练的点")
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
        }
        .cardStyle()
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "口语任务", systemImage: "message")
            Text(lesson.speakingPrompt)
                .font(.body)
            Button {
            } label: {
                Label("开始跟读", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
        }
        .cardStyle()
    }
}
