# Vrav Pass

**Sovereign Password, Notes & Bookmarks Manager**

Offline-first · Zero-knowledge · Serverless · Post-quantum ready · Multi-language

[![Build APK](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml/badge.svg)](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml)

## Features

| Feature | Status |
|---------|--------|
| Offline encrypted vault (Argon2id + AES-256-GCM) | ✅ |
| Passwords / Notes / Bookmarks CRUD | ✅ |
| Password generator | ✅ |
| TOTP (2FA) codes | ✅ |
| Auto-lock + biometric unlock | ✅ |
| WebDAV E2EE sync (Yandex Disk, Nextcloud…) | ✅ |
| File export / import (`.enc`) | ✅ |
| Browser extension (Chrome/Yandex) + autofill | ✅ |
| Google Drive App Data (scaffold) | 🧩 |
| Post-quantum hybrid KEM | 📋 |
| Desktop Native Messaging | 📋 |

Languages: **Russian, English, Bulgarian, Thai**

## Architecture

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — crypto & design
- [docs/SYNC.md](docs/SYNC.md) — WebDAV / file sync
- [docs/GOOGLE_DRIVE.md](docs/GOOGLE_DRIVE.md) — Drive setup
- [docs/EXTENSION.md](docs/EXTENSION.md) — browser extension

## Project structure

```
vrav-pass/
├── mobile/           # Flutter app
├── extensions/chrome # MV3 extension
├── docs/
└── .github/workflows # APK CI
```

## Quick start

```bash
git clone https://github.com/zametkikostik/vrav-pass.git
cd vrav-pass/mobile
chmod +x scripts/bootstrap.sh && ./scripts/bootstrap.sh
# or:
# flutter create . --org com.vravpass --project-name vrav_pass
# flutter pub get
flutter run
```

Build APK:

```bash
flutter build apk --release --split-per-abi
```

CI runs the same on every push to `main` (auto `flutter create` if `android/` is absent).

## Browser extension

```
chrome://extensions → Developer mode → Load unpacked → extensions/chrome
```

See [extensions/chrome/README.md](extensions/chrome/README.md).

## Security model (short)

- No Vrav servers
- Master password → Argon2id → DEK
- Vault on disk = AES-256-GCM ciphertext only
- Cloud = same ciphertext
- Biometric unlock stores DEK in platform secure storage after first password unlock

## License

MIT — see [LICENSE](LICENSE)
