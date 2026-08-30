# Browser Extension Architecture

## Why not Native Messaging on Android?

Chrome **Native Messaging** talks to a native host over stdio. That works well for **desktop** (Windows/Linux/macOS) where a Flutter desktop build can register a host.

On **Android**, Chrome/Yandex cannot use the same Native Messaging pipe to a Flutter APK. Therefore the mobile ↔ extension bridge is:

1. **E2EE file / WebDAV** (same ciphertext as the app)
2. **JSON import** into extension-local PBKDF2 vault (practical autofill today)
3. Future: **Argon2 WASM** to open mobile `vault.v1.enc` directly in the extension

## Data flow (current)

```
Mobile app  --export/WebDAV-->  ciphertext or JSON
                                      |
                                      v
                              Extension Options
                                      |
                          PBKDF2 + AES-GCM lock
                                      |
                              chrome.storage.local
                                      |
                         Unlock in popup (session)
                                      |
                         content.js autofill
```

## Security

- Session items kept in `chrome.storage.session` when available.
- Lock clears session.
- No Vrav servers.
- Host permissions required for autofill on all sites (standard for password managers).

## Desktop Native Messaging (roadmap)

1. Flutter desktop target registers `com.vravpass.host`.
2. Extension `nativeMessaging` permission + host manifest.
3. Messages: `getItemsForUrl`, `lock`, `status`.
4. Keys never leave the Flutter process; extension only receives filled fields or one-time secrets.
