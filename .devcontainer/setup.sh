#!/usr/bin/env bash
# Installs Flutter + Android command-line tools inside the Codespace.
set -euo pipefail

FLUTTER_DIR="$HOME/flutter"
ANDROID_HOME="$HOME/android-sdk"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  curl -fsSL -o /tmp/cmdtools.zip \
    https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q /tmp/cmdtools.zip -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi

export ANDROID_HOME ANDROID_SDK_ROOT="$ANDROID_HOME"
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null || true
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "platform-tools"

if ! grep -q "# stillscreen-env" ~/.bashrc; then
  cat >> ~/.bashrc <<EOT
# stillscreen-env
export PATH="$FLUTTER_DIR/bin:$ANDROID_HOME/platform-tools:\$PATH"
export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
EOT
fi

flutter config --no-analytics --android-sdk "$ANDROID_HOME"
flutter precache --android --web
echo "Done. Open a new terminal, then run: bash scripts/bootstrap.sh"
