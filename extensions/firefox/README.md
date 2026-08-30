# Vrav Pass on Firefox

The extension sources live in **`../chrome`** (Manifest V3 + `browser_specific_settings.gecko`).

## Install (temporary / development)

1. Open `about:debugging#/runtime/this-firefox`
2. **Load Temporary Add-on…**
3. Select `extensions/chrome/manifest.json`

Firefox 121+ is required (MV3 service worker).

## Permanent install (unsigned)

For personal use you can use `about:config` → `xpinstall.signatures.required` = `false` on **Developer / Nightly** editions, then install a zipped package — not recommended for most users. Prefer temporary load or a signed AMO listing later.

## Pack for testing

```bash
cd extensions/chrome
zip -r ../firefox/vrav-pass-firefox.zip . -x '*.md'
```

Then load the zip via temporary add-on (Firefox accepts zip with manifest at root).

## Notes

- Same unlock / import / autofill flow as Chrome
- Native Messaging host on Linux: see `docs/DESKTOP_HOST.md` (Chrome-oriented; Firefox host path differs — TBD)
- Yandex Browser: use the Chrome package via `browser://extensions`
