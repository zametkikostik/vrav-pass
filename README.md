# Vrav Pass

**Sovereign password, notes & bookmarks manager.**  
Offline-first · Zero-knowledge · No our servers · Your cloud, your keys

[![Build APK](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml/badge.svg)](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Status:** public **beta** (v0.1). Suitable for self-hosting enthusiasts and careful daily use.  
> Read [Security](#security-model) before storing high-value credentials.  
> **Русский:** [На русском](#на-русском) · [Руководство пользователя](docs/USER_GUIDE.md)

---

## What is this?

**Vrav Pass** is a local-first vault for:

| You store | Where it lives |
|-----------|----------------|
| Passwords (login, URL, notes, TOTP) | Encrypted file on your device |
| Secure notes | Same vault |
| Bookmarks | Same vault |

**We do not run a backend.** There is no Vrav account and nothing to “leak from our servers.”

Optional sync uploads **only ciphertext** to storage **you** control:

- WebDAV (Yandex Disk, Nextcloud, own server)
- Google Drive *Application Data* folder (bring your own OAuth client)
- Manual file export / import (`.enc`)

Browser extension (Chrome / Yandex) can autofill after unlock. On desktop, a Native Messaging host can talk to the unlocked Flutter app over localhost.

**Languages in the app:** Russian, English, Bulgarian, Thai.

---

## What it is *not*

- Not a company cloud password service (Bitwarden-cloud style)
- Not “unbreakable” / not audited by a big firm (yet)
- Not full post-quantum protection until you ship `liboqs` (see [docs/PQ_CRYPTO.md](docs/PQ_CRYPTO.md))
- If you **forget the master password**, data **cannot** be recovered — by design

---

## Security model

```
Master password
    → Argon2id
    → Master key / DEK
    → AES-256-GCM vault file (vault.v1.enc)
```

- **At rest:** only encrypted blob on disk
- **In cloud:** same blob; provider never gets plaintext from us
- **In memory:** keys while unlocked; auto-lock + optional biometrics
- **Threats we design for:** stolen phone backup, honest-but-curious cloud, casual malware
- **Threats we don’t fully stop alone:** targeted malware with root, evil keyboard, reusing the master password elsewhere

Report vulnerabilities: see [SECURITY.md](SECURITY.md).

---

## Quick start

### Android (developers)

```bash
git clone https://github.com/zametkikostik/vrav-pass.git
cd vrav-pass/mobile
chmod +x scripts/bootstrap.sh && ./scripts/bootstrap.sh
flutter run
```

Release APK:

```bash
flutter build apk --release --split-per-abi
```

CI builds APK on every push to `main`. **Tagged releases** (`v0.1.0`) publish APKs to GitHub Releases.

### Browser extension

1. `chrome://extensions` → Developer mode
2. **Load unpacked** → `extensions/chrome`
3. Options: import vault JSON (temporary bridge) **or** use desktop host

### Desktop + autofill host (Linux)

```bash
cd mobile && flutter run -d linux   # unlock vault
cd ../desktop/native_host
./install_linux.sh <YOUR_EXTENSION_ID>
```

Details: [docs/DESKTOP_HOST.md](docs/DESKTOP_HOST.md).

End users: [docs/USER_GUIDE.md](docs/USER_GUIDE.md).

---

## Features (beta)

- [x] Local encrypted vault (Argon2id + AES-256-GCM)
- [x] Passwords, notes, bookmarks
- [x] Password generator, TOTP codes
- [x] Auto-lock, biometric unlock
- [x] WebDAV E2EE sync, file backup
- [x] Google Drive E2EE (optional OAuth)
- [x] Chrome/Yandex extension + autofill
- [x] Desktop native host ↔ local API
- [x] Hybrid KEM API (X25519 + ML-KEM-768 scaffold)
- [ ] Prebuilt liboqs in APK
- [ ] Bitwarden import
- [ ] iOS

---

## Project layout

```
vrav-pass/
├── mobile/              # Flutter app (Android + desktop targets)
├── extensions/chrome/   # Manifest V3 extension
├── desktop/native_host/ # Native Messaging host
├── docs/                # Architecture, sync, user guide
└── .github/workflows/   # APK CI + tagged releases
```

## Documentation

| Doc | Topic |
|-----|--------|
| [USER_GUIDE.md](docs/USER_GUIDE.md) | How to use (EN + RU) |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Design & crypto |
| [SYNC.md](docs/SYNC.md) | WebDAV / files |
| [GOOGLE_DRIVE.md](docs/GOOGLE_DRIVE.md) | Drive OAuth |
| [EXTENSION.md](docs/EXTENSION.md) | Browser |
| [DESKTOP_HOST.md](docs/DESKTOP_HOST.md) | Native host |
| [PQ_CRYPTO.md](docs/PQ_CRYPTO.md) | Post-quantum |
| [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) | Ship checklist |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and PRs welcome.

## License

[MIT](LICENSE) — free to use, modify, and redistribute.

---

## На русском

**Vrav Pass** — суверенный менеджер **паролей, заметок и закладок**.

- Всё хранится **у вас** в зашифрованном виде (Argon2id + AES-256-GCM).
- **Нет наших серверов** и аккаунтов Vrav: нечего утечь «у разработчика».
- Синхронизация — только **шифротекст** на ваш WebDAV / Google Drive / файл.
- Есть приложение (Flutter), расширение для Chrome/Yandex, desktop-host для автозаполнения.
- Языки: русский, English, български, ไทย.

**Важно:** забыли мастер-пароль — данные не восстановить. Это не облачный «восстановим через email».  
**Статус:** публичная бета. Для повседневного использования — осознанно; критичные сценарии — после стабилизации v1 и при желании аудита.

Как пользоваться: [docs/USER_GUIDE.md](docs/USER_GUIDE.md).  
Установка для разработчиков — **Quick start** выше. Баги — GitHub Issues.
