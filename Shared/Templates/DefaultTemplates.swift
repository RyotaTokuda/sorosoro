import Foundation

enum DefaultTemplates {
    static let all: [ItemTemplate] = daily + car

    static let daily: [ItemTemplate] = [
        // 日用品
        ItemTemplate(name: "シャンプー",        mode: .daily, cycleDays: 60,  isDefault: true),
        ItemTemplate(name: "コンディショナー",  mode: .daily, cycleDays: 60,  isDefault: true),
        ItemTemplate(name: "ボディソープ",      mode: .daily, cycleDays: 45,  isDefault: true),
        ItemTemplate(name: "歯ブラシ",          mode: .daily, cycleDays: 30,  isDefault: true),
        ItemTemplate(name: "歯磨き粉",          mode: .daily, cycleDays: 60,  isDefault: true),
        ItemTemplate(name: "食器用洗剤",        mode: .daily, cycleDays: 30,  isDefault: true),
        ItemTemplate(name: "洗濯洗剤",          mode: .daily, cycleDays: 30,  isDefault: true),
        ItemTemplate(name: "柔軟剤",            mode: .daily, cycleDays: 45,  isDefault: true),
        ItemTemplate(name: "ラップ",            mode: .daily, cycleDays: 30,  isDefault: true),
        ItemTemplate(name: "アルミホイル",      mode: .daily, cycleDays: 60,  isDefault: true),
        ItemTemplate(name: "トイレットペーパー",mode: .daily, cycleDays: 14,  isDefault: true),
        ItemTemplate(name: "ティッシュペーパー",mode: .daily, cycleDays: 14,  isDefault: true),
        ItemTemplate(name: "キッチンスポンジ",  mode: .daily, cycleDays: 30,  isDefault: true),
        ItemTemplate(name: "ハンドソープ",      mode: .daily, cycleDays: 30,  isDefault: true),
        ItemTemplate(name: "浄水器カートリッジ",mode: .daily, cycleDays: 90,  isDefault: true),
        // 家電・ガジェット消耗品（日用品タブに統合）
        ItemTemplate(name: "乾電池（リモコン等）",   mode: .daily, cycleDays: 180, isDefault: true),
        ItemTemplate(name: "プリンターインク",        mode: .daily, cycleDays: 90,  isDefault: true),
        ItemTemplate(name: "エアコンフィルター",      mode: .daily, cycleDays: 90,  isDefault: true),
        ItemTemplate(name: "空気清浄機フィルター",    mode: .daily, cycleDays: 365, isDefault: true),
        ItemTemplate(name: "掃除機フィルター",        mode: .daily, cycleDays: 180, isDefault: true),
        ItemTemplate(name: "電動歯ブラシ替えブラシ",  mode: .daily, cycleDays: 90,  isDefault: true),
        ItemTemplate(name: "シェーバー替刃",          mode: .daily, cycleDays: 365, isDefault: true),
    ]

    static let car: [ItemTemplate] = [
        ItemTemplate(name: "エンジンオイル",    mode: .car, cycleDays: 180,  distanceKmBase: 5000,  isDefault: true),
        ItemTemplate(name: "オイルフィルター",  mode: .car, cycleDays: 365,  distanceKmBase: 10000, isDefault: true),
        ItemTemplate(name: "ブレーキパッド",    mode: .car, cycleDays: 730,  distanceKmBase: 30000, isDefault: true),
        ItemTemplate(name: "タイヤ（交換目安）",mode: .car, cycleDays: 1095, distanceKmBase: 50000, isDefault: true),
        ItemTemplate(name: "ワイパーゴム",      mode: .car, cycleDays: 365,  isDefault: true),
        ItemTemplate(name: "エアコンフィルター",mode: .car, cycleDays: 730,  isDefault: true),
        ItemTemplate(name: "バッテリー",        mode: .car, cycleDays: 1095, isDefault: true),
        ItemTemplate(name: "ウォッシャー液",    mode: .car, cycleDays: 90,   isDefault: true),
    ]

    static func templates(for mode: Mode) -> [ItemTemplate] {
        switch mode {
        case .daily, .gadget: daily  // gadget items fall into daily list
        case .car:            car
        }
    }
}
