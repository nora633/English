import SwiftUI

struct SpeakingPracticeView: View {
    private let lesson = SampleData.todayLesson
    private let score = SampleData.speakingScore
    var onFinish: () -> Void = {}

    @State private var hasSavedRecording = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    targetSentence
                    recordingPanel
                    if hasSavedRecording {
                        scorePanel
                        transcriptPanel
                        suggestionsPanel
                        finishPanel
                    }
                }
                .padding(20)
            }
            .background(AppColors.pageBackground)
            .navigationTitle("跟读练习")
        }
    }

    private var targetSentence: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "目标句", systemImage: "scope")
            Text(lesson.listeningLines[0])
                .font(.title3.weight(.semibold))
            Text("重点：about to / grab some coffee / want anything")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var recordingPanel: some View {
        VStack(spacing: 14) {
            Button {
                hasSavedRecording.toggle()
            } label: {
                Image(systemName: hasSavedRecording ? "checkmark.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 72))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .foregroundStyle(hasSavedRecording ? .green : .teal)

            Text(hasSavedRecording ? "已保存一段 mock 录音，下面展示模拟反馈" : "静态原型：点击麦克风或保存录音来模拟完成跟读")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Button {
                } label: {
                    Label("播放原句", systemImage: "play.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    hasSavedRecording = true
                } label: {
                    Label("保存录音", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var scorePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "口语评分", systemImage: "gauge.with.dots.needle.67percent")
            ScoreBar(label: "清晰度", value: score.clarity)
            ScoreBar(label: "流利度", value: score.fluency)
            ScoreBar(label: "完整度", value: score.completeness)
            ScoreBar(label: "自然度", value: score.naturalness)
        }
        .cardStyle()
    }

    private var finishPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "下一步", systemImage: "arrow.right.circle")
            Text("把今天的词块和反馈保存到复盘里，明天继续练同一类表达。")
                .font(.body)
                .foregroundStyle(.secondary)
            Button {
                onFinish()
            } label: {
                Label("进入复盘", systemImage: "chart.line.uptrend.xyaxis")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
        }
        .cardStyle()
    }

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "转写文本", systemImage: "text.bubble")
            Text(score.transcript)
                .font(.body)
        }
        .cardStyle()
    }

    private var suggestionsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "改进建议", systemImage: "wand.and.stars")
            ForEach(score.suggestions, id: \.self) { suggestion in
                Label(suggestion, systemImage: "checkmark.circle")
                    .font(.body)
            }
        }
        .cardStyle()
    }
}
