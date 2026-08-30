# Vrav Pass Browser Extension

Chrome · Chromium · Yandex · Firefox (temporary load)

Manifest V3 · unlock · search · copy · autofill · native host ping

## Load — Chrome / Yandex

1. `chrome://extensions` or `browser://extensions`
2. Developer mode → **Load unpacked** → `extensions/chrome`

## Load — Firefox

1. `about:debugging#/runtime/this-firefox`
2. **Load Temporary Add-on** → `extensions/chrome/manifest.json`

See also [../firefox/README.md](../firefox/README.md).

## First-time setup

1. **Options** → paste JSON items + lock password → **Import & Lock**  
   (or use mobile export / desktop host)
2. Popup → unlock → autofill on login pages
3. Optional: **Test native host** (desktop)

### Example JSON

```json
[
  {
    "type": "password",
    "title": "GitHub",
    "username": "you@mail.com",
    "password": "secret",
    "url": "https://github.com"
  }
]
```

## Features (v0.4)

- PBKDF2-locked local cache + session unlock
- Search, copy, autofill by hostname
- Native Messaging client (`com.vravpass.host`)
- Options: import JSON, ping desktop host
- Gecko id for Firefox temporary installs

## Architecture

| Path | Status |
|------|--------|
| Extension encrypted cache | ✅ |
| Autofill | ✅ basic |
| Native Messaging ↔ Flutter desktop | ✅ when host + app unlocked |
| Same Argon2id as mobile on `.enc` | ⏳ Argon2 WASM |
| Signed AMO / Chrome Web Store | ⏳ |

Mobile remains source of truth for the vault.
