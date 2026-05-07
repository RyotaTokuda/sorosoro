import Foundation

enum PlanLimits {
    /// モードあたりのアイテム登録上限
    static func itemLimit(isPro: Bool) -> Int {
        isPro ? .max : 10
    }

    /// 通知可能アイテム数
    static func notificationLimit(isPro: Bool) -> Int {
        isPro ? 64 : 5
    }

    /// カスタムテンプレート作成可否
    static func canCreateCustomTemplate(isPro: Bool) -> Bool {
        isPro
    }

    /// 全モード利用可否
    static func canUseAllModes(isPro: Bool) -> Bool {
        isPro
    }

    /// 買い物リスト全モード横断表示可否
    static func canCrossModeShopping(isPro: Bool) -> Bool {
        isPro
    }

    /// メモ機能利用可否
    static func canUseMemo(isPro: Bool) -> Bool {
        isPro
    }
}
