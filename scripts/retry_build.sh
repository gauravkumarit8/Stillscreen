#!/usr/bin/env bash
# Runs a build command. If it fails because a download was cut off or corrupted
# (this happens now and then on the build machines), clears any half-installed
# Android tools and tries again, up to 3 times. A real compile error is never
# retried, so it still fails quickly.
#
# Usage: bash scripts/retry_build.sh flutter build apk --debug
set -uo pipefail

MAX_ATTEMPTS=3
LOG="${RUNNER_TEMP:-/tmp}/build_attempt.log"
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"

# Text that means "the network or a download failed", not "your code is wrong".
DOWNLOAD_PROBLEMS='Error reading Zip content|SeekableByteChannel|Unexpected end of ZLIB|Premature end of Content-Length|Read timed out|Connection reset|Connection timed out|Could not GET|Could not HEAD|Received fatal alert|SSLException|Remote host terminated|Failed to download|sdkmanager.*non-zero'

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  "$@" 2>&1 | tee "$LOG"
  status=${PIPESTATUS[0]}
  if [ "$status" -eq 0 ]; then
    exit 0
  fi

  if ! grep -qiE "$DOWNLOAD_PROBLEMS" "$LOG"; then
    echo "The build failed for a reason that is not a download problem. Not retrying."
    exit "$status"
  fi

  if [ "$attempt" -eq "$MAX_ATTEMPTS" ]; then
    break
  fi

  echo "::warning::A download failed on attempt $attempt of $MAX_ATTEMPTS. Clearing half-installed tools and trying again."

  # A corrupted NDK zip leaves a broken folder that would fail the next try too.
  ndk_version="$(grep -oE 'NDK \(Side by side\) [0-9.]+' "$LOG" | head -n 1 | awk '{print $NF}')"
  if [ -n "$SDK" ] && [ -n "$ndk_version" ]; then
    echo "Removing partial NDK $ndk_version"
    rm -rf "$SDK/ndk/$ndk_version"
  fi
  [ -n "$SDK" ] && rm -rf "$SDK/.temp" 2>/dev/null

  sleep $(( attempt * ${RETRY_SLEEP_SECONDS:-15} ))
done

echo "The build still failed after $MAX_ATTEMPTS attempts because of download problems."
exit 1
