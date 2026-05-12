import SwiftUI
import WidgetKit

// MARK: - Color helpers

private extension Item {
    var statusColor: Color {
        switch status {
        case .overdue: .red
        case .soon:    .orange
        case .ok:      .green
        }
    }

    var statusLabel: String {
        switch status {
        case .overdue: "期限切れ"
        case .soon:    "もうすぐ"
        case .ok:      "OK"
        }
    }

    var daysText: String {
        let d = abs(daysRemaining)
        if status == .overdue { return "\(d)日超過" }
        if daysRemaining == 0 { return "今日" }
        return "あと\(daysRemaining)日"
    }
}

// MARK: - Small

struct SmallWidgetView: View {
    let entry: SorosoroEntry

    var body: some View {
        if let item = entry.urgentItems.first {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "cart.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Spacer()
                    Text(item.statusLabel)
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(item.statusColor)
                }

                Spacer()

                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(item.daysText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(intent: PurchaseItemIntent(itemId: item.id)) {
                    Label("買った！", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        } else {
            emptyView
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
            Text("買うものなし")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium

struct MediumWidgetView: View {
    let entry: SorosoroEntry

    var body: some View {
        let items = Array(entry.urgentItems.prefix(3))

        if items.isEmpty {
            emptyView
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "cart.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text("買い替え時リスト")
                        .font(.caption)
                        .bold()
                    Spacer()
                }
                .padding(.bottom, 2)

                ForEach(items) { item in
                    mediumRow(item)
                }

                Spacer()
            }
            .padding(12)
        }
    }

    private func mediumRow(_ item: Item) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(item.statusColor)
                .frame(width: 8, height: 8)

            Text(item.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            Text(item.daysText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(intent: PurchaseItemIntent(itemId: item.id)) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.body)
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(.green)
            Text("買うものはありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Large

struct LargeWidgetView: View {
    let entry: SorosoroEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundStyle(.blue)
                Text("買い替え時リスト")
                    .font(.subheadline)
                    .bold()
                Spacer()
            }
            .padding(.bottom, 8)

            // Urgent items section
            if entry.urgentItems.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text("急ぎのものはありません")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(Array(entry.urgentItems.prefix(5))) { item in
                    largeUrgentRow(item)
                    Divider()
                }
            }

            Spacer()

            // Recent purchases section
            if !entry.recentPurchases.isEmpty {
                Text("最近の購入")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                ForEach(Array(entry.recentPurchases.prefix(3))) { item in
                    largeHistoryRow(item)
                }
            }
        }
        .padding(14)
    }

    private func largeUrgentRow(_ item: Item) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(item.statusColor)
                .frame(width: 8, height: 8)

            Text(item.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            Text(item.daysText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(intent: PurchaseItemIntent(itemId: item.id)) {
                Label("買った！", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 5)
    }

    private func largeHistoryRow(_ item: Item) -> some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(item.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text(item.lastPurchaseDate, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Lock Screen (Accessory Circular)

struct AccessoryWidgetView: View {
    let entry: SorosoroEntry

    private var overdueCount: Int {
        entry.urgentItems.filter { $0.status == .overdue }.count
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "cart.fill")
                    .font(.caption)
                Text("\(overdueCount)")
                    .font(.title3)
                    .bold()
                    .minimumScaleFactor(0.6)
            }
        }
    }
}
