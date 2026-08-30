# Vrav Pass Browser Extension (Chrome / Chromium / Yandex)

Manifest V3 extension.

## Load for development

1. Open `chrome://extensions` (or `browser://extensions` in Yandex).
2. Enable **Developer mode**.
3. **Load unpacked** → select this folder (`extensions/chrome`).

> Icons are currently missing. Add simple PNGs named `icon16.png`, `icon48.png`, `icon128.png` into `icons/` or temporarily remove the icons section from `manifest.json`.

## Roadmap

- Native Messaging host (talk to Flutter app)
- Autofill
- Bookmarks manager
- Local encrypted cache of vault subset
