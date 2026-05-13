#!/bin/bash
# TestFlight アップロードスクリプト
# 使い方: bash scripts/upload_testflight.sh [ipa_path]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_CREDENTIALS="$SCRIPT_DIR/../../.credentials"  # side_job/.credentials
LOCAL_CREDENTIALS="$SCRIPT_DIR/../.credentials"

if [[ -f "$SHARED_CREDENTIALS" ]]; then
  source "$SHARED_CREDENTIALS"
elif [[ -f "$LOCAL_CREDENTIALS" ]]; then
  source "$LOCAL_CREDENTIALS"
else
  echo "ERROR: .credentials が見つかりません"
  echo "  side_job/.credentials または Sorosoro/.credentials を用意してください"
  exit 1
fi

IPA_PATH="${1:-/tmp/Sorosoro_export/Sorosoro.ipa}"

if [[ -z "${APP_SPECIFIC_PASSWORD:-}" ]]; then
  echo "ERROR: APP_SPECIFIC_PASSWORD が未設定です"
  echo "  side_job/.credentials に入力してください"
  echo "  発行: https://appleid.apple.com → サインインとセキュリティ → アプリ用パスワード"
  exit 1
fi

if [[ ! -f "$IPA_PATH" ]]; then
  echo "ERROR: IPA が見つかりません: $IPA_PATH"
  echo "  Xcode → Archive → Distribute App → App Store Connect で書き出してください"
  exit 1
fi

echo "==> IPA: $IPA_PATH"
echo "==> Apple ID: $APPLE_ID"
echo "==> TestFlight へアップロード中..."

xcrun altool \
  --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --username "$APPLE_ID" \
  --password "$APP_SPECIFIC_PASSWORD"

echo "==> 完了。App Store Connect の TestFlight で処理完了を待ってください"
