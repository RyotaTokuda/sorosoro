# Sorosoro - 消耗品管理アプリ 仕様書

> 「なくなる前に気づく」「交換時期を忘れない」に特化した消耗品管理アプリ

---

## 概要

日用品・車・ガジェットなど、定期的に交換・補充が必要なアイテムの管理アプリ。
前回購入日と交換周期から「そろそろ買い替え時」をローカル通知で知らせる。

---

## Phase 1: iOS MVP（Swift / SwiftUI）

### 1-1. モード切替

| モード | アイコン | カラー | 代表アイテム例 |
|--------|----------|--------|----------------|
| 日用品 | house.fill | .blue | シャンプー、洗剤、ラップ、歯ブラシ |
| 車 | car.fill | .green | エンジンオイル、タイヤ、ワイパー、バッテリー |
| ガジェット | desktopcomputer | .purple | 電池、フィルター、インクカートリッジ |

- TabView でモード切替（各タブに独立したアイテムリスト）
- 無料プラン: 1モードのみ利用可能（初回起動時に選択）
- 有料プラン: 全モード解放

### 1-2. アイテム CRUD

#### データモデル: `Item`

```swift
struct Item: Codable, Identifiable {
    var id: UUID
    var name: String                    // アイテム名
    var mode: Mode                      // 所属モード
    var cycleDays: Int                  // 交換周期（日数）
    var lastPurchaseDate: Date          // 前回購入日
    var nextDueDate: Date               // 次回予定日（computed も可だが通知用に保持）
    var memo: String                    // メモ（任意）
    var notificationEnabled: Bool       // 通知ON/OFF
    var notificationDaysBefore: Int     // 何日前に通知するか（デフォルト: 3）
    var createdAt: Date
    var updatedAt: Date
}
```

#### 画面構成

| 画面 | 説明 |
|------|------|
| ItemListView | モード別アイテム一覧。残日数でソート。期限切れは赤表示 |
| ItemDetailView | アイテム詳細・編集。「買った！」ボタンで前回購入日を今日に更新 |
| ItemFormView | 新規追加 / 編集フォーム |

#### 一覧表示の状態

| 状態 | 条件 | 表示 |
|------|------|------|
| 期限切れ | nextDueDate < today | 赤背景 + 「○日超過」 |
| そろそろ | nextDueDate - today <= notificationDaysBefore | オレンジ + 「あと○日」 |
| まだ大丈夫 | それ以外 | 通常 + 「あと○日」 |

#### 「買った！」アクション

- `lastPurchaseDate = Date.now`
- `nextDueDate = Date.now + cycleDays`
- 通知を再スケジュール
- 確認ダイアログ付き（誤タップ防止）

### 1-3. テンプレート登録

#### データモデル: `ItemTemplate`

```swift
struct ItemTemplate: Codable, Identifiable {
    var id: UUID
    var name: String
    var mode: Mode
    var cycleDays: Int
    var notificationDaysBefore: Int
    var isDefault: Bool                 // プリインストール or ユーザー作成
}
```

#### プリインストールテンプレート

**日用品モード:**
| 名前 | 周期（日） |
|------|-----------|
| シャンプー | 60 |
| コンディショナー | 60 |
| ボディソープ | 45 |
| 歯ブラシ | 30 |
| 歯磨き粉 | 60 |
| 食器用洗剤 | 30 |
| 洗濯洗剤 | 30 |
| 柔軟剤 | 45 |
| ラップ | 30 |
| アルミホイル | 60 |
| トイレットペーパー | 14 |
| ティッシュペーパー | 14 |
| キッチンスポンジ | 30 |
| ハンドソープ | 30 |
| 浄水器カートリッジ | 90 |

**車モード:**
| 名前 | 周期（日） |
|------|-----------|
| エンジンオイル | 180 |
| オイルフィルター | 365 |
| ワイパーゴム | 365 |
| エアコンフィルター | 365 |
| タイヤ（交換目安） | 1095 |
| バッテリー | 730 |
| ウォッシャー液 | 90 |
| ブレーキパッド | 1460 |

**ガジェットモード:**
| 名前 | 周期（日） |
|------|-----------|
| 乾電池（リモコン等） | 180 |
| プリンターインク | 90 |
| エアコンフィルター | 90 |
| 空気清浄機フィルター | 365 |
| 掃除機フィルター | 180 |
| 電動歯ブラシ替えブラシ | 90 |
| シェーバー替刃 | 365 |

