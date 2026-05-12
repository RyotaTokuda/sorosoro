import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SorosoroEntry: TimelineEntry {
    let date: Date
    let urgentItems: [Item]
    let recentPurchases: [Item]
}

// MARK: - Timeline Provider

struct SorosoroTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SorosoroEntry {
        SorosoroEntry(date: Date(), urgentItems: [], recentPurchases: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SorosoroEntry) -> Void) {
        let items = WidgetDataProvider.loadItems()
        completion(makeEntry(from: items))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SorosoroEntry>) -> Void) {
        let items = WidgetDataProvider.loadItems()
        let entry = makeEntry(from: items)
        // 1時間ごとに更新
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry(from items: [Item]) -> SorosoroEntry {
        SorosoroEntry(
            date: Date(),
            urgentItems: WidgetDataProvider.urgentItems(from: items, limit: 5),
            recentPurchases: WidgetDataProvider.recentPurchases(from: items, limit: 3)
        )
    }
}

// MARK: - Widget Definitions

struct SorosoroWidget: Widget {
    let kind = "SorosoroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SorosoroTimelineProvider()) { entry in
            SorosoroWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("そろそろ")
        .description("もうすぐ買い替え時のアイテムを表示します。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct SorosoroLockScreenWidget: Widget {
    let kind = "SorosoroLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SorosoroTimelineProvider()) { entry in
            AccessoryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("そろそろ（ロック画面）")
        .description("期限切れのアイテム数を表示します。")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Entry View Router

struct SorosoroWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SorosoroEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Bundle

@main
struct SorosoroWidgetBundle: WidgetBundle {
    var body: some Widget {
        SorosoroWidget()
        SorosoroLockScreenWidget()
    }
}
