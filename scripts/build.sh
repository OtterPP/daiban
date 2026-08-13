#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild \
  -project Daiban.xcodeproj \
  -scheme Daiban \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath build \
  build
echo
echo "构建完成：build/Build/Products/Release/Daiban.app"
echo "运行：open build/Build/Products/Release/Daiban.app"
