#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Flutter create (preserve existing lib/pubspec)"
flutter create . --org com.vravpass --project-name vrav_pass --platforms=android,ios

echo "==> pub get"
flutter pub get

echo "==> Patch AndroidManifest for biometrics (if missing)"
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [[ -f "$MANIFEST" ]] && ! grep -q "USE_BIOMETRIC" "$MANIFEST"; then
  # Insert permissions before <application
  if grep -q "<application" "$MANIFEST"; then
    sed -i.bak 's|<application|<uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n    <uses-permission android:name="android.permission.INTERNET"/>\n    <application|' "$MANIFEST" || true
    echo "Patched $MANIFEST"
  fi
fi

echo "==> Done. Run: flutter run"
echo "==> Build APK: flutter build apk --release --split-per-abi"
