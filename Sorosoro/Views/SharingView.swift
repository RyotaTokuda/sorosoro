import SwiftUI
import CloudKit

// UICloudSharingController の SwiftUI ラッパー
struct SharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onDismiss: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onDismiss: (() -> Void)?
        init(onDismiss: (() -> Void)?) { self.onDismiss = onDismiss }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("[Sharing] save error: \(error)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? { "そろそろ - 消耗品リスト" }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {}

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onDismiss?()
        }
    }
}

// MARK: - 共有ボタン（SettingsView から呼び出す）

struct ShareButton: View {
    @Environment(PlanService.self) private var planService
    @State private var isPreparing = false
    @State private var identifiableShare: IdentifiableShare?
    @State private var errorMessage: String?
    @State private var showingPaywall = false

    private let ck = CloudKitService.shared

    var body: some View {
        Group {
            if !planService.isPro {
                // Plus 限定機能
                Button { showingPaywall = true } label: {
                    HStack {
                        Label("家族・パートナーと共有", systemImage: "person.2.fill")
                        Spacer()
                        Text("Plus")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.yellow.opacity(0.25))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
            } else if ck.isAvailable {
                Button {
                    Task { await prepareShare() }
                } label: {
                    if isPreparing {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text("共有を準備中…")
                        }
                    } else {
                        Label("家族・パートナーと共有", systemImage: "person.2.fill")
                    }
                }
                .disabled(isPreparing)
            } else {
                Label("iCloud にサインインすると共有できます", systemImage: "icloud.slash")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .sheet(item: $identifiableShare) { wrapper in
            SharingView(share: wrapper.share, container: wrapper.container)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .alert("共有エラー", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func prepareShare() async {
        isPreparing = true
        do {
            let (s, c) = try await ck.fetchOrCreateShare()
            identifiableShare = IdentifiableShare(share: s, container: c)
        } catch {
            errorMessage = error.localizedDescription
        }
        isPreparing = false
    }
}

// CKShare の Sheet 表示用ラッパー
struct IdentifiableShare: Identifiable {
    let id = UUID()
    let share: CKShare
    let container: CKContainer
}
