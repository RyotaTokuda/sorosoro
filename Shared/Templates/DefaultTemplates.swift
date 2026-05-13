import Foundation

enum DefaultTemplates {
    static let all: [ItemTemplate] = daily + car + pet + health

    // MARK: - 日用品

    static let daily: [ItemTemplate] = [
        // バスルーム
        ItemTemplate(name: "シャンプー",              mode: .daily, cycleDays: 60,  category: "バスルーム"),
        ItemTemplate(name: "コンディショナー",        mode: .daily, cycleDays: 60,  category: "バスルーム"),
        ItemTemplate(name: "ボディソープ",            mode: .daily, cycleDays: 45,  category: "バスルーム"),
        ItemTemplate(name: "洗顔料",                  mode: .daily, cycleDays: 60,  category: "バスルーム"),
        ItemTemplate(name: "歯ブラシ",                mode: .daily, cycleDays: 30,  category: "バスルーム"),
        ItemTemplate(name: "歯磨き粉",                mode: .daily, cycleDays: 60,  category: "バスルーム"),
        ItemTemplate(name: "ハンドソープ",            mode: .daily, cycleDays: 30,  category: "バスルーム"),
        ItemTemplate(name: "電動歯ブラシ替えブラシ",  mode: .daily, cycleDays: 90,  category: "バスルーム"),
        ItemTemplate(name: "シェーバー替刃",          mode: .daily, cycleDays: 365, category: "バスルーム"),
        ItemTemplate(name: "かみそり刃",              mode: .daily, cycleDays: 30,  category: "バスルーム"),
        ItemTemplate(name: "バスタオル",              mode: .daily, cycleDays: 365, category: "バスルーム"),
        ItemTemplate(name: "フェイスタオル",          mode: .daily, cycleDays: 180, category: "バスルーム"),

        // キッチン
        ItemTemplate(name: "食器用洗剤",              mode: .daily, cycleDays: 30,  category: "キッチン"),
        ItemTemplate(name: "キッチンスポンジ",        mode: .daily, cycleDays: 30,  category: "キッチン"),
        ItemTemplate(name: "ラップ",                  mode: .daily, cycleDays: 30,  category: "キッチン"),
        ItemTemplate(name: "アルミホイル",            mode: .daily, cycleDays: 60,  category: "キッチン"),
        ItemTemplate(name: "浄水器カートリッジ",      mode: .daily, cycleDays: 90,  category: "キッチン"),
        ItemTemplate(name: "キッチンペーパー",        mode: .daily, cycleDays: 30,  category: "キッチン"),
        ItemTemplate(name: "ジッパーバッグ",          mode: .daily, cycleDays: 30,  category: "キッチン"),
        ItemTemplate(name: "台所用漂白剤",            mode: .daily, cycleDays: 90,  category: "キッチン"),

        // 洗濯・掃除
        ItemTemplate(name: "洗濯洗剤",                mode: .daily, cycleDays: 30,  category: "洗濯・掃除"),
        ItemTemplate(name: "柔軟剤",                  mode: .daily, cycleDays: 45,  category: "洗濯・掃除"),
        ItemTemplate(name: "漂白剤",                  mode: .daily, cycleDays: 90,  category: "洗濯・掃除"),
        ItemTemplate(name: "トイレットペーパー",      mode: .daily, cycleDays: 14,  category: "洗濯・掃除"),
        ItemTemplate(name: "ティッシュペーパー",      mode: .daily, cycleDays: 14,  category: "洗濯・掃除"),
        ItemTemplate(name: "ウェットティッシュ",      mode: .daily, cycleDays: 30,  category: "洗濯・掃除"),
        ItemTemplate(name: "消臭剤（トイレ）",        mode: .daily, cycleDays: 60,  category: "洗濯・掃除"),
        ItemTemplate(name: "除菌スプレー",            mode: .daily, cycleDays: 30,  category: "洗濯・掃除"),
        ItemTemplate(name: "ゴミ袋",                  mode: .daily, cycleDays: 30,  category: "洗濯・掃除"),

        // 家電・フィルター
        ItemTemplate(name: "エアコンフィルター",      mode: .daily, cycleDays: 90,  category: "家電・フィルター"),
        ItemTemplate(name: "空気清浄機フィルター",    mode: .daily, cycleDays: 365, category: "家電・フィルター"),
        ItemTemplate(name: "掃除機フィルター",        mode: .daily, cycleDays: 180, category: "家電・フィルター"),
        ItemTemplate(name: "除湿機フィルター",        mode: .daily, cycleDays: 180, category: "家電・フィルター"),
        ItemTemplate(name: "乾電池（リモコン等）",    mode: .daily, cycleDays: 180, category: "家電・フィルター"),
        ItemTemplate(name: "プリンターインク",        mode: .daily, cycleDays: 90,  category: "家電・フィルター"),
        ItemTemplate(name: "電球・LED",               mode: .daily, cycleDays: 1095,category: "家電・フィルター"),
    ]

