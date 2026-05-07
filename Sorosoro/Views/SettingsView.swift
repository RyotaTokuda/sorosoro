import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(PlanService.self) private var planService
    @Environment(UserProfileStore.self) private var profileStore
    @State private var showingPaywall = false

    var body: some View {
        List {
            // プランセクション
            Section("プラン") {
                HStack {
                    Text("現在のプラン")
                    Spacer()
                    Text(planService.isPro ? "Plus" : "無料")
                        .foregroundStyle(planService.isPro ? .green : .secondary)
                }
                if !planService.isPro {
                    Button {
                        showingPaywall = true
                    } label: {
                        Label("Plus にアップグレード", systemImage: "star.fill")
                    }
                }
            }

            // モード設定（無料のみ）
            if !planService.canUseAllModes() {
                Section("アクティブモード") {
                    Picker("モード", selection: Binding(
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

            // 表示タブ設定
            Section("表示するタブ") {
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

            // プロフィール設定
            if profileStore.profile.visibleModes.contains(.daily) {
                Section("家族の人数") {
                    Stepper(
                        "大人: \(profileStore.profile.adultsCount)人",
                        value: Binding(
                            get: { profileStore.profile.adultsCount },
                            set: { profileStore.setAdultsCount($0) }
                        ),
                        in: 1...6
                    )
                    Stepper(
                        "子供（中学生以下）: \(profileStore.profile.childrenCount)人",
                        value: Binding(
                            get: { profileStore.profile.childrenCount },
                            set: { profileStore.setChildrenCount($0) }
                        ),
                        in: 0...6
                    )
                    Text("子供は大人の約60%として計算。日用品の補充タイミングに反映されます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if profileStore.profile.visibleModes.contains(.car) {
                Section("車の情報") {
                    Picker("月間走行距離", selection: Binding(
                        get: { profileStore.profile.monthlyMileage },
                        set: { profileStore.setMonthlyMileage($0) }
                    )) {
                        ForEach(MonthlyMileage.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    Picker("車の種類", selection: Binding(
                        get: { profileStore.profile.vehicleType },
                        set: { profileStore.setVehicleType($0) }
                    )) {
                        ForEach(VehicleType.allCases) { v in
                            Text(v.displayName).tag(v)
                        }
                    }
                }
            }

            // 通知設定
            Section("通知") {
                Toggle("通知を有効にする", isOn: Binding(
                    get: { settingsStore.settings.globalNotificationEnabled },
                    set: { newValue in
                        if newValue {
                            Task { _ = await NotificationService.requestPermission() }
                        }
                        settingsStore.setGlobalNotification(newValue)
                    }
                ))

                Stepper(
                    "デフォルト通知: \(settingsStore.settings.defaultNotificationDaysBefore)日前",
                    value: Binding(
                        get: { settingsStore.settings.defaultNotificationDaysBefore },
                        set: { settingsStore.setDefaultNotificationDays($0) }
                    ),
                    in: 1...30
                )
            }

            // 共有
            Section("家族・パートナーと共有") {
                ShareButton()
            }

            // アプリ情報
            Section("アプリ情報") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
                Button("購入の復元") {
                    Task { await planService.restorePurchases() }
                }
            }

        }
        .navigationTitle("設定")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func toggleMode(_ mode: Mode, current: [Mode]) {
        var modes = Set(current)
        if modes.contains(mode) {
            guard modes.count > 1 else { return } // at least one must remain
            modes.remove(mode)
        } else {
            modes.insert(mode)
        }
        profileStore.setVisibleModes(Array(modes))
    }

}
