import SwiftUI

struct ThemeLibraryView: View {
    @State private var selectedKind: ContentKind? = nil
    @State private var selectedStage: LearningStage? = nil

    private var filteredThemes: [LearningTheme] {
        SampleData.themes.filter { theme in
            let matchesKind = selectedKind == nil || theme.kind == selectedKind
            let matchesStage = selectedStage == nil || theme.stage == selectedStage
            return matchesKind && matchesStage
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Picker("阶段", selection: $selectedStage) {
                        Text("全部").tag(LearningStage?.none)
                        ForEach(LearningStage.allCases) { stage in
                            Text(stage.rawValue).tag(LearningStage?.some(stage))
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("类型", selection: $selectedKind) {
                        Text("全部").tag(ContentKind?.none)
                        ForEach(ContentKind.allCases) { kind in
                            Text(kind.rawValue).tag(ContentKind?.some(kind))
                        }
                    }
                    .pickerStyle(.menu)
                }
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
                .listStyle(.plain)
            }
            .navigationTitle("素材主题")
        }
    }
}
