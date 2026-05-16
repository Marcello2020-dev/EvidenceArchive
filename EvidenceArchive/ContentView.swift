import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CaseListView()
                .tabItem {
                    Label("Cases", systemImage: "folder")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .background(EvidenceTheme.screenBackground.ignoresSafeArea())
        .toolbarBackground(EvidenceTheme.screenBackground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    ContentView()
}
