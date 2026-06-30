import SwiftUI

struct ReviewView: View {
    private let lesson = SampleData.todayLesson
    private let review = SampleData.review
    var onRestart: () -> Void = {}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    progressHeader
                    recommendationCard
                    expressionCard
                    chunkReview
                    nextStepCard
                }
                .padding(20)
            }
            .background(AppColors.pageBackground)
            .navigationTitle("学习复盘")
        }
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "明日推荐", systemImage: "sparkles")

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(review.recommendation.title)
                        .font(.title3.weight(.bold))
                    Text("\(review.recommendation.stage.rawValue) · \(review.recommendation.difficulty)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.teal)
                }
                Spacer()
                Text("推荐")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.indigo)
                    .clipShape(Capsule())
            }

            Text(review.recommendation.reason)
                .font(.body)

            VStack(alignment: .leading, spacing: 8) {
                Label(review.recommendation.mix, systemImage: "slider.horizontal.3")
                Label(review.recommendation.weakFocus, systemImage: "target")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            FlowLayout(items: review.recommendation.keywords) { keyword in
                Text(keyword)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.teal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.teal.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .cardStyle()
    }

    private var progressHeader: some View {
        HStack(spacing: 14) {
            MetricTile(title: "连续", value: "\(review.streakDays) 天", color: .teal)
            MetricTile(title: "累计", value: "\(review.completedMinutes) 分钟", color: .indigo)
        }
    }

    private var expressionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "可迁移表达", systemImage: "arrow.triangle.2.circlepath")
            Text(review.reusableExpression)
                .font(.title3.weight(.semibold))
            Text("明天可以替换 coffee 为 lunch、a package、some water，练出真实反应速度。")
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var chunkReview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "今日词块", systemImage: "square.stack.3d.up")
            ForEach(lesson.targetChunks, id: \.self) { chunk in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.teal)
                    Text(chunk)
                        .font(.headline)
                    Spacer()
                }
                .padding(12)
                .background(AppColors.subtleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .cardStyle()
    }

    private var nextStepCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "明日重点", systemImage: "flag")
            Text(review.nextFocus)
                .font(.body)
            Button {
                onRestart()
            } label: {
                Label("完成并回到今日", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
        }
        .cardStyle()
    }
}
