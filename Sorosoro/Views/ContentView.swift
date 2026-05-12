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

    private var visibleTabs: [Tab] {
        var tabs = profileStore.profile.visibleModes
            .filter { Mode.allCases.contains($0) }
            .map { Tab.mode($0) }
        tabs.append(.shopping)
        tabs.append(.settings)
        return tabs
    }

    var body: some View {
        ZStack {
            // Pre-render all tabs to avoid flash on first switch
            ForEach(visibleTabs, id: \.self) { tab in
                NavigationStack {
                    contentView(for: tab)
                }
                .opacity(selectedTab == tab ? 1 : 0)
                .allowsHitTesting(selectedTab == tab)
                .zIndex(selectedTab == tab ? 1 : 0)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .onChange(of: profileStore.profile.visibleModes) { _, modes in
            if case .mode(let current) = selectedTab,
               !modes.filter({ Mode.allCases.contains($0) }).contains(current) {
                selectedTab = .mode(modes.first ?? .daily)
            }
        }
        .fullScreenCover(isPresented: .constant(!profileStore.profile.hasCompletedOnboarding)) {
            OnboardingView()
                .environment(profileStore)
        }
    }

    @ViewBuilder
    private func contentView(for tab: Tab) -> some View {
        switch tab {
        case .mode(let mode): ItemListView(mode: mode)
        case .shopping:       ShoppingListView()
        case .settings:       SettingsView()
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 0) {
                ForEach(visibleTabs, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 8)
            .background(.regularMaterial)
        }
    }

    private func tabButton(for tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            if case .mode(let tappedMode) = tab,
               !planService.canUseAllModes(),
               tappedMode != settingsStore.settings.selectedMode {
                settingsStore.setSelectedMode(tappedMode)
            }
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tabIcon(for: tab))
                    .font(.system(size: 22))
                    .symbolVariant(isSelected ? .fill : .none)
                Text(tabLabel(for: tab))
                    .font(.system(size: 10))
            }
            .foregroundStyle(isSelected ? .blue : Color(UIColor.systemGray))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func tabIcon(for tab: Tab) -> String {
        switch tab {
        case .mode(let m): return m.iconName
        case .shopping: return "cart"
        case .settings: return "gearshape"
        }
    }

    private func tabLabel(for tab: Tab) -> String {
        switch tab {
        case .mode(let m): return m.displayName
        case .shopping: return String(localized: "tab.shopping")
        case .settings: return String(localized: "tab.settings")
        }
    }
}
