import SwiftUI

struct ThemeLibraryView: View {
    @State private var selectedKind: ContentKind? = nil

    private var filteredThemes: [LearningTheme] {
        guard let selectedKind else { return SampleData.themes }
        return SampleData.themes.filter { $0.kind == selectedKind }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("类型", selection: $selectedKind) {
                    Text("全部").tag(ContentKind?.none)
                    ForEach(ContentKind.allCases) { kind in
                        Text(kind.rawValue).tag(ContentKind?.some(kind))
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List(filteredThemes) { theme in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(theme.title)
                                .font(.headline)
                            Spacer()
                            Text(theme.kind.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.teal)
                        }
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
                .listStyle(.plain)
            }
            .navigationTitle("素材主题")
        }
    }
}
