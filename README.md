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

## Status

Currently scaffolding core architecture, crypto foundation and Flutter mobile app.

## License

MIT (see LICENSE)

## Contributing

PRs welcome after initial architecture is locked.
