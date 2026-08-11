import SwiftUI

/// Three tabs, no nesting. The audience skews 45+ (CLAUDE.md section 1), so
/// navigation stays as flat and predictable as the platform allows.
public struct MainTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            LevelListView()
                .tabItem { Label("tab.train", systemImage: "figure.cooldown") }

            ProgressDashboardView()
                .tabItem { Label("tab.progress", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("tab.settings", systemImage: "gearshape.fill") }
        }
    }
}

/// Chooses between onboarding and the app itself, and holds the one-time load.
public struct AppRootView: View {
    @Environment(AppModel.self) private var model

    public init() {}

    public var body: some View {
        Group {
            if !model.preferences.isLoaded {
                ProgressView()
            } else if model.preferences.preferences.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .task { await model.load() }
    }
}
