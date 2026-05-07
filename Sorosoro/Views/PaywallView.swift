import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PlanService.self) private var planService
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    VStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.yellow)
                        Text("そろそろ Plus")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("すべての機能を使えるようになります")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    // 機能一覧
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow("全モード利用可能", icon: "square.grid.3x3.fill")
                        featureRow("アイテム登録数 無制限", icon: "infinity")
                        featureRow("通知アイテム数 無制限", icon: "bell.fill")
                        featureRow("カスタムテンプレート作成", icon: "doc.badge.plus")
                        featureRow("買い物リスト 全モード横断", icon: "cart.fill")
                        featureRow("メモ機能", icon: "note.text")
                    }
                    .padding(.horizontal)

                    // 価格ボタン
                    VStack(spacing: 12) {
                        if let monthly = planService.monthlyProduct {
                            purchaseButton(monthly, label: "月額プラン")
                        }
                        if let yearly = planService.yearlyProduct {
                            purchaseButton(yearly, label: "年額プラン（お得）")
                        }
                    }
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    // 復元
                    Button("購入の復元") {
                        Task { await planService.restorePurchases() }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // Apple 必須定型文
                    legalSection
                        .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task {
                await planService.loadProducts()
            }
            .onChange(of: planService.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Link("利用規約", destination: URL(string: "https://mankai-software.com/terms")!)
                Link("プライバシーポリシー", destination: URL(string: "https://mankai-software.com/privacy")!)
            }
            .font(.caption2)

            Text("サブスクリプションは購入の確認後に課金されます。サブスクリプションは現在の期間終了の24時間前までにキャンセルしない限り自動的に更新されます。更新料金はお使いのApple IDアカウントに課金されます。サブスクリプションの管理・解約はApp Store「設定」→「Apple ID」→「サブスクリプション」から行えます。")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.body)
        }
    }

    private func purchaseButton(_ product: Product, label: String) -> some View {
        Button {
            Task {
                purchasing = true
                errorMessage = nil
                do {
                    _ = try await planService.purchase(product)
                } catch {
                    errorMessage = "購入に失敗しました: \(error.localizedDescription)"
                }
                purchasing = false
            }
        } label: {
            VStack(spacing: 4) {
                Text(label)
                    .fontWeight(.semibold)
                Text(product.displayPrice)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(purchasing)
    }
}