    // MARK: - 車

    static let car: [ItemTemplate] = [
        // エンジン・オイル
        ItemTemplate(name: "エンジンオイル",          mode: .car, cycleDays: 180,  distanceKmBase: 5000,  category: "エンジン・オイル"),
        ItemTemplate(name: "オイルフィルター",        mode: .car, cycleDays: 365,  distanceKmBase: 10000, category: "エンジン・オイル"),
        ItemTemplate(name: "エアフィルター",          mode: .car, cycleDays: 365,  distanceKmBase: 15000, category: "エンジン・オイル"),
        ItemTemplate(name: "ATF / CVTフルード",       mode: .car, cycleDays: 1095, distanceKmBase: 40000, category: "エンジン・オイル"),

        // ブレーキ
        ItemTemplate(name: "ブレーキパッド",          mode: .car, cycleDays: 730,  distanceKmBase: 30000, category: "ブレーキ"),
        ItemTemplate(name: "ブレーキフルード",        mode: .car, cycleDays: 730,  distanceKmBase: 40000, category: "ブレーキ"),

        // タイヤ・足回り
        ItemTemplate(name: "タイヤ（交換目安）",      mode: .car, cycleDays: 1095, distanceKmBase: 50000, category: "タイヤ・足回り"),
        ItemTemplate(name: "タイヤローテーション",    mode: .car, cycleDays: 180,  distanceKmBase: 5000,  category: "タイヤ・足回り"),
        ItemTemplate(name: "スペアタイヤ確認",        mode: .car, cycleDays: 365,                         category: "タイヤ・足回り"),

        // 外装・消耗品
        ItemTemplate(name: "ワイパーゴム",            mode: .car, cycleDays: 365,                         category: "外装・消耗品"),
        ItemTemplate(name: "バッテリー",              mode: .car, cycleDays: 1095,                        category: "外装・消耗品"),
        ItemTemplate(name: "ウォッシャー液",          mode: .car, cycleDays: 90,                          category: "外装・消耗品"),
        ItemTemplate(name: "エアコンフィルター",      mode: .car, cycleDays: 730,                         category: "外装・消耗品"),
        ItemTemplate(name: "スパークプラグ",          mode: .car, cycleDays: 1095, distanceKmBase: 30000, category: "外装・消耗品"),
        ItemTemplate(name: "冷却水（LLC）",           mode: .car, cycleDays: 730,                         category: "外装・消耗品"),
        ItemTemplate(name: "ヘッドライトバルブ",      mode: .car, cycleDays: 730,                         category: "外装・消耗品"),
    ]

    // MARK: - ペット

    static let pet: [ItemTemplate] = [
        // 予防・医療
        ItemTemplate(name: "ノミ・マダニ予防薬",      mode: .pet, cycleDays: 30,  category: "予防・医療"),
        ItemTemplate(name: "フィラリア予防薬",        mode: .pet, cycleDays: 30,  category: "予防・医療"),
        ItemTemplate(name: "混合ワクチン",            mode: .pet, cycleDays: 365, category: "予防・医療"),
        ItemTemplate(name: "狂犬病ワクチン",          mode: .pet, cycleDays: 365, category: "予防・医療"),
        ItemTemplate(name: "内部寄生虫予防薬",        mode: .pet, cycleDays: 90,  category: "予防・医療"),
        ItemTemplate(name: "定期健診",                mode: .pet, cycleDays: 180, category: "予防・医療"),

        // グルーミング
        ItemTemplate(name: "シャンプー・トリミング",  mode: .pet, cycleDays: 30,  category: "グルーミング"),
        ItemTemplate(name: "爪切り",                  mode: .pet, cycleDays: 30,  category: "グルーミング"),
        ItemTemplate(name: "歯磨き用品",              mode: .pet, cycleDays: 30,  category: "グルーミング"),
        ItemTemplate(name: "イヤークリーナー",        mode: .pet, cycleDays: 14,  category: "グルーミング"),
        ItemTemplate(name: "ブラッシング用品",        mode: .pet, cycleDays: 180, category: "グルーミング"),

        // 食事・日用品
        ItemTemplate(name: "ペットフード（ドライ）",  mode: .pet, cycleDays: 30,  category: "食事・日用品"),
        ItemTemplate(name: "ペットフード（ウェット）",mode: .pet, cycleDays: 14,  category: "食事・日用品"),
        ItemTemplate(name: "おやつ",                  mode: .pet, cycleDays: 30,  category: "食事・日用品"),
        ItemTemplate(name: "トイレ砂",                mode: .pet, cycleDays: 14,  category: "食事・日用品"),
        ItemTemplate(name: "ペットシーツ",            mode: .pet, cycleDays: 14,  category: "食事・日用品"),
        ItemTemplate(name: "消臭スプレー",            mode: .pet, cycleDays: 30,  category: "食事・日用品"),
    ]

