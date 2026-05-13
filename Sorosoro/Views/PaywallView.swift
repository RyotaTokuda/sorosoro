import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PlanService.self) private var planService
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing: PurchasingState = .idle

    enum PurchasingState: Equatable { case idle, monthly, yearly }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    comparisonSection
                        .padding(.top, 28)
                    pricingSection
                        .padding(.top, 24)
                    ctaSection
                        .padding(.top, 20)
                    footerSection
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                        .foregroundStyle(.blue)
                }
            }
            .task { await planService.loadProducts() }
            .onChange(of: planService.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.12), Color.teal.opacity(0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.15)).frame(width: 88, height: 88)
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(LinearGradient(colors: [.blue, .teal], startPoint: .top, endPoint: .bottom))
                }
                .padding(.top, 32)
                VStack(spacing: 8) {
                    Text("paywall.title").font(.system(size: 26, weight: .bold))
                    Text("paywall.subtitle").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Comparison Table

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("paywall.features.title")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("").frame(maxWidth: .infinity, alignment: .leading)
                    Text("paywall.free.column")
                        .font(.caption.bold()).foregroundStyle(.secondary).frame(width: 64, alignment: .center)
                    Text("Plus")
                        .font(.caption.bold()).foregroundStyle(.blue).frame(width: 64, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.tertiarySystemBackground))

                Divider()

                comparisonRow("paywall.feature.all.modes",
                              icon: "square.grid.2x2.fill", color: .blue,
                              freeValue: "paywall.feature.all.modes.free.label",
                              plusMark: true)
                Divider().padding(.leading, 16)
                comparisonRow("paywall.feature.unlimited",
                              icon: "infinity", color: .teal,
                              freeValue: "paywall.feature.unlimited.free.label",
                              plusMark: true)
                Divider().padding(.leading, 16)
                comparisonRow("paywall.feature.templates",
                              icon: "doc.badge.plus", color: .indigo,
                              freeValue: nil, plusMark: true)
                Divider().padding(.leading, 16)
                comparisonRow("paywall.feature.memo",
                              icon: "note.text", color: .orange,
                              freeValue: nil, plusMark: true)
                Divider().padding(.leading, 16)
                comparisonRow("paywall.feature.sharing",
                              icon: "person.2.fill", color: .purple,
                              freeValue: nil, plusMark: true)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    private func comparisonRow(
        _ titleKey: LocalizedStringKey,
        icon: String, color: Color,
        freeValue: LocalizedStringKey?,
        plusMark: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(titleKey).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)

            // 無料列
            Group {
                if let freeValue {
                    Text(freeValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                }
            }
            .frame(width: 64, alignment: .center)

            // Plus列
            Group {
                if plusMark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.blue)
                }
            }
            .frame(width: 64, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    // MARK: - Pricing (month vs year side-by-side)

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("paywall.plan.section.title")
                .font(.headline)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                // Monthly card
                pricingCard(
                    label: "paywall.plan.monthly",
                    product: planService.monthlyProduct,
                    subtitle: nil,
                    badge: nil,
                    isHighlighted: false
                )
                // Yearly card
                pricingCard(
                    label: "paywall.plan.yearly",
                    product: planService.yearlyProduct,
                    subtitle: yearlySubtitle,
                    badge: "paywall.yearly.badge",
                    isHighlighted: true
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private func pricingCard(
        label: LocalizedStringKey,
        product: Product?,
        subtitle: String?,
        badge: LocalizedStringKey?,
        isHighlighted: Bool
    ) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text(label).font(.caption.bold()).foregroundStyle(isHighlighted ? .blue : .secondary)
                if let badge {
                    Text(badge)
                        .font(.caption2.bold()).foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.orange).clipShape(Capsule())
                }
            }
            Text(product?.displayPrice ?? "---")
                .font(.title3.bold())
                .foregroundStyle(isHighlighted ? .blue : .primary)
            if let sub = subtitle {
                Text(sub).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isHighlighted ? Color.blue.opacity(0.06) : Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isHighlighted ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1.5)
                )
        )
    }

    private var yearlySubtitle: String? {
        guard let monthly = planService.monthlyProduct,
              let yearly = planService.yearlyProduct else { return nil }
        let monthlyD = Double(truncating: monthly.price as NSNumber)
        let yearlyD  = Double(truncating: yearly.price as NSNumber)
        guard monthlyD > 0 else { return nil }
        let equivD = yearlyD / 12
        let saving = Int(((monthlyD - equivD) / monthlyD * 100).rounded())
        let equivDecimal = Decimal(equivD)
        let formatted = equivDecimal.formatted(yearly.priceFormatStyle)
        return String(localized: "paywall.monthly.equivalent \(formatted) \(saving)")
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 10) {
            // Yearly (primary)
            ctaButton(plan: .yearly,
                      product: planService.yearlyProduct,
                      labelKey: "paywall.cta.yearly",
                      isPrimary: true)

            // Monthly (secondary)
            ctaButton(plan: .monthly,
                      product: planService.monthlyProduct,
                      labelKey: "paywall.cta.monthly",
                      isPrimary: false)

            if case .idle = purchasing {} else {}
            Button("paywall.restore") {
                Task { await planService.restorePurchases() }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
    }

    private func ctaButton(
        plan: PurchasingState,
        product: Product?,
        labelKey: LocalizedStringKey,
        isPrimary: Bool
    ) -> some View {
        let isThisPurchasing: Bool = {
            if case .yearly = purchasing, case .yearly = plan { return true }
            if case .monthly = purchasing, case .monthly = plan { return true }
            return false
        }()
        let anyPurchasing = purchasing != .idle

        return Button {
            guard let product else { return }
            Task {
                purchasing = plan
                do { _ = try await planService.purchase(product) } catch {}
                purchasing = .idle
            }
        } label: {
            HStack(spacing: 8) {
                if isThisPurchasing {
                    ProgressView().tint(isPrimary ? .white : .blue)
                } else {
                    if isPrimary { Image(systemName: "sparkles") }
                    Text(labelKey).font(.headline)
                    if let price = product?.displayPrice {
                        Text(price).font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isPrimary ? (anyPurchasing && !isThisPurchasing ? Color.blue.opacity(0.4) : Color.blue) : Color.clear)
            .foregroundStyle(isPrimary ? .white : .blue)
            .overlay(
                isPrimary ? nil :
                    RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(anyPurchasing || product == nil)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 24) {
                if let termsURL = URL(string: "https://mankai-software.vercel.app/terms") {
                    Link("paywall.terms", destination: termsURL)
                        .foregroundStyle(.blue)
                }
                if let privacyURL = URL(string: "https://mankai-software.vercel.app/privacy") {
                    Link("paywall.privacy", destination: privacyURL)
                        .foregroundStyle(.blue)
                }
            }
            .font(.caption)

            Text("paywall.legal")
                .font(.caption2)
                .foregroundStyle(Color(UIColor.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}
