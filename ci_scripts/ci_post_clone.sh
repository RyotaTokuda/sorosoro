#!/bin/sh
# Xcode Cloud: リポジトリの clone 直後に実行される
# project.yml から .xcodeproj を再生成し、コミット済みプロジェクトとの食い違いを防ぐ
set -e

# 実行時のカレントは ci_scripts/ なのでリポジトリルートへ移動する
cd "${CI_PRIMARY_REPOSITORY_PATH:-$CI_WORKSPACE}"

# Xcode Cloud のイメージに xcodegen は入っていないので必要なら導入する
if ! command -v xcodegen >/dev/null 2>&1; then
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_INSTALL_CLEANUP=1
  brew install xcodegen
fi

xcodegen --version
xcodegen generate
