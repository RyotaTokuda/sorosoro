import SwiftUI

struct TemplatePickerView: View {
    let mode: Mode
    @Environment(TemplateStore.self) private var templateStore
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ItemTemplate?

    var body: some View {
        List {
            Section("template.section.preset") {
                ForEach(DefaultTemplates.templates(for: mode)) { template in
                    templateRow(template)
                }
            }

            let filterModes: [Mode] = mode == .daily ? [.daily, .gadget] : [mode]
            let custom = templateStore.customTemplates.filter { filterModes.contains($0.mode) }
            if !custom.isEmpty {
                Section("template.section.custom") {
                    ForEach(custom) { template in
                        templateRow(template)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            templateStore.deleteCustomTemplate(id: custom[index].id)
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
        return Button {
            selectedTemplate = template
        } label: {
            HStack {
                Text(template.name)
                    .foregroundStyle(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("item.detail.days.value \(days)")
                        .foregroundStyle(.secondary)
                    if isAdjusted {
                        Text("template.base.days \(template.cycleDays)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
