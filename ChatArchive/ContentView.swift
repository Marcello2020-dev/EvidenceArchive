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
    }
}

#Preview {
    ContentView()
}
