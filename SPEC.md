# 買いどき — 機能仕様書

> 最終更新: 2026-05-12  
> 対象バージョン: 1.0.0 (Build 3)

---

## 1. アプリ概要

消耗品の交換・買い替えタイミングを自動計算し通知する管理アプリ。  
iOS / watchOS 対応。CloudKit による家族共有機能付き。

---

## 2. モード

| モード | 内容 | 無料プラン |
|--------|------|-----------|
| 日用品 | シャンプー・洗剤・電池など生活消耗品 | 1モードのみ使用可 |
| カー用品 | エンジンオイル・タイヤ・ワイパーなど | Pro のみ |
| gadget | 内部定義のみ、UI では daily に統合 | — |

`Mode.allCases` は `[.daily, .car]` のみ返す。  
`gadget` アイテムは `effectiveMode` により `daily` として表示される。

---

## 3. データモデル

### 3-1. Item

| フィールド | 型 | 説明 |
|---|---|---|
| id | UUID | 主キー |
| name | String | アイテム名 |
| mode | Mode | 所属モード |
| cycleDays | Int | 交換周期（日） |
| lastPurchaseDate | Date | 最終購入日 |
| nextDueDate | Date | 次回交換推奨日（lastPurchaseDate + cycleDays） |
| memo | String | メモ（Pro のみ表示・編集可） |
| notificationEnabled | Bool | 通知 ON/OFF |
| notificationDaysBefore | Int | 何日前に通知するか（1〜30） |
| purchaseHistory | [Date] | 購入履歴（最大20件） |
| isShared | Bool | 共有ゾーンのアイテムか（transient、JSON保存対象外） |

**計算プロパティ:**
- `daysRemaining: Int` = `nextDueDate - today`（負=超過）
- `status: ItemStatus` = overdue（< 0）/ soon（0〜6）/ ok（7〜）

**サイクル自動最適化:**
- `suggestedCycleDays() -> Int?`
- 購入履歴が3件以上あり、平均間隔と現在の cycleDays の差が5日以上の場合に提案値を返す

### 3-2. ShoppingListEntry

| フィールド | 型 | 説明 |
|---|---|---|
| id | UUID | 主キー |
| itemId | UUID | 紐付くアイテムの ID |
| addedAt | Date | 追加日時 |
| isChecked | Bool | チェック済みか |
| checkedAt | Date? | チェック日時 |
| isShared | Bool | 共有フラグ（transient） |

### 3-3. UserProfile

| フィールド | 型 | 説明 |
|---|---|---|
| visibleModes | [Mode] | タブバーに表示するモード |
| adultsCount | Int | 大人の人数 |
| childrenCount | Int | 子どもの人数 |
| monthlyMileage | MonthlyMileage | 月間走行距離（low/medium/high） |
| vehicleType | VehicleType | 車種（gasoline/diesel/hev/ev） |
| hasCompletedOnboarding | Bool | オンボーディング完了フラグ |

**effectiveFamilyFactor:**
```
(adultsCount + childrenCount × 0.6) / 2.0
```
日用品の交換周期をこの係数で割ることで家族人数に応じた周期に調整する。

---

## 4. プラン制限

| 機能 | 無料 | Plus |
|---|---|---|
| アイテム登録数（モード別） | 10件 | 無制限 |
| 通知件数 | 5件 | 64件（iOS上限） |
| モード同時利用 | 1モードのみ | 全モード |
| カスタムテンプレート | 不可 | 可 |
| メモ機能 | 不可 | 可 |
| 買い物リスト全モード表示 | 不可（選択モードのみ） | 可 |
| CloudKit 家族共有 | 不可 | 可 |

**制限チェック実装箇所:**
- アイテム追加: `ItemListView` ツールバーで `planService.canAddItem(currentCount:)` をチェック
- テンプレート作成: `TemplatePickerView` の「カスタム追加」ボタン
- メモ: `ItemFormView` の memo フィールド
- 共有: `SharingView` の ShareButton

---

## 5. プリセットテンプレート

