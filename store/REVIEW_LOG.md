# 買いどき — App Store 審査ログ

> 共通ガイド → `/Users/ryotatokuda/side_job/store/APP_STORE_REVIEW_LOG.md`

## 提出前チェックリスト（このアプリ固有）

### IAP / サブスクリプション

- [ ] App Store Connect → 契約・税金・口座情報 → **Paid Apps Agreement が承認済み**か確認
- [ ] `sorosoro.plus.monthly` / `sorosoro.plus.yearly` を「審査へ提出」済み
- [ ] ペイウォール画面のスクリーンショットを IAP Review 用に登録済み
- [ ] Sandbox でサブスク購入・復元のフローテスト完了

### 必須 UI

- [ ] Settings → 「購入を復元」ボタンあり ✅（`settings.restore.purchases`）
- [ ] PaywallView のフッターに利用規約・プライバシーポリシーリンクあり ✅
- [ ] 無料でも日用品モード10件・通知5件まで使えること ✅

### アプリ固有の確認事項

- [ ] CloudKit 家族共有機能（Plus限定）が Sandbox 環境でテスト済み
- [ ] 通知権限を拒否してもクラッシュしないこと確認済み
- [ ] App Store Connect でアプリ名が **「買いどき」**（旧名「そろそろ」ではない）

### 審査メモ（Review Notes）に書くこと

`metadata-ja.md` の審査メモセクションを App Store Connect にそのまま貼り付ける。

---

## 審査提出履歴

| Build | 日付 | 結果 | 詳細 |
|-------|------|------|------|
| - | - | - | 初回提出前 |
