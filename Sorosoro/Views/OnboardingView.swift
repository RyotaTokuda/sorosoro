import SwiftUI

struct OnboardingView: View {
    @Environment(UserProfileStore.self) private var profileStore

    @State private var selectedModes: Set<Mode> = Set(Mode.allCases)
    @State private var familySize: Int = 2
    @State private var monthlyMileage: MonthlyMileage = .medium
    @State private var vehicleType: VehicleType = .gasoline

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    welcomeHeader

                    modeSection

                    if selectedModes.contains(.daily) {
                        familySizeSection
                    }

                    if selectedModes.contains(.car) {
                        carSection
                    }

                    startButton
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("そろそろへようこそ")
                .font(.largeTitle.bold())
            Text("あなたの生活スタイルを教えていただくと、消耗品の交換タイミングをより正確にお知らせできます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("使うモードを選択", systemImage: "square.grid.2x2")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Mode.allCases) { mode in
                    modeRow(mode)
                    if mode != Mode.allCases.last {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if selectedModes.isEmpty {
                Text("少なくとも1つ選択してください")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func modeRow(_ mode: Mode) -> some View {
        Button {
            if selectedModes.contains(mode) {
                if selectedModes.count > 1 { selectedModes.remove(mode) }
            } else {
                selectedModes.insert(mode)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: mode.iconName)
                    .frame(width: 28)
                    .foregroundStyle(modeColor(mode))
                Text(mode.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: selectedModes.contains(mode)
                      ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedModes.contains(mode) ? .blue : .secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }

    private var familySizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("家族の人数", systemImage: "person.2")
                .font(.headline)

            HStack {
                Text("何人家族ですか？")
                    .foregroundStyle(.secondary)
                Spacer()
                Stepper("\(familySize)人", value: $familySize, in: 1...8)
                    .fixedSize()
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("消耗品の使用ペースを人数に合わせて調整します")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var carSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("車の情報", systemImage: "car")
                .font(.headline)

            VStack(spacing: 0) {
                HStack {
                    Text("月間走行距離")
                    Spacer()
                    Picker("", selection: $monthlyMileage) {
                        ForEach(MonthlyMileage.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Divider().padding(.leading, 16)

                HStack {
                    Text("車の種類")
                    Spacer()
                    Picker("", selection: $vehicleType) {
                        ForEach(VehicleType.allCases) { v in
                            Text(v.displayName).tag(v)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("走行距離に応じてオイル・タイヤなどの交換時期を計算します")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var startButton: some View {
        Button {
            profileStore.completeOnboarding(
                visibleModes: Array(selectedModes),
                familySize: familySize,
                monthlyMileage: monthlyMileage,
                vehicleType: vehicleType
            )
        } label: {
            Text("はじめる")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedModes.isEmpty ? Color.secondary : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedModes.isEmpty)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func modeColor(_ mode: Mode) -> Color {
        switch mode {
        case .daily:  .blue
        case .car:    .green
        case .gadget: .purple
        }
    }
}
