# そろそろ — TestFlight アップロード手順

## 1. アプリ用パスワードを用意する

まだ発行していない場合:
1. https://appleid.apple.com にサインイン
2. **サインインとセキュリティ → アプリ用パスワード → +**
3. 名前（例: `altool`）を入力して生成

## 2. `.credentials` にパスワードを入力する

```
# Sorosoro/.credentials
APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx  ← ここに貼り付け
```

`.credentials` は `.gitignore` 済みなので**絶対にコミットしない**。

## 3. IPA を書き出す

Xcode → **Product → Archive** → **Distribute App → App Store Connect**
→ Export → `/tmp/Sorosoro_export/Sorosoro.ipa` に保存

## 4. アップロード

```bash
# リポジトリルートから実行
bash scripts/upload_testflight.sh

# IPA パスを指定する場合
bash scripts/upload_testflight.sh /path/to/Sorosoro.ipa
```

スクリプトが `.credentials` を自動で読み込み、`$APPLE_ID` と `$APP_SPECIFIC_PASSWORD` を使ってアップロードする。

## 5. App Store Connect で確認

https://appstoreconnect.apple.com → **TestFlight** → ビルドが表示されるまで数分待つ

---

## トラブル

| エラー | 対処 |
|--------|------|
| `APP_SPECIFIC_PASSWORD が未設定` | `.credentials` に値を入力したか確認 |
| `IPA が見つかりません` | Xcode で Archive → Export を先に行う |
| `Authentication failed` | アプリ用パスワードを再発行する |
| `No suitable application records` | App Store Connect でアプリのレコードを先に作成する |
