# Changelog

## [0.1.0-beta] — 2026-08-31

### Added

- Flutter mobile app: create/unlock vault (Argon2id + AES-256-GCM)
- Passwords, notes, bookmarks CRUD
- Password generator, TOTP display
- Auto-lock and biometric unlock
- WebDAV E2EE sync, encrypted file export/import
- Google Drive App Data sync (optional OAuth client)
- Chrome/Yandex MV3 extension with autofill
- Desktop Native Messaging host + localhost vault API
- Hybrid KEM scaffold (X25519 + ML-KEM-768 / liboqs FFI)
- Vault search, type filters, favorites
- Secure clipboard auto-clear (45s)
- Import hub: **Bitwarden** JSON/CSV + **Chrome** password CSV
- Onboarding copy on home screen
- i18n: Russian, English, Bulgarian, Thai
- GitHub Actions APK build + tagged Release workflow

### Security notes

- Post-quantum path inactive unless native liboqs is present
- Extension JSON import remains a temporary plaintext bridge

### Known limitations

- iOS not packaged
- Encrypted Bitwarden exports not supported
- Sync conflicts are manual (upload/download)
