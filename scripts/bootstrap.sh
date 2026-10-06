#!/usr/bin/env bash
# Generates the Flutter/Android boilerplate, then lays our source on top of it.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -d android ]; then
  flutter create --org app.stillscreen --project-name focus --platforms android,web .
fi

cp -r overlay/. .
rm -f test/widget_test.dart
flutter pub get
flutter analyze || true
echo "Bootstrap complete."