#### テンプレートからの追加フロー

1. 「テンプレートから追加」ボタンタップ
2. 現在のモードに対応するテンプレート一覧表示
3. 選択 → ItemFormView にプリセット値を埋めた状態で遷移
4. ユーザーが周期等を調整 → 保存

#### カスタムテンプレート（有料機能）

- ユーザーが自分のテンプレートを作成・保存
- 既存アイテムから「テンプレートとして保存」

### 1-4. 買い物リスト

#### 機能

- 期限切れ + そろそろ のアイテムを自動抽出
- 手動で「買い物リストに追加」も可能
- チェックボックスで購入済みマーク → 「買った！」処理と連動
- モード横断で表示（全モードのアイテムを一覧）

#### データモデル: `ShoppingListEntry`

```swift
struct ShoppingListEntry: Codable, Identifiable {
    var id: UUID
    var itemId: UUID                    // 紐づく Item
    var addedAt: Date
    var isChecked: Bool
    var checkedAt: Date?
}
```

#### 画面

| 画面 | 説明 |
|------|------|
| ShoppingListView | 買い物リスト。未チェック→チェック済みの順で表示 |

- チェック時: 確認ダイアログ → Item の「買った！」処理を実行 → リストから除外
- 無料プラン: 選択中の1モードのみ表示
- 有料プラン: 全モード横断表示

### 1-5. ローカル通知

#### 通知タイミング

- `nextDueDate - notificationDaysBefore` の朝9:00にスケジュール
- アイテムごとに個別の通知ID（`item.id.uuidString`）

#### 通知内容

```
タイトル: そろそろ○○
本文: ○○の交換時期が近づいています（あと○日）
カテゴリ: SOROSORO_REMINDER
```

#### 通知アクション

| アクション | 説明 |
|------------|------|
| 「買った！」 | 通知から直接購入完了処理 |
| 「あとで」 | 通知を消すのみ |

#### 制限

- 無料: 通知は最大5アイテムまで
- 有料: 無制限
- iOS上限（64件）を超える場合は次回予定日が近い順に優先

### 1-6. データ保存

#### 方式: JSON + App Group（既存アプリと同パターン）

- `group.com.mankai.sorosoro` App Group
- ファイル:
  - `items.json` — Item 配列
  - `shopping_list.json` — ShoppingListEntry 配列
  - `custom_templates.json` — ユーザー作成テンプレート
  - `settings.json` — アプリ設定（選択中モード等）

#### Store クラス

```swift
class ItemStore: ObservableObject {
    @Published var items: [Item] = []
    // Atomic write（shimedoki パターン）
    // Phase 2 で App Group 経由 watchOS 共有
}
```

### 1-7. StoreKit 2 サブスク

#### プラン構成

| プラン | 価格 | Product ID |
|--------|------|------------|
| 無料 | ¥0 | — |
| Plus 月額 | ¥280/月 | sorosoro.plus.monthly |
| Plus 年額 | ¥2,800/年 | sorosoro.plus.yearly |

#### 無料 vs Plus 制限

| 機能 | 無料 | Plus |
|------|------|------|
| 利用モード数 | 1モード | 全モード |
| アイテム登録数 | 10件/モード | 無制限 |
| 通知アイテム数 | 5件 | 無制限 |
| カスタムテンプレート | 不可 | 可 |
| 買い物リスト表示 | 選択モードのみ | 全モード横断 |
| アイテムメモ | 不可 | 可 |

#### 実装パターン

- `PlanService`（shimedoki パターン踏襲）
- `isPro` で判定
- Paywall トリガー: モード切替時 / 登録上限到達時 / カスタムテンプレート作成時

### 1-8. アプリ設定

| 項目 | 説明 |
|------|------|
| 選択中モード | 無料ユーザーのアクティブモード |
| 通知 ON/OFF（全体） | 通知の一括制御 |
| デフォルト通知日数 | 新規アイテムの通知デフォルト（初期値: 3日前） |

---

## Phase 2: watchOS Companion App

### 2-1. 概要

- iPhone 側で登録したアイテムを watchOS で確認
- 「買った！」をWatch側から実行可能
- 買い物リストの閲覧・チェック

### 2-2. Watch 画面構成

