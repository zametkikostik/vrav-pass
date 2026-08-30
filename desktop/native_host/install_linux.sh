#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
HOST_SCRIPT="$ROOT/vrav_host.py"
chmod +x "$HOST_SCRIPT"

EXT_ID="${1:-}"
if [[ -z "$EXT_ID" ]]; then
  echo "Usage: $0 <chrome-extension-id>"
  echo "Find ID on chrome://extensions (Developer mode)"
  exit 1
fi

TARGET_DIR="${HOME}/.config/google-chrome/NativeMessagingHosts"
mkdir -p "$TARGET_DIR"

MANIFEST="$TARGET_DIR/com.vravpass.host.json"
cat > "$MANIFEST" <<EOF
{
  "name": "com.vravpass.host",
  "description": "Vrav Pass native messaging host",
  "path": "$HOST_SCRIPT",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://${EXT_ID}/"
  ]
}
EOF

# Chromium / Yandex variants
for d in \
  "${HOME}/.config/chromium/NativeMessagingHosts" \
  "${HOME}/.config/yandex-browser/NativeMessagingHosts"
do
  if [[ -d "$(dirname "$d")" ]]; then
    mkdir -p "$d"
    cp "$MANIFEST" "$d/"
    echo "Installed: $d/com.vravpass.host.json"
  fi
done

echo "Installed: $MANIFEST"
echo "Reload the extension, then Options → Test native host"
