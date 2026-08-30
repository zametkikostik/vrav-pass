#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Flutter create (android + desktop)"
flutter create . --org com.vravpass --project-name vrav_pass \
  --platforms=android,linux,windows,macos

echo "==> pub get"
flutter pub get

echo "==> Patch AndroidManifest for biometrics (if missing)"
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [[ -f "$MANIFEST" ]] && ! grep -q "USE_BIOMETRIC" "$MANIFEST"; then
  if grep -q "<application" "$MANIFEST"; then
    sed -i.bak 's|<application|<uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n    <uses-permission android:name="android.permission.INTERNET"/>\n    <application|' "$MANIFEST" || true
    echo "Patched $MANIFEST"
  fi
fi

echo "==> Done."
echo "  Mobile:  flutter run"
echo "  Desktop: flutter run -d linux   # or windows / macos"
echo "  APK:     flutter build apk --release --split-per-abi"
