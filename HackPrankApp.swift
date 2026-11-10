import SwiftUI

@main
struct HackPrankApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            FileManagerView()
                .tabItem { Label("Dosyalar", systemImage: "folder.fill") }
            ContentView()
                .tabItem { Label("Jailbreak", systemImage: "lock.open.fill") }
            ToolsView()
                .tabItem { Label("Tools", systemImage: "terminal.fill") }
        }
        .accentColor(.blue)
        .preferredColorScheme(.dark)
        .statusBar(hidden: true)
    }
}
