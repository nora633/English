import SwiftUI

enum AppTab: Hashable {
    case today
    case library
    case speaking
    case review
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(
                onChooseTheme: { selectedTab = .library },
                onStartSpeaking: { selectedTab = .speaking }
            )
                .tabItem {
                    Label("今日", systemImage: "calendar")
                }
                .tag(AppTab.today)

            ThemeLibraryView()
                .tabItem {
                    Label("素材", systemImage: "sparkles")
                }
                .tag(AppTab.library)

            SpeakingPracticeView(
                onFinish: { selectedTab = .review }
            )
                .tabItem {
                    Label("跟读", systemImage: "mic")
                }
                .tag(AppTab.speaking)

            ReviewView(
                onRestart: { selectedTab = .today }
            )
                .tabItem {
                    Label("复盘", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.review)
        }
        .tint(.teal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
