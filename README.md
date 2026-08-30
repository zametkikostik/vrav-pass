# Vrav Pass

**Sovereign password, notes & bookmarks manager.**  
Offline-first · Zero-knowledge · No our servers · Your cloud, your keys

[![Build APK](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml/badge.svg)](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Status:** public **beta** (`0.1.0-beta`). Careful daily use OK.  
> Read [Security](#security-model) before high-value secrets.  
> **Русский:** [На русском](#на-русском) · [User guide](docs/USER_GUIDE.md)

---

## What is this?

Local-first vault for **passwords**, **secure notes**, and **bookmarks**.

| | |
|--|--|
| **No Vrav backend** | No account on our servers — nothing to leak from us |
| **Encryption** | Argon2id → AES-256-GCM (`vault.v1.enc`) |
| **Sync** | Optional: your WebDAV / Google Drive App Data / file — **ciphertext only** |
| **Browsers** | Chrome, Yandex, Firefox (temporary) extension + autofill |
| **Languages** | Russian, English, Bulgarian, Thai |

---

## What it is *not*

- Not a hosted cloud password service
- Not formally audited (yet)
- Not post-quantum until you ship `liboqs` ([docs/PQ_CRYPTO.md](docs/PQ_CRYPTO.md))
- **Forgot master password = data gone** (by design)

---

## Features (beta)

| Feature | Status |
|---------|--------|
| Local encrypted vault | ✅ |
| Passwords / notes / bookmarks | ✅ |
| Search, type filters, favorites | ✅ |
| Password generator + TOTP | ✅ |
| Clipboard auto-clear (45s) | ✅ |
| Auto-lock + biometrics | ✅ |
| Import Bitwarden JSON/CSV | ✅ |
| Import Chrome password CSV | ✅ |
| WebDAV E2EE sync | ✅ |
| Google Drive E2EE (your OAuth) | ✅ |
| File backup `.enc` | ✅ |
| Extension autofill (Chrome/Yandex/Firefox) | ✅ |
| Desktop native host ↔ app | ✅ |
| Hybrid KEM / liboqs scaffold | ✅ |
| Prebuilt liboqs in APK | 📋 optional |
| iOS | 📋 |
| Chrome Web Store / AMO signed | 📋 |

---

## Security model

```
Master password → Argon2id → DEK → AES-256-GCM vault file
```

- Disk & cloud: ciphertext only
- Memory: keys while unlocked; auto-lock / biometrics optional
- Report issues: [SECURITY.md](SECURITY.md)

---

## Quick start

### Android

```bash
git clone https://github.com/zametkikostik/vrav-pass.git
cd vrav-pass/mobile
chmod +x scripts/bootstrap.sh && ./scripts/bootstrap.sh
flutter run
# release:
flutter build apk --release --split-per-abi
```

Tagged releases (`v0.1.0-beta`) publish APKs via GitHub Actions.

### Browser extension

- **Chrome / Yandex:** load unpacked → `extensions/chrome`
- **Firefox:** `about:debugging` → temporary add-on → `extensions/chrome/manifest.json`

### Desktop host (Linux)

```bash
flutter run -d linux   # unlock vault
./desktop/native_host/install_linux.sh <EXTENSION_ID>
```

[docs/USER_GUIDE.md](docs/USER_GUIDE.md) · [docs/DESKTOP_HOST.md](docs/DESKTOP_HOST.md)

---

## Docs

| Doc | Topic |
|-----|--------|
| [USER_GUIDE.md](docs/USER_GUIDE.md) | End users EN/RU |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Design |
| [SYNC.md](docs/SYNC.md) · [GOOGLE_DRIVE.md](docs/GOOGLE_DRIVE.md) | Sync |
| [EXTENSION.md](docs/EXTENSION.md) · [DESKTOP_HOST.md](docs/DESKTOP_HOST.md) | Browser / host |
| [PQ_CRYPTO.md](docs/PQ_CRYPTO.md) | Post-quantum |
| [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) | Ship |
| [CHANGELOG.md](CHANGELOG.md) | Versions |

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md) — PRs welcome.

## License

[MIT](LICENSE)

---

## На русском

**Vrav Pass** — офлайн-менеджер **паролей, заметок и закладок** без наших серверов.

- Шифрование на устройстве (Argon2id + AES-256-GCM)
- Синк только шифротекста (WebDAV / Google Drive / файл)
- Импорт из Bitwarden и Chrome
- Расширение для Chrome / Yandex / Firefox
- Языки: русский, English, български, ไทย

**Важно:** мастер-пароль не восстанавливается.  
**Статус:** публичная бета `0.1.0-beta`.

Как пользоваться: [docs/USER_GUIDE.md](docs/USER_GUIDE.md).