### 日用品（21件）
シャンプー(60d)、コンディショナー(60d)、ボディソープ(30d)、ハンドソープ(30d)、歯ブラシ(30d)、歯磨き粉(60d)、トイレットペーパー(14d)、洗濯洗剤(30d)、食器用洗剤(30d)、柔軟剤(30d)、キッチンペーパー(14d)、ラップ(30d)、スポンジ(30d)、電池(365d)、空気清浄機フィルター(365d)、冷蔵庫フィルター(180d)、コーヒーフィルター(30d)、生ゴミ袋(14d)、マスク(14d)、綿棒(60d)、ティッシュ(14d)

### カー用品（8件）
エンジンオイル(180d/5,000km)、エアフィルター(365d/15,000km)、ワイパー(365d/20,000km)、ブレーキパッド(730d/30,000km)、バッテリー(1,095d/45,000km)、タイヤ(1,095d/50,000km)、タイヤローテーション(180d/5,000km)、クーラント(730d/40,000km)

**周期調整ロジック:**
- 日用品: `cycleDays / effectiveFamilyFactor`（最小7日）
- カー用品: `min(日数基準, 走行距離ベース日数)` で短い方を採用

---

## 6. 通知

- スケジュール: `nextDueDate の notificationDaysBefore 日前の朝9時`
- タイトル: `{item.name}の交換時期です`
- 本文: `交換時期まであと{notificationDaysBefore}日です`
- 過去日付はスキップ（次回「買った！」後に再スケジュール）
- アプリがアクティブになるたびに全通知を再スケジュール
- 無料: 残日数が近い上位5件のみ / Plus: 上位64件

---

## 7. データ永続化

### JSON キャッシュ（App Group: group.com.mankai.sorosoro）
| ファイル | 内容 |
|---|---|
| items.json | ItemStore |
| shopping_list.json | ShoppingListStore |
| custom_templates.json | TemplateStore |
| settings.json | AppSettings / UserProfile |

共有アイテム（isShared = true）は JSON に保存しない（CloudKit から再取得）。

### CloudKit（iCloud.com.mankai.sorosoro）
- プライベート DB: 自分のデータ
- 共有 DB: 家族共有データ
- デルタ同期: serverChangeToken を UserDefaults に永続化
- レコード種別: Item / ShoppingListEntry / CustomTemplate

---

## 8. Watch 連携

### WatchConnectivity（リアルタイム）
| メッセージ type | 方向 | ペイロード |
|---|---|---|
| updateItem | 双方向 | Item を JSON エンコード |
| deleteItem | 双方向 | UUID |
| markPurchased | Watch → iPhone | UUID |

### Watch アプリ動作
- App Group JSON キャッシュを直接読み書き（iPhone と共有）
- CloudKit アクセスなし（iPhone 経由でのみ反映）
- 「買った！」: ローカル更新 → WatchConnectivity で iPhone に通知 → iPhone が CloudKit に反映

---

## 9. iOS 画面一覧

| 画面 | 役割 |
|---|---|
| ContentView | ZStack カスタムタブバー。オンボーディング未完了時は fullScreenCover |
| OnboardingView | 3ページ: ウェルカム / モード選択 / 家族構成+車設定 |
| ItemListView | アイテム一覧（残日数順）。追加・削除・ペイウォール制御 |
| ItemDetailView | 詳細。最適化提案・「買った！」・買い物リスト追加・編集 |
| ItemFormView | 新規作成・編集フォーム |
| ShoppingListView | 緊急候補 / 未チェック / 購入済みの3セクション |
| TemplatePickerView | プリセット + カスタムテンプレート一覧 |
| PaywallView | 機能比較・プラン選択・購入・復元 |
| SettingsView | プラン・モード・家族構成・通知・共有・バージョン |

---

## 10. watchOS 画面一覧

| 画面 | 役割 |
|---|---|
| WatchHomeView | 緊急上位5件 / カテゴリリンク / 買い物リストリンク |
| WatchItemListView | モード別一覧 |
| WatchItemDetailView | 詳細 + 「買った！」ボタン |
| WatchShoppingListView | 未チェックエントリ + 緊急候補 |

---

## 11. 既知の制限

- Watch からの「買った！」後、通知の再スケジュールは iPhone 側のみ
- 通知アクション「買った！」はフォアグラウンド起動のみ（バックグラウンド購入処理未実装）
- CloudKit 未接続時はオフラインキャッシュで動作（共有データは表示されない）
