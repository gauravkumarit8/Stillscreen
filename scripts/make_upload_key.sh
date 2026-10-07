#!/usr/bin/env bash
# Creates the upload keystore and android/key.properties (both stay out of git).
set -euo pipefail
cd "$(dirname "$0")/.."

KEYSTORE="$HOME/stillscreen-upload.jks"
if [ -f "$KEYSTORE" ]; then
  echo "A keystore already exists at $KEYSTORE. Not overwriting it."
  exit 1
fi

read -r -p "Your full name (no commas): " NAME
read -r -p "Two-letter country code, for example IN: " COUNTRY
read -r -s -p "Choose a keystore password (letters and numbers only, 8+ characters): " PASS; echo
read -r -s -p "Repeat the password: " PASS2; echo
if [ "$PASS" != "$PASS2" ]; then
  echo "Passwords do not match."
  exit 1
fi

keytool -genkeypair -v \
  -keystore "$KEYSTORE" -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASS" \
  -dname "CN=$NAME, O=Stillscreen, C=$COUNTRY"

printf 'storePassword=%s\nkeyPassword=%s\nkeyAlias=upload\nstoreFile=%s\n' \
  "$PASS" "$PASS" "$KEYSTORE" > android/key.properties
chmod 600 "$KEYSTORE" android/key.properties

echo
echo "Created $KEYSTORE and android/key.properties."
echo "NEXT: download $KEYSTORE from the Codespace and save it with your password"
echo "somewhere safe outside GitHub (password manager or private drive)."
