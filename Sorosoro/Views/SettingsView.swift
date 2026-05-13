import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(PlanService.self) private var planService
    @Environment(UserProfileStore.self) private var profileStore
    @State private var showingPaywall = false

    var body: some View {
        List {
            Section("settings.section.plan") {
                HStack {
                    Text("settings.current.plan")
                    Spacer()
                    Text(planService.isPro ? "Plus" : String(localized: "settings.plan.free"))
                        .foregroundStyle(planService.isPro ? .green : .secondary)
                }
                if !planService.isPro {
                    Button {
                        showingPaywall = true
                    } label: {
                        Label("settings.upgrade", systemImage: "star.fill")
                    }
                }
            }

            if !planService.canUseAllModes() {
                Section("settings.section.active.mode") {
                    Picker(String(localized: "settings.mode.picker.label"), selection: Binding(
                        get: { settingsStore.settings.selectedMode },
                        set: { settingsStore.setSelectedMode($0) }
                    )) {
                        ForEach(profileStore.profile.visibleModes) { mode in
                            Label(mode.displayName, systemImage: mode.iconName)
                                .tag(mode)
                        }
                    }
                }
            }

            Section("settings.section.visible.tabs") {
                ForEach(Mode.allCases) { mode in
                    let isVisible = profileStore.profile.visibleModes.contains(mode)
                    Button {
                        toggleMode(mode, current: profileStore.profile.visibleModes)
                    } label: {
                        HStack {
                            Label(mode.displayName, systemImage: mode.iconName)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: isVisible ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isVisible ? .blue : .secondary)
                        }
                    }
                }
            }

            if profileStore.profile.visibleModes.contains(.daily) {
                Section("settings.section.family") {
                    Stepper(
                        String(localized: "settings.adults.count \(profileStore.profile.adultsCount)"),
                        value: Binding(
                            get: { profileStore.profile.adultsCount },
                            set: { profileStore.setAdultsCount($0) }
                        ),
                        in: 1...6
                    )
                    Stepper(
                        String(localized: "settings.children.count \(profileStore.profile.childrenCount)"),
                        value: Binding(
                            get: { profileStore.profile.childrenCount },
                            set: { profileStore.setChildrenCount($0) }
                        ),
                        in: 0...6
                    )
                    Text("settings.family.hint")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if profileStore.profile.visibleModes.contains(.car) {
                Section("settings.section.car") {
                    Picker(String(localized: "settings.monthly.mileage"), selection: Binding(
                        get: { profileStore.profile.monthlyMileage },
                        set: { profileStore.setMonthlyMileage($0) }
                    )) {
                        ForEach(MonthlyMileage.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    Picker(String(localized: "settings.vehicle.type"), selection: Binding(
                        get: { profileStore.profile.vehicleType },
                        set: { profileStore.setVehicleType($0) }
                    )) {
                        ForEach(VehicleType.allCases) { v in
                            Text(v.displayName).tag(v)
                        }
                    }
                }
            }

            Section("settings.section.notification") {
                Toggle("settings.notification.global.toggle", isOn: Binding(
                    get: { settingsStore.settings.globalNotificationEnabled },
                    set: { newValue in
                        if newValue {
                            Task { _ = await NotificationService.requestPermission() }
                        }
                        settingsStore.setGlobalNotification(newValue)
                    }
                ))

                Stepper(
                    String(localized: "settings.notification.default \(settingsStore.settings.defaultNotificationDaysBefore)"),
                    value: Binding(
                        get: { settingsStore.settings.defaultNotificationDaysBefore },
                        set: { settingsStore.setDefaultNotificationDays($0) }
                    ),
                    in: 1...30
                )
            }

            Section("settings.section.sharing") {
                ShareButton()
            }

            Section("settings.section.app.info") {
                HStack {
                    Text("settings.version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
                Button("settings.restore.purchases") {
                    Task { await planService.restorePurchases() }
                }
                Link(destination: URL(string: "https://mankai-software.vercel.app/tokushoho")!) {
                    HStack {
                        Label("settings.tokushoho", systemImage: "scroll")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

        }
        .navigationTitle("tab.settings")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func toggleMode(_ mode: Mode, current: [Mode]) {
        var modes = Set(current)
        if modes.contains(mode) {
            guard modes.count > 1 else { return }
            modes.remove(mode)
        } else {
            modes.insert(mode)
        }
        profileStore.setVisibleModes(Array(modes))
    }

}
