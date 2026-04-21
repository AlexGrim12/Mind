import SwiftUI
import SwiftData
import UIKit

@main
struct MindApp: App {
    let container: ModelContainer
    @StateObject private var watchService = WatchConnectivityService.shared

    init() {
        Self.configureSystemAppearance()

        do {
            container = try ModelContainer(for:
                MoodEntry.self,
                JournalEntry.self,
                Appointment.self,
                SafetyPlan.self
            )
        } catch {
            fatalError("SwiftData container error: \(error)")
        }
    }

    private static func configureSystemAppearance() {
        let tabBar = UITabBarAppearance()
        tabBar.configureWithTransparentBackground()
        tabBar.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        tabBar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.82)
        tabBar.shadowColor = UIColor.black.withAlphaComponent(0.08)

        let normal = tabBar.stackedLayoutAppearance.normal
        normal.iconColor = UIColor.secondaryLabel
        normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]

        let selected = tabBar.stackedLayoutAppearance.selected
        selected.iconColor = UIColor(named: "AccentBlue") ?? UIColor.systemBlue
        selected.titleTextAttributes = [.foregroundColor: UIColor(named: "AccentBlue") ?? UIColor.systemBlue]

        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar

        let navBar = UINavigationBarAppearance()
        navBar.configureWithTransparentBackground()
        navBar.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        navBar.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.78)
        navBar.shadowColor = .clear
        navBar.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBar.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = navBar
        UINavigationBar.appearance().scrollEdgeAppearance = navBar
        UINavigationBar.appearance().compactAppearance = navBar
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .environment(watchService)
                .task {
                    watchService.setContext(container.mainContext)
                }
        }
    }
}
