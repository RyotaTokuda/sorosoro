import SwiftUI

struct ItemListView: View {
    let mode: Mode
    @Environment(ItemStore.self) private var itemStore
    @Environment(PlanService.self) private var planService
    @Environment(SettingsStore.self) private var settingsStore
    @State private var showingAddSheet = false
    @State private var showingTemplatePicker = false
    @State private var showingPaywall = false

    private var items: [Item] {
        itemStore.items(for: mode)
    }

    private var isFreeInactiveMode: Bool {
        !planService.canUseAllModes() && mode != settingsStore.settings.selectedMode
    }

    var body: some View {
        List {
            // 無料プランで非アクティブモードを表示中のインジケーター
            if isFreeInactiveMode {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.blue)
                    Text("タブをタップしてこのモードに切り替えられます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color(.systemGray6))
            }
            if items.isEmpty {
                ContentUnavailableView {
                    Label("アイテムがありません", systemImage: "tray")
                } description: {
                    Text("テンプレートから追加するか、新規作成してください")
                }
            } else {
                ForEach(items) { item in
                    NavigationLink(destination: ItemDetailView(itemId: item.id)) {
                        ItemRowView(item: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
        .navigationTitle(mode.displayName)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        if planService.canAddItem(currentCount: itemStore.itemCount(for: mode)) {
                            showingAddSheet = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Label("新規作成", systemImage: "plus")
                    }
                    Button {
                        if planService.canAddItem(currentCount: itemStore.itemCount(for: mode)) {
                            showingTemplatePicker = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Label("テンプレートから追加", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                ItemFormView(mode: mode)
            }
        }
        .sheet(isPresented: $showingTemplatePicker) {
            NavigationStack {
                TemplatePickerView(mode: mode)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            NotificationService.cancelNotification(for: item.id)
            itemStore.deleteItem(id: item.id)
        }
    }
}

// MARK: - Row

struct ItemRowView: View {
    let item: Item

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text("周期: \(item.cycleDays)日")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                statusBadge
                Text(item.nextDueDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.status {
        case .overdue:
            Text("\(abs(item.daysRemaining))日超過")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.red.opacity(0.15))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        case .soon:
            Text("あと\(item.daysRemaining)日")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.orange.opacity(0.15))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        case .ok:
            Text("あと\(item.daysRemaining)日")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.green.opacity(0.1))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        }
    }
}
