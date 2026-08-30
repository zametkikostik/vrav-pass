# Vrav Pass

**Sovereign Password, Notes & Bookmarks Manager**

Offline-first · Zero-knowledge · Serverless · Post-quantum ready · Multi-language

[![Build APK](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml/badge.svg)](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml)

## Features

| Feature | Status |
|---------|--------|
| Offline vault (Argon2id + AES-256-GCM) | ✅ |
| Passwords / Notes / Bookmarks | ✅ |
| Password generator + TOTP | ✅ |
| Auto-lock + biometrics | ✅ |
| WebDAV E2EE (Yandex, Nextcloud…) | ✅ |
| Google Drive App Data E2EE | ✅ (needs your OAuth client) |
| Chrome/Yandex extension + autofill | ✅ |
| Desktop Native Messaging + local API | ✅ |
| Hybrid KEM X25519 + ML-KEM-768 API | ✅ |
| liboqs `.so` shipped in APK | 📋 optional build |
| Languages RU / EN / BG / TH | ✅ |

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Sync](docs/SYNC.md) · [Google Drive](docs/GOOGLE_DRIVE.md)
- [Extension](docs/EXTENSION.md) · [Desktop host](docs/DESKTOP_HOST.md)
- [PQ crypto](docs/PQ_CRYPTO.md) · [Android liboqs](mobile/android_liboqs/README.md)
- [Release checklist](docs/RELEASE_CHECKLIST.md)

## Quick start

```bash
git clone https://github.com/zametkikostik/vrav-pass.git
cd vrav-pass/mobile
chmod +x scripts/bootstrap.sh && ./scripts/bootstrap.sh
flutter run                  # device / emulator
flutter run -d linux         # desktop bridge for browser host
```

```bash
flutter build apk --release --split-per-abi
```

Extension: `chrome://extensions` → Load unpacked → `extensions/chrome`

## Security (short)

- No Vrav servers
- Master password → Argon2id → DEK; disk/cloud = ciphertext only
- Biometrics wrap DEK in OS secure storage
- PQ: real only when `liboqs` is present (`isPostQuantumNative`)

## License

MIT — [LICENSE](LICENSE)
