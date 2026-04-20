import SwiftUI

@main
struct MindWatchApp: App {
    @StateObject private var store = WatchStore()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(store)
        }
    }
}
