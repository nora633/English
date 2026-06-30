import SwiftUI

enum AppColors {
    static let pageBackground = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let cardBackground = Color.white
    static let subtleBackground = Color(red: 0.93, green: 0.96, blue: 0.96)
}

struct SectionTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

struct KeyWordRow: View {
    let item: KeyWord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.word)
                    .font(.title3.weight(.bold))
                Spacer()
                Text(item.priority)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.teal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.teal.opacity(0.12))
                    .clipShape(Capsule())
            }
            Text(item.meaning)
                .font(.headline)
            Text(item.usage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(item.example)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.indigo)
                .padding(.top, 2)
        }
        .padding(14)
        .background(AppColors.subtleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct GrammarPointRow: View {
    let point: GrammarPoint

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(point.pattern)
                .font(.headline)
            Text(point.meaning)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.teal)
            Text(point.example)
                .font(.body)
            Text(point.note)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(AppColors.subtleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct WritingFeedback: View {
    let title: String
    let reference: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(reference)
                .font(.body.weight(.semibold))
            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(AppColors.subtleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ScoreBar: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(value)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(value), total: 100)
                .tint(value >= 80 ? .teal : .orange)
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
    }
}
