import SwiftUI

struct OnboardingView: View {
    @Environment(UserProfileStore.self) private var profileStore

    @State private var page = 0
    @State private var selectedModes: Set<Mode> = Set(Mode.allCases)
    @State private var adultsCount: Int = 2
    @State private var childrenCount: Int = 0
    @State private var monthlyMileage: MonthlyMileage = .medium
    @State private var vehicleType: VehicleType = .gasoline

    private let totalPages = 3

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                modePage.tag(1)
                profilePage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            VStack(spacing: 16) {
                pageIndicator
                navigationButtons
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.15), Color.teal.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .teal], startPoint: .top, endPoint: .bottom)
                        )
                }

                VStack(spacing: 12) {
                    Text("補充のタイミングを\n見逃さないために")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("シャンプー・エンジンオイル・電池──\n「そろそろ必要かも」をアプリが先回りして知らせます")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }

    private var modePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("何を管理しますか？")
                        .font(.title2.bold())
                    Text("あとから変更できます")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 12) {
                    modeCard(
                        mode: .daily,
                        title: "日用品",
                        description: "洗剤・シャンプー・トイレットペーパーなど\n使用量に合わせた補充タイミングを管理",
                        examples: ["🧴 シャンプー", "🧻 トイレットペーパー", "🧼 洗剤", "🪥 歯ブラシ"],
                        color: .blue
                    )
                    modeCard(
                        mode: .car,
                        title: "車",
                        description: "エンジンオイル・タイヤ・ブレーキパッドなど\n走行距離に連動した交換時期を管理",
                        examples: ["🛢 エンジンオイル", "🔧 オイルフィルター", "🚗 タイヤ", "⚙️ ブレーキパッド"],
                        color: .green
                    )
                }

                if selectedModes.isEmpty {
                    Text("少なくとも1つ選んでください")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 140)
        }
    }

    private var profilePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("もう少し教えてください")
                        .font(.title2.bold())
                    Text("消耗スピードをあなたの生活に合わせます")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                if selectedModes.contains(.daily) {
                    familySection
                }

                if selectedModes.contains(.car) {
                    carSection
                }

                if !selectedModes.contains(.daily) && !selectedModes.contains(.car) {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("準備完了！")
                            .font(.title3.bold())
                        Text("「はじめる」をタップしてください")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 140)
        }
    }

    // MARK: - Sub-views

    private func modeCard(mode: Mode, title: String, description: String, examples: [String], color: Color) -> some View {
        let isSelected = selectedModes.contains(mode)
        return Button {
            if isSelected {
                if selectedModes.count > 1 { selectedModes.remove(mode) }
            } else {
                selectedModes.insert(mode)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: mode.iconName)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? color : .secondary)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? color : Color(UIColor.systemGray3))
                }

                if isSelected {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(examples, id: \.self) { ex in
                            Text(ex)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(color.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }

    private var familySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("家族の人数", systemImage: "person.2.fill")
                .font(.headline)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("大人")
                        Text("高校生以上")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    counterControl(value: $adultsCount, range: 1...6)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Divider().padding(.leading, 16)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("子供")
                        Text("中学生以下（消耗量は大人の約60%）")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    counterControl(value: $childrenCount, range: 0...6)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("合計 \(adultsCount)大人 + \(childrenCount)子供 → 実質 \(String(format: "%.1f", Double(adultsCount) + Double(childrenCount) * 0.6))人分")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var carSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("車の情報", systemImage: "car.fill")
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
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("走行距離に応じてオイル・タイヤの交換周期を自動計算します")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func counterControl(value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 0) {
            Button {
                if value.wrappedValue > range.lowerBound {
                    value.wrappedValue -= 1
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .clipShape(Circle())
            }
            .disabled(value.wrappedValue <= range.lowerBound)

            Text("\(value.wrappedValue)")
                .font(.title3.monospacedDigit())
                .frame(width: 40)

            Button {
                if value.wrappedValue < range.upperBound {
                    value.wrappedValue += 1
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 36, height: 36)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .clipShape(Circle())
            }
            .disabled(value.wrappedValue >= range.upperBound)
        }
    }

    // MARK: - Navigation

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Color.blue : Color(UIColor.systemGray4))
                    .frame(width: i == page ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: page)
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if page > 0 {
                Button {
                    withAnimation { page -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 52, height: 52)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(Circle())
                }
            }

            Button {
                if page < totalPages - 1 {
                    withAnimation { page += 1 }
                } else {
                    profileStore.completeOnboarding(
                        visibleModes: Array(selectedModes),
                        adultsCount: adultsCount,
                        childrenCount: childrenCount,
                        monthlyMileage: monthlyMileage,
                        vehicleType: vehicleType
                    )
                }
            } label: {
                HStack(spacing: 8) {
                    Text(page == totalPages - 1 ? "はじめる" : "次へ")
                        .font(.headline)
                    if page < totalPages - 1 {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isNextDisabled ? Color(UIColor.systemGray4) : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 26))
            }
            .disabled(isNextDisabled)
        }
    }

    private var isNextDisabled: Bool {
        page == 1 && selectedModes.isEmpty
    }
}
