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

    private var cycleDayOptions: [Int] {
        let standard = [7, 14, 21, 30, 45, 60, 90, 120, 180, 270, 365, 545, 730, 1095]
        if standard.contains(cycleDays) { return standard }
        return (standard + [cycleDays]).sorted()
    }

    private func cycleDaysLabel(_ days: Int) -> String {
        switch days {
        case 7:    return "7日（1週間）"
        case 14:   return "14日（2週間）"
        case 21:   return "21日（3週間）"
        case 30:   return "30日（約1ヶ月）"
        case 45:   return "45日（約1.5ヶ月）"
        case 60:   return "60日（約2ヶ月）"
        case 90:   return "90日（約3ヶ月）"
        case 120:  return "120日（約4ヶ月）"
        case 180:  return "180日（半年）"
        case 270:  return "270日（約9ヶ月）"
        case 365:  return "365日（1年）"
        case 545:  return "545日（約1.5年）"
        case 730:  return "730日（2年）"
        case 1095: return "1095日（3年）"
        default:   return "\(days)日"
        }
    }

    var body: some View {
        Form {
            Section("form.section.basic") {
                TextField("form.name.placeholder", text: $name)

                Picker(String(localized: "form.cycle.label"), selection: $cycleDays) {
                    ForEach(cycleDayOptions, id: \.self) { days in
                        Text(cycleDaysLabel(days)).tag(days)
                    }
                }

                DatePicker(
                    String(localized: "form.last.purchase.date"),
                    selection: $lastPurchaseDate,
                    displayedComponents: .date
                )
            }

            if planService.canUseMemo() {
                Section("form.section.memo") {
                    TextField("form.memo.placeholder", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }
            }

            Section("form.section.notification") {
                Toggle("form.notification.toggle", isOn: $notificationEnabled)
                if notificationEnabled {
                    Stepper(
                        String(localized: "form.notification.days.before \(notificationDaysBefore)"),
                        value: $notificationDaysBefore,
                        in: 1...30
                    )
                }
            }

            Section {
                HStack {
                    Text("form.next.due.date")
                    Spacer()
                    Text(computedNextDueDate, style: .date)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(isEditing ? String(localized: "form.title.edit") : String(localized: "form.title.new"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("common.save") { save() }
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
