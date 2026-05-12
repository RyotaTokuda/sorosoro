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
                    Button("common.close") { dismiss() }
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
                    Text("paywall.title")
                        .font(.system(size: 26, weight: .bold))
                    Text("paywall.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 28)
            }
        }
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("paywall.features.title")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)

            VStack(spacing: 1) {
                featureRow("paywall.feature.all.modes",
                           detail: "paywall.feature.all.modes.detail",
                           icon: "square.grid.2x2.fill", color: .blue,
                           freeLabel: "paywall.feature.all.modes.free.label")
                featureRow("paywall.feature.unlimited",
                           detail: "paywall.feature.unlimited.detail",
                           icon: "infinity", color: .teal,
                           freeLabel: "paywall.feature.unlimited.free.label")
                featureRow("paywall.feature.templates",
                           detail: "paywall.feature.templates.detail",
                           icon: "doc.badge.plus", color: .indigo,
                           freeLabel: "paywall.feature.templates.free.label")
                featureRow("paywall.feature.memo",
                           detail: "paywall.feature.memo.detail",
                           icon: "note.text", color: .orange,
                           freeLabel: nil)
                featureRow("paywall.feature.sharing",
                           detail: "paywall.feature.sharing.detail",
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
            Text("paywall.plan.section.title")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            VStack(spacing: 10) {
                if let yearly = planService.yearlyProduct {
                    planCard(
                        option: .yearly,
                        product: yearly,
                        badge: "paywall.yearly.badge",
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
                        errorMessage = String(localized: "paywall.purchase.error")
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
                    Text(purchasing ? String(localized: "paywall.purchasing") : String(localized: "paywall.cta"))
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

            Button("paywall.restore") {
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
                    Link("paywall.terms", destination: termsURL)
                }
                if let privacyURL = URL(string: "https://mankai-software.com/privacy") {
                    Link("paywall.privacy", destination: privacyURL)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("paywall.legal")
                .font(.caption2)
                .foregroundStyle(Color(UIColor.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
    }

    // MARK: - Components

    private func featureRow(_ titleKey: LocalizedStringKey, detail detailKey: LocalizedStringKey, icon: String, color: Color, freeLabel freeLabelKey: LocalizedStringKey?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(titleKey)
                    .font(.subheadline.weight(.medium))
                Text(detailKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let freeLabelKey {
                Text(freeLabelKey)
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

    private func planCard(option: PlanOption, product: Product, badge: LocalizedStringKey?, monthlyEquivalent: String?) -> some View {
        let isSelected = selectedPlan == option
        return Button { selectedPlan = option } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? .blue : Color(UIColor.systemGray3))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(option == .yearly ? "paywall.plan.yearly" : "paywall.plan.monthly")
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
        return String(localized: "paywall.monthly.equivalent \(formatted) \(saving)")
    }
}
