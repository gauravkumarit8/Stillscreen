#!/usr/bin/env bash
# Checks the usual reasons a release bundle does not appear, then tries to build it.
# It never prints passwords. Paste the whole output if you need help.
cd "$(dirname "$0")/.." || exit 1

echo "=== machine ==="
df -h . | tail -1 | awk '{print "disk free: " $4 " (" $5 " used)"}'
free -m 2>/dev/null | awk 'NR==2 {print "memory: " $2 " MB total, " $7 " MB available"}'
flutter --version 2>/dev/null | head -1

echo
echo "=== version ==="
grep '^version:' pubspec.yaml

echo
echo "=== signing ==="
if [ -f android/key.properties ]; then
  echo "android/key.properties: present"
  store=$(grep '^storeFile=' android/key.properties | cut -d= -f2-)
  if [ -f "$store" ]; then echo "keystore file: present"; else echo "keystore file: MISSING at $store"; fi
  grep '^keyAlias=' android/key.properties
else
  echo "android/key.properties: MISSING (run scripts/make_upload_key.sh)"
fi
if grep -q "stillscreen-release-signing" android/app/build.gradle.kts 2>/dev/null; then
  echo "gradle signing patch: present"
else
  echo "gradle signing patch: MISSING (run python3 scripts/enable_release_signing.py)"
fi
grep -n "minSdk" android/app/build.gradle.kts

echo
echo "=== analyze ==="
flutter analyze --no-fatal-infos 2>&1 | tail -12

echo
echo "=== building the release bundle (this takes a few minutes) ==="
flutter build appbundle --release > /tmp/aab_build.log 2>&1
code=$?
echo "exit code: $code"
echo
echo "--- the lines that matter ---"
grep -n -E "^e: |error:|FAILURE|What went wrong|Execution failed|Lint found|OutOfMemory|Java heap|No space left|keystore|Keystore" /tmp/aab_build.log | head -30
echo
echo "--- last 25 lines ---"
tail -25 /tmp/aab_build.log
echo
if [ -f build/app/outputs/bundle/release/app-release.aab ]; then
  ls -la build/app/outputs/bundle/release/app-release.aab
  echo "signer:"
  keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | head -3
else
  echo "No .aab was produced. Full log: /tmp/aab_build.log"
fi
