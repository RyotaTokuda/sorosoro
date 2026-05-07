import SwiftUI

struct ItemFormView: View {
    let mode: Mode
    var editingItem: Item?
    var presetTemplate: ItemTemplate?

    @Environment(ItemStore.self) private var itemStore
    @Environment(PlanService.self) private var planService
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var cycleDays: Int = 30
    @State private var lastPurchaseDate: Date = Date()
    @State private var memo: String = ""
    @State private var notificationEnabled: Bool = true
    @State private var notificationDaysBefore: Int = 3

    private var isEditing: Bool { editingItem != nil }

    var body: some View {
        Form {
            Section("基本情報") {
                TextField("アイテム名", text: $name)

                Stepper("交換周期: \(cycleDays)日", value: $cycleDays, in: 1...9999)

                DatePicker(
                    "前回購入日",
                    selection: $lastPurchaseDate,
                    displayedComponents: .date
                )
            }

            if planService.canUseMemo() {
                Section("メモ") {
                    TextField("メモ（任意）", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }
            }

            Section("通知") {
                Toggle("通知する", isOn: $notificationEnabled)
                if notificationEnabled {
                    Stepper(
                        "\(notificationDaysBefore)日前に通知",
                        value: $notificationDaysBefore,
                        in: 1...30
                    )
                }
            }

            // 次回予定日プレビュー
            Section {
                HStack {
                    Text("次回予定日")
                    Spacer()
                    Text(computedNextDueDate, style: .date)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(isEditing ? "アイテム編集" : "新規アイテム")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let item = editingItem {
                name = item.name
                cycleDays = item.cycleDays
                lastPurchaseDate = item.lastPurchaseDate
                memo = item.memo
                notificationEnabled = item.notificationEnabled
                notificationDaysBefore = item.notificationDaysBefore
            } else if let template = presetTemplate {
                name = template.name
                cycleDays = template.cycleDays
                notificationDaysBefore = template.notificationDaysBefore
            } else {
                notificationDaysBefore = settingsStore.settings.defaultNotificationDaysBefore
            }
        }
    }

    private var computedNextDueDate: Date {
        Calendar.current.date(byAdding: .day, value: cycleDays, to: lastPurchaseDate) ?? lastPurchaseDate
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if var item = editingItem {
            item.name = trimmedName
            item.cycleDays = cycleDays
            item.lastPurchaseDate = lastPurchaseDate
            item.nextDueDate = computedNextDueDate
            item.memo = memo
            item.notificationEnabled = notificationEnabled
            item.notificationDaysBefore = notificationDaysBefore
            itemStore.updateItem(item)
            NotificationService.scheduleNotification(for: item)
        } else {
            let item = Item(
                name: trimmedName,
                mode: mode,
                cycleDays: cycleDays,
                lastPurchaseDate: lastPurchaseDate,
                memo: memo,
                notificationEnabled: notificationEnabled,
                notificationDaysBefore: notificationDaysBefore
            )
            itemStore.addItem(item)
            if notificationEnabled {
                Task {
                    _ = await NotificationService.requestPermission()
                    NotificationService.scheduleNotification(for: item)
                }
            }
        }

        dismiss()
    }
}