    // MARK: - 健康

    static let health: [ItemTemplate] = [
        // サプリメント
        ItemTemplate(name: "プロテイン",              mode: .health, cycleDays: 30, category: "サプリメント"),
        ItemTemplate(name: "マルチビタミン",          mode: .health, cycleDays: 30, category: "サプリメント"),
        ItemTemplate(name: "ビタミンC",               mode: .health, cycleDays: 30, category: "サプリメント"),
        ItemTemplate(name: "ビタミンD",               mode: .health, cycleDays: 30, category: "サプリメント"),
        ItemTemplate(name: "葉酸",                    mode: .health, cycleDays: 30, category: "サプリメント"),
        ItemTemplate(name: "鉄分サプリ",              mode: .health, cycleDays: 30, category: "サプリメント"),
        ItemTemplate(name: "DHA・EPA",                mode: .health, cycleDays: 30, category: "サプリメント"),
        ItemTemplate(name: "整腸剤・乳酸菌",          mode: .health, cycleDays: 30, category: "サプリメント"),
        ItemTemplate(name: "カルシウム",              mode: .health, cycleDays: 30, category: "サプリメント"),
        ItemTemplate(name: "マグネシウム",            mode: .health, cycleDays: 30, category: "サプリメント"),

        // コンタクト・アイケア
        ItemTemplate(name: "1ヶ月使い捨てコンタクト", mode: .health, cycleDays: 30, category: "コンタクト・アイケア"),
        ItemTemplate(name: "2週間使い捨てコンタクト", mode: .health, cycleDays: 14, category: "コンタクト・アイケア"),
        ItemTemplate(name: "コンタクト洗浄液",        mode: .health, cycleDays: 30, category: "コンタクト・アイケア"),
        ItemTemplate(name: "目薬",                    mode: .health, cycleDays: 30, category: "コンタクト・アイケア"),

        // スキンケア・美容
        ItemTemplate(name: "日焼け止め",              mode: .health, cycleDays: 30,  category: "スキンケア・美容"),
        ItemTemplate(name: "化粧水",                  mode: .health, cycleDays: 60,  category: "スキンケア・美容"),
        ItemTemplate(name: "乳液・保湿クリーム",      mode: .health, cycleDays: 60,  category: "スキンケア・美容"),
        ItemTemplate(name: "美容液",                  mode: .health, cycleDays: 60,  category: "スキンケア・美容"),
        ItemTemplate(name: "リップクリーム",          mode: .health, cycleDays: 30,  category: "スキンケア・美容"),

        // 常備薬・その他
        ItemTemplate(name: "常備薬（解熱剤・鎮痛剤）",mode: .health, cycleDays: 365, category: "常備薬・その他"),
        ItemTemplate(name: "絆創膏",                  mode: .health, cycleDays: 180, category: "常備薬・その他"),
        ItemTemplate(name: "マスク",                  mode: .health, cycleDays: 14,  category: "常備薬・その他"),
        ItemTemplate(name: "体温計電池",              mode: .health, cycleDays: 730, category: "常備薬・その他"),
        ItemTemplate(name: "生理用品",                mode: .health, cycleDays: 30,  category: "常備薬・その他"),
    ]

    static func templates(for mode: Mode) -> [ItemTemplate] {
        switch mode {
        case .daily, .gadget: daily
        case .car:            car
        case .pet:            pet
        case .health:         health
        }
    }
}