| 画面 | 説明 |
|------|------|
| WatchHomeView | 「そろそろ」「期限切れ」アイテムのサマリー |
| WatchItemListView | モード別アイテム一覧（残日数表示） |
| WatchShoppingListView | 買い物リスト（チェック可） |

### 2-3. データ同期

- App Group 共有ストレージ（ベース）
- WatchConnectivity（`WCSession`）でリアルタイム同期
  - iPhone → Watch: `transferUserInfo` でアイテム更新を送信
  - Watch → iPhone: 「買った！」を `sendMessage` で送信
- itami-techo の `WatchSyncService` パターン踏襲

### 2-4. Complication / Widget

- WidgetKit 対応
- 「次にそろそろなアイテム」を表示
- accessoryCircular: 残日数
- accessoryRectangular: アイテム名 + 残日数

### 2-5. 触覚通知

- 「そろそろ」アイテムの通知を Watch の触覚フィードバックで通知
- しめどき の WatchHapticService パターン踏襲

---

## Phase 3: Android（Kotlin / Jetpack Compose）

### 3-1. 概要

- iOS 版の機能をそのまま Kotlin/Jetpack Compose で再実装
- Android Studio エミュレータでデバッグ（実機なし）

### 3-2. 技術スタック

| 要素 | 技術 |
|------|------|
| UI | Jetpack Compose |
| データ保存 | Room（SQLite） |
| 通知 | AlarmManager + NotificationCompat |
| 課金 | Google Play Billing Library v7 |
| DI | Hilt |
| アーキテクチャ | MVVM + Repository |

### 3-3. データモデル（Room Entity）

```kotlin
@Entity(tableName = "items")
data class Item(
    @PrimaryKey val id: String,         // UUID
    val name: String,
    val mode: String,                   // "daily" | "car" | "gadget"
    val cycleDays: Int,
    val lastPurchaseDate: Long,         // epoch millis
    val nextDueDate: Long,
    val memo: String,
    val notificationEnabled: Boolean,
    val notificationDaysBefore: Int,
    val createdAt: Long,
    val updatedAt: Long
)
```

### 3-4. 画面構成

iOS版と同等:

| 画面 | Composable |
|------|-----------|
| モード別一覧 | ItemListScreen |
| アイテム詳細 | ItemDetailScreen |
| 追加・編集 | ItemFormScreen |
| テンプレート選択 | TemplatePickerScreen |
| 買い物リスト | ShoppingListScreen |
| 設定 | SettingsScreen |
| Paywall | PaywallScreen |

### 3-5. 通知

- `AlarmManager.setExactAndAllowWhileIdle()` で正確なスケジュール
- `NotificationChannel`: `sorosoro_reminder`
- Android 13+ の通知パーミッション対応（`POST_NOTIFICATIONS`）

### 3-6. 課金

| プラン | Google Play Product ID |
|--------|----------------------|
| Plus 月額 | sorosoro.plus.monthly |
| Plus 年額 | sorosoro.plus.yearly |

- `BillingClient` + `ProductDetails` + `launchBillingFlow`
- `Purchase.PurchaseState.PURCHASED` で Pro 解放
- iOS 版と同一の制限テーブル適用

### 3-7. Android 固有の考慮事項

- バックグラウンド制限: `WorkManager` でバックアップ通知スケジュール
- Doze モード: `setExactAndAllowWhileIdle` で対応
- 画面回転: Compose の state hoisting で自動対応
- Material 3 / Dynamic Color 対応
- Edge-to-edge display 対応

---

## プロジェクト構成

### ディレクトリ構造（Phase 1 + Phase 2）

