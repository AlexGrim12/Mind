import SwiftUI

@main
struct MindWatchApp: App {
    @State private var store = WatchStore()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(store)
        }
    }
}
