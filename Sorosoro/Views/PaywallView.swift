import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PlanService.self) private var planService
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false
    @State private var errorMessage: String?
    @State private var selectedPlan: PlanOption = .yearly

    enum PlanOption { case monthly, yearly }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    featureSection
                    planPickerSection
                    purchaseSection
                    footerSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .task { await planService.loadProducts() }
            .onChange(of: planService.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.12), Color.teal.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 88, height: 88)
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .teal], startPoint: .top, endPoint: .bottom)
                        )
                }
                .padding(.top, 32)

                VStack(spacing: 8) {
                    Text("買いどき Plus")
                        .font(.system(size: 26, weight: .bold))
                    Text("管理を、もっとかしこく。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 28)
            }
        }
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Plusでできること")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)

            VStack(spacing: 1) {
                featureRow("全モード同時に管理",
                           detail: "日用品・車 を両方使える",
                           icon: "square.grid.2x2.fill", color: .blue,
                           freeLabel: "1つのみ")
                featureRow("アイテム・通知 無制限",
                           detail: "登録件数・通知件数の上限なし",
                           icon: "infinity", color: .teal,
                           freeLabel: "各10件/5件")
                featureRow("カスタムテンプレート",
                           detail: "よく買う商品を登録して再利用",
                           icon: "doc.badge.plus", color: .indigo,
                           freeLabel: "プリセットのみ")
                featureRow("メモ機能",
                           detail: "銘柄・メーカー・購入先のメモ",
                           icon: "note.text", color: .orange,
                           freeLabel: nil)
                featureRow("家族・パートナーと共有",
                           detail: "iCloudで同じ管理リストを共有",
                           icon: "person.2.fill", color: .purple,
                           freeLabel: nil)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    private var planPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プランを選択")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            VStack(spacing: 10) {
                if let yearly = planService.yearlyProduct {
                    planCard(
                        option: .yearly,
                        product: yearly,
                        badge: "2ヶ月分お得",
                        monthlyEquivalent: monthlyEquivalent(yearly)
                    )
                }
                if let monthly = planService.monthlyProduct {
                    planCard(
                        option: .monthly,
                        product: monthly,
                        badge: nil,
                        monthlyEquivalent: nil
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    purchasing = true
                    errorMessage = nil
                    let product = selectedPlan == .yearly
                        ? planService.yearlyProduct
                        : planService.monthlyProduct
                    guard let product else { return }
                    do {
                        _ = try await planService.purchase(product)
                    } catch {
                        errorMessage = "購入に失敗しました"
                    }
                    purchasing = false
                }
            } label: {
                HStack(spacing: 8) {
                    if purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(purchasing ? "処理中..." : "Plusをはじめる")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(purchasing ? Color.secondary : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(purchasing)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("購入を復元") {
                Task { await planService.restorePurchases() }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 24) {
                if let termsURL = URL(string: "https://mankai-software.com/terms") {
                    Link("利用規約", destination: termsURL)
                }
                if let privacyURL = URL(string: "https://mankai-software.com/privacy") {
                    Link("プライバシーポリシー", destination: privacyURL)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("サブスクリプションは確認後に課金されます。現在の期間終了24時間前までにキャンセルしない限り自動更新されます。App Store「設定」→「Apple ID」→「サブスクリプション」から解約できます。")
                .font(.caption2)
                .foregroundStyle(Color(UIColor.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
    }

    // MARK: - Components

    private func featureRow(_ title: String, detail: String, icon: String, color: Color, freeLabel: String?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let freeLabel {
                Text(freeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .clipShape(Capsule())
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    private func planCard(option: PlanOption, product: Product, badge: String?, monthlyEquivalent: String?) -> some View {
        let isSelected = selectedPlan == option
        return Button { selectedPlan = option } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? .blue : Color(UIColor.systemGray3))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(option == .yearly ? "年額プラン" : "月額プラン")
                            .font(.subheadline.weight(.semibold))
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                    if let eq = monthlyEquivalent {
                        Text(eq)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func monthlyEquivalent(_ product: Product) -> String? {
        guard let monthly = planService.monthlyProduct else { return nil }
        let monthlyDouble = Double(truncating: monthly.price as NSNumber)
        let yearlyDouble = Double(truncating: product.price as NSNumber)
        guard monthlyDouble > 0 else { return nil }
        let equivDouble = yearlyDouble / 12
        let saving = Int(((monthlyDouble - equivDouble) / monthlyDouble * 100).rounded())
        let equivDecimal = Decimal(equivDouble)
        let formatted = equivDecimal.formatted(product.priceFormatStyle)
        return "\(formatted)/月（約\(saving)%割引）"
    }
}
