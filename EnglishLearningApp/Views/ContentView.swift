import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("今日", systemImage: "calendar")
                }

            ThemeLibraryView()
                .tabItem {
                    Label("素材", systemImage: "sparkles")
                }

            SpeakingPracticeView()
                .tabItem {
                    Label("跟读", systemImage: "mic")
                }

            ReviewView()
                .tabItem {
                    Label("复盘", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(.teal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
