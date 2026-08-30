# Vrav Pass Browser Extension (Chrome / Chromium / Yandex)

Manifest V3 · unlock · search · copy · autofill

## Load for development

1. Open `chrome://extensions` (Yandex: `browser://extensions`).
2. Enable **Developer mode**.
3. **Load unpacked** → select `extensions/chrome`.

## First-time setup

1. Open **Options** (extension details → Extension options).
2. Paste JSON array of items (from mobile) and set a lock password.
3. Click **Import & Lock**.
4. Open popup → enter password → Unlock.

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

## Features (v0.2)

- Master-password unlock (PBKDF2-locked local cache)
- Session storage (cleared when browser session ends, when available)
- Search + copy username/password
- Autofill current tab login form
- Match passwords by site hostname

## Architecture note

| Path | Status |
|------|--------|
| Extension local encrypted cache | ✅ |
| Autofill | ✅ basic |
| Same Argon2id as mobile on `.enc` blob | ⏳ needs Argon2 WASM |
| Native Messaging ↔ Flutter (desktop) | ⏳ planned |
| WebDAV direct from extension | ⏳ planned |

Mobile remains source of truth. Extension cache is for browser autofill convenience.

## Yandex Browser

Same Chromium MV3 package — load unpacked identically.
