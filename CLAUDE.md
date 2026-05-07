# Sorosoro — 消耗品管理アプリ

## 概要
「そろそろ買い替え時」をローカル通知で知らせる消耗品管理アプリ。
日用品・車・ガジェットの3モード対応。

## 技術スタック
- iOS: Swift 5.9 / SwiftUI / iOS 17+
- データ保存: JSON + App Group（Codable, Atomic write）
- 課金: StoreKit 2（sorosoro.plus.monthly / sorosoro.plus.yearly）
- プロジェクト生成: xcodegen（project.yml）

## ディレクトリ構成
```
Shared/          # iOS/watchOS 共有コード
  Models/        # Item, Mode, ItemTemplate, ShoppingListEntry, AppSettings, PlanLimits
  Services/      # ItemStore, ShoppingListStore, TemplateStore, SettingsStore, PlanService, NotificationService
  Templates/     # DefaultTemplates（プリインストールテンプレート）
  Constants.swift
Sorosoro/        # iOS ターゲット
  App/           # SorosoroApp.swift
  Views/         # ContentView, ItemList, ItemDetail, ItemForm, TemplatePicker, ShoppingList, Settings, Paywall
SorosoroTests/   # テスト
```

## ビルド
```bash
xcodegen generate
xcodebuild -project Sorosoro.xcodeproj -scheme Sorosoro -destination 'generic/platform=iOS Simulator' build
```

## Bundle ID
- iOS: com.mankai.sorosoro
- App Group: group.com.mankai.sorosoro

## Phase
- Phase 1: iOS MVP ← 現在
- Phase 2: watchOS companion
- Phase 3: Android（Kotlin/Jetpack Compose）
