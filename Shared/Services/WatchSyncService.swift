import Foundation
import WatchConnectivity

/// Watch <-> iPhone 間のリアルタイム同期サービス
@Observable
final class WatchSyncService: NSObject, WCSessionDelegate {
    static let shared = WatchSyncService()

    private(set) var isReachable = false

    var onItemUpdated: ((Item) -> Void)?
    var onItemDeleted: ((UUID) -> Void)?
    var onItemPurchased: ((UUID) -> Void)?
    var onShoppingListChanged: (() -> Void)?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - 送信

    /// アイテムの追加・更新を相手デバイスに送信
    func sendItemUpdate(_ item: Item) {
        guard WCSession.default.activationState == .activated else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(item)
            WCSession.default.transferUserInfo([
                "type": "updateItem",
                "data": data,
            ])
        } catch {
            print("[WatchSync] encode error: \(error)")
        }
    }

    /// アイテム削除を相手デバイスに送信
    func sendItemDeletion(id: UUID) {
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.transferUserInfo([
            "type": "deleteItem",
            "id": id.uuidString,
        ])
    }

    /// 「買った！」を相手デバイスに送信
    func sendMarkPurchased(itemId: UUID) {
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.transferUserInfo([
            "type": "markPurchased",
            "id": itemId.uuidString,
        ])
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("[WatchSync] activation error: \(error)")
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "updateItem":
            guard let data = userInfo["data"] as? Data else { return }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard let item = try? decoder.decode(Item.self, from: data) else { return }
            DispatchQueue.main.async { [weak self] in
                self?.onItemUpdated?(item)
            }

        case "deleteItem":
            guard let idString = userInfo["id"] as? String,
                  let id = UUID(uuidString: idString) else { return }
            DispatchQueue.main.async { [weak self] in
                self?.onItemDeleted?(id)
            }

        case "markPurchased":
            guard let idString = userInfo["id"] as? String,
                  let id = UUID(uuidString: idString) else { return }
            DispatchQueue.main.async { [weak self] in
                self?.onItemPurchased?(id)
            }

        default:
            break
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
    }
}
