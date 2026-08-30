# Vrav Pass

**Sovereign Password, Notes & Bookmarks Manager**

Offline-first · Zero-knowledge · Serverless · Post-quantum ready · Multi-language

[![Build APK](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml/badge.svg)](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml)

## Features (planned / in progress)

- **Fully offline** local encrypted vault (no our servers)
- Strong cryptography:
  - Argon2id key derivation
  - AES-256-GCM / ChaCha20-Poly1305
  - Hybrid key exchange: X25519 + ML-KEM-768 (post-quantum)
  - Hybrid signatures: Ed25519 + ML-DSA
- Passwords, Secure Notes, Bookmarks
- Optional E2EE sync to **your** cloud storage (Google Drive, Yandex Disk, WebDAV, local folder)
- Browser extensions (Chrome, Yandex, Edge, Firefox…)
- Multi-language: **Russian, English, Bulgarian, Thai**
- Android APK built via GitHub Actions

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Project Structure

```
vrav-pass/
├── mobile/          # Flutter app (Android primary, later iOS/Desktop)
├── extensions/      # Browser extensions (MV3)
├── docs/            # Architecture & crypto design
├── .github/         # CI: APK build
└── shared/          # Shared crypto / formats (future)
```

## Current Status (2026-08-30)

- ✅ Repository initialized
- ✅ Architecture document
- ✅ Flutter project skeleton + Riverpod + easy_localization (4 languages)
- ✅ Crypto engine foundation (Argon2id + AES-256-GCM)
- ✅ Vault data models (Password / Note / Bookmark)
- ✅ Basic UI + language switcher
- ✅ Chrome/Yandex MV3 extension scaffold
- ✅ GitHub Actions workflow for APK
- ⏳ Need to run `flutter create .` inside `mobile/` once to generate platform folders
- ⏳ Full vault unlock / create flow
- ⏳ Local encrypted storage
- ⏳ Cloud E2EE sync
- ⏳ Autofill + Native Messaging

## Quick start (developers)

```bash
git clone https://github.com/zametkikostik/vrav-pass.git
cd vrav-pass/mobile
flutter create . --org com.vravpass --project-name vrav_pass
flutter pub get
flutter run
```

## License

MIT (see LICENSE)
