#!/bin/sh
# Xcode Cloud: リポジトリの clone 直後に実行される
# project.yml から .xcodeproj を再生成し、コミット済みプロジェクトとの食い違いを防ぐ
set -e

# ローカル開発機と同じバージョンに固定する。
# brew install だと CI が最新版を拾い、ローカルと CI で生成結果がずれる事故が起きるため
# GitHub のリリース成果物を直接落として使う（約4MB・数秒）。
XCODEGEN_VERSION=2.45.3

TOOLS_DIR="$HOME/.tools/xcodegen-$XCODEGEN_VERSION"
if [ ! -x "$TOOLS_DIR/xcodegen/bin/xcodegen" ]; then
    mkdir -p "$TOOLS_DIR"
    curl -fsSL -o "$TOOLS_DIR/xcodegen.zip" \
        "https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"
    unzip -q -o "$TOOLS_DIR/xcodegen.zip" -d "$TOOLS_DIR"
fi
XCODEGEN="$TOOLS_DIR/xcodegen/bin/xcodegen"

# 実行時のカレントは ci_scripts/ なのでリポジトリルートへ移動する
cd "${CI_PRIMARY_REPOSITORY_PATH:-$CI_WORKSPACE}"

"$XCODEGEN" --version
"$XCODEGEN" generate
