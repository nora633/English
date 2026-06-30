import SwiftUI

struct TodayView: View {
    private let lesson = SampleData.todayLesson
    var onChooseTheme: () -> Void = {}
    var onStartSpeaking: () -> Void = {}

    @State private var completedStepCount = 0
    @State private var dictationAnswer = ""
    @State private var recallAnswer = ""
    @State private var showsWritingAnswers = false

    private let steps = [
        FlowStep(minutes: "2", title: "选择主题", detail: "确认今天练邻里寒暄"),
        FlowStep(minutes: "3", title: "精听短句", detail: "抓住弱读和连读"),
        FlowStep(minutes: "3", title: "听写默写", detail: "听一句写一句，再凭记忆默写"),
        FlowStep(minutes: "4", title: "影子跟读", detail: "录音并获得转写"),
        FlowStep(minutes: "2", title: "情景复述", detail: "复用当天表达"),
        FlowStep(minutes: "1", title: "保存复盘", detail: "留下明天要练的点")
    ]

    private var progress: Double {
        Double(completedStepCount) / Double(steps.count)
    }

    private var primaryActionTitle: String {
        if completedStepCount == 0 { return "确认主题" }
        if completedStepCount < 2 { return "完成本步" }
        return "开始跟读"
    }

    private var primaryActionIcon: String {
        if completedStepCount < 2 { return "checkmark" }
        return "mic.fill"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    taskTimeline
                    chunkSection
                    listeningSection
                    writingSection
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

            ProgressView(value: progress)
                .tint(.white)
                .padding(.top, 6)

            Text("已完成 \(completedStepCount)/\(steps.count) 步")
                .font(.caption.weight(.semibold))
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
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                FlowStepRow(
                    step: step,
                    isActive: index == completedStepCount,
                    isCompleted: index < completedStepCount
                )
            }

            HStack {
                Button {
                    onChooseTheme()
                } label: {
                    Label("换个主题", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)

                Button {
                    advanceFlow()
                } label: {
                    Label(primaryActionTitle, systemImage: primaryActionIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
            }
            .padding(.top, 6)
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

    private var writingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "听写 / 默写", systemImage: "pencil.and.list.clipboard")

            Text("听写：听目标句后输入你听到的英文。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("I was about to...", text: $dictationAnswer, axis: .vertical)
                .textFieldStyle(.roundedBorder)

            Text("默写：看中文提示，凭记忆写出自然英文。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("中文提示：我正准备去买杯咖啡。你要带点什么吗？")
                .font(.body.weight(.semibold))
            TextField("Write the sentence from memory", text: $recallAnswer, axis: .vertical)
                .textFieldStyle(.roundedBorder)

            Button {
                showsWritingAnswers.toggle()
            } label: {
                Label(showsWritingAnswers ? "收起答案" : "对照答案", systemImage: "eye")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if showsWritingAnswers {
                VStack(alignment: .leading, spacing: 8) {
                    Text("参考句")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(lesson.listeningLines[0])
                        .font(.body.weight(.semibold))
                    Text("v0.3 会加入相似度评分、漏词提醒和自然表达建议。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(AppColors.subtleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                onStartSpeaking()
            } label: {
                Label("开始跟读", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
        }
        .cardStyle()
    }

    private func advanceFlow() {
        if completedStepCount >= 2 {
            onStartSpeaking()
        } else {
            completedStepCount += 1
        }
    }
}