```
sorosoro/
├── SPEC.md                          # この仕様書
├── CLAUDE.md                        # Claude Code 向けガイド
├── project.yml                      # xcodegen 設定
├── Shared/
│   ├── Models/
│   │   ├── Item.swift
│   │   ├── Mode.swift
│   │   ├── ItemTemplate.swift
│   │   ├── ShoppingListEntry.swift
│   │   ├── AppSettings.swift
│   │   └── PlanLimits.swift
│   ├── Services/
│   │   ├── ItemStore.swift
│   │   ├── ShoppingListStore.swift
│   │   ├── TemplateStore.swift
│   │   ├── NotificationService.swift
│   │   ├── PlanService.swift
│   │   └── WatchSyncService.swift   # Phase 2
│   ├── Templates/
│   │   └── DefaultTemplates.swift
│   └── Constants.swift
├── Sorosoro/                        # iOS target
│   ├── App/
│   │   └── SorosoroApp.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── ItemListView.swift
│   │   ├── ItemDetailView.swift
│   │   ├── ItemFormView.swift
│   │   ├── TemplatePickerView.swift
│   │   ├── ShoppingListView.swift
│   │   ├── SettingsView.swift
│   │   └── PaywallView.swift
│   ├── ViewModels/
│   │   ├── ItemListViewModel.swift
│   │   └── ShoppingListViewModel.swift
│   └── Resources/
│       └── Assets.xcassets/
├── SorosoroWatch/                   # watchOS target (Phase 2)
│   ├── App/
│   │   └── SorosoroWatchApp.swift
│   ├── Views/
│   └── Resources/
├── SorosoroTests/
│   └── ItemStoreTests.swift
└── android/                         # Phase 3
    └── (Kotlin project)
```

### Bundle ID

- iOS: `com.mankai.sorosoro`
- watchOS: `com.mankai.sorosoro.watch`
- Android: `com.mankai.sorosoro`
- App Group: `group.com.mankai.sorosoro`

### xcodegen 設定

- iOS deployment target: 17.0
- watchOS deployment target: 10.0
- Swift version: 5.9
- Team: R7B3AEZ7TA

---

## UI / UX ガイドライン

### カラーパレット

- Primary: システムブルー（日用品モードカラーと兼用）
- 各モードカラー: 上記テーブル参照
- 期限切れ: .red
- そろそろ: .orange
- 大丈夫: .green（進捗バー）

### アイコン

- AppIcon: 家のシルエット + リマインダーベル（or タイマー的な要素）
- SF Symbols 活用: clock.arrow.circlepath, bell.fill, cart.fill, checkmark.circle.fill

### ナビゲーション

```
TabView
├── [モード1] ItemListView
├── [モード2] ItemListView（Plus のみ）
├── [モード3] ItemListView（Plus のみ）
├── 買い物リスト ShoppingListView
└── 設定 SettingsView
```

### ダークモード

- 完全対応（SwiftUI デフォルト + Asset Catalog）

---

## マイルストーン

### Phase 1（iOS MVP） — 目標: 2〜3週間

| # | タスク | 優先度 |
|---|--------|--------|
| 1 | プロジェクト初期化（xcodegen, Assets, 基本構造） | P0 |
| 2 | Mode enum + Item / ItemTemplate モデル | P0 |
| 3 | ItemStore（JSON 永続化） | P0 |
| 4 | DefaultTemplates | P0 |
| 5 | ItemListView（モード別一覧 + ステータス表示） | P0 |
| 6 | ItemFormView（新規追加 / 編集） | P0 |
| 7 | ItemDetailView（詳細 + 「買った！」） | P0 |
| 8 | TemplatePickerView | P0 |
| 9 | ShoppingListView + ShoppingListStore | P0 |
| 10 | NotificationService（ローカル通知） | P0 |
| 11 | TabView + ContentView 統合 | P0 |
| 12 | PlanService（StoreKit 2） | P1 |
| 13 | PaywallView | P1 |
| 14 | SettingsView | P1 |
| 15 | 無料 / Plus 制限の適用 | P1 |
| 16 | テスト | P1 |

### Phase 2（watchOS） — 目標: 1〜2週間

| # | タスク | 優先度 |
|---|--------|--------|
| 1 | watchOS target 追加（project.yml） | P0 |
| 2 | WatchSyncService | P0 |
| 3 | WatchHomeView | P0 |
| 4 | WatchItemListView | P0 |
| 5 | WatchShoppingListView | P0 |
| 6 | 触覚通知 | P1 |
| 7 | Complication / Widget | P1 |

### Phase 3（Android） — 目標: 2〜3週間

| # | タスク | 優先度 |
|---|--------|--------|
| 1 | Android Studio プロジェクト初期化 | P0 |
| 2 | Room Entity + DAO | P0 |
| 3 | Repository + ViewModel | P0 |
| 4 | 画面実装（Compose） | P0 |
| 5 | 通知実装（AlarmManager） | P0 |
| 6 | Google Play Billing | P1 |
| 7 | Material 3 テーマ調整 | P1 |
| 8 | ストア公開準備 | P1 |
