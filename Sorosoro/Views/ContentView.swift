import SwiftUI

struct ContentView: View {
    @Environment(PlanService.self) private var planService
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(UserProfileStore.self) private var profileStore
    @State private var selectedTab: Tab = .mode(.daily)

    enum Tab: Hashable {
        case mode(Mode)
        case shopping
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(profileStore.profile.visibleModes.filter { Mode.allCases.contains($0) }) { mode in
                NavigationStack {
                    ItemListView(mode: mode)
                }
                .tabItem {
                    Label(mode.displayName, systemImage: mode.iconName)
                }
                .tag(Tab.mode(mode))
            }

            NavigationStack {
                ShoppingListView()
            }
            .tabItem {
                Label("買い物リスト", systemImage: "cart.fill")
            }
            .tag(Tab.shopping)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
        .onChange(of: selectedTab) { _, newTab in
            guard !planService.canUseAllModes(),
                  case .mode(let tappedMode) = newTab,
                  tappedMode != settingsStore.settings.selectedMode else { return }
            settingsStore.setSelectedMode(tappedMode)
        }
        .onChange(of: profileStore.profile.visibleModes) { _, modes in
            // If current tab's mode is no longer visible, switch to first visible mode
            if case .mode(let current) = selectedTab, !modes.contains(current) {
                selectedTab = .mode(modes.first ?? .daily)
            }
        }
        .fullScreenCover(isPresented: .constant(!profileStore.profile.hasCompletedOnboarding)) {
            OnboardingView()
                .environment(profileStore)
        }
    }
}
