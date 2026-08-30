# Changelog

All notable changes to Vrav Pass are documented here.

## [0.1.0-beta] — 2026-08-30

### Added

- Flutter mobile app: create/unlock vault (Argon2id + AES-256-GCM)
- Passwords, notes, bookmarks CRUD
- Password generator, TOTP display
- Auto-lock and biometric unlock
- WebDAV E2EE sync, encrypted file export/import
- Google Drive App Data sync (optional OAuth client)
- Chrome/Yandex MV3 extension with autofill and local vault cache
- Desktop Native Messaging host + localhost vault API
- Hybrid KEM scaffold (X25519 + ML-KEM-768 via liboqs FFI or stub)
- i18n: Russian, English, Bulgarian, Thai
- GitHub Actions APK build

### Security notes

- Post-quantum path is **not** active unless native liboqs is present
- Extension JSON import is a temporary bridge (plaintext at import time)

### Known limitations

- iOS not packaged
- No Bitwarden import yet
- Sync conflicts are manual (upload/download)
