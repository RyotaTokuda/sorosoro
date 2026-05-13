import SwiftUI

struct TemplatePickerView: View {
    let mode: Mode
    let existingItems: [Item]

    @Environment(TemplateStore.self) private var templateStore
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ItemTemplate?

    private var existingNames: Set<String> {
        Set(existingItems.map { $0.name.lowercased() })
    }

    private var presetByCategory: [(category: String, templates: [ItemTemplate])] {
        let templates = DefaultTemplates.templates(for: mode)
        let order = categoryOrder(for: mode)
        var dict: [String: [ItemTemplate]] = [:]
        for t in templates {
            let cat = t.category.isEmpty ? "その他" : t.category
            dict[cat, default: []].append(t)
        }
        return order.compactMap { cat in
            guard let items = dict[cat] else { return nil }
            return (category: cat, templates: items)
        }
    }

    private var customTemplates: [ItemTemplate] {
        templateStore.customTemplates(for: mode)
    }

    var body: some View {
        List {
            ForEach(presetByCategory, id: \.category) { group in
                Section(group.category) {
                    ForEach(group.templates) { template in
                        templateRow(template)
                    }
                }
            }

            if !customTemplates.isEmpty {
                Section("template.section.custom") {
                    ForEach(customTemplates) { template in
                        templateRow(template)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            templateStore.deleteCustomTemplate(id: customTemplates[index].id)
                        }
                    }
                }
            }
        }
        .navigationTitle("template.nav.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.close") { dismiss() }
            }
        }
        .sheet(item: $selectedTemplate) { template in
            NavigationStack {
                ItemFormView(mode: mode, presetTemplate: template)
            }
        }
    }

    private func templateRow(_ template: ItemTemplate) -> some View {
        let days = template.adjustedCycleDays(profile: profileStore.profile)
        let isAdjusted = days != template.cycleDays
        let alreadyTracking = existingNames.contains(template.name.lowercased())

        return Button {
            if !alreadyTracking { selectedTemplate = template }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .foregroundStyle(alreadyTracking ? .secondary : .primary)
                    if isAdjusted {
                        Text("template.base.days \(template.cycleDays)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if alreadyTracking {
                    Label("template.already.tracking", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .labelStyle(.titleAndIcon)
                } else {
                    Text("item.detail.days.value \(days)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .disabled(alreadyTracking)
    }

    private func categoryOrder(for mode: Mode) -> [String] {
        switch mode {
        case .daily, .gadget:
            return ["バスルーム", "キッチン", "洗濯・掃除", "家電・フィルター"]
        case .car:
            return ["エンジン・オイル", "ブレーキ", "タイヤ・足回り", "外装・消耗品"]
        case .pet:
            return ["予防・医療", "グルーミング", "食事・日用品"]
        case .health:
            return ["サプリメント", "コンタクト・アイケア", "スキンケア・美容", "常備薬・その他"]
        }
    }
}
