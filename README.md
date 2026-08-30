# Vrav Pass

**Sovereign password, notes & bookmarks manager.**  
Offline-first · Zero-knowledge · No our servers · Your cloud, your keys

[![Build APK](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml/badge.svg)](https://github.com/zametkikostik/vrav-pass/actions/workflows/build-apk.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Status:** public **beta** (`0.1.0-beta`) — good for friends, self-hosters, careful daily use.  
> Not a bank-grade audited product yet. Read [Security](#security-model).  
> **Русский:** [На русском](#на-русском) · [User guide](docs/USER_GUIDE.md)

---

## What is this?

Local-first vault for **passwords**, **secure notes**, and **bookmarks**.

| | |
|--|--|
| **No Vrav backend** | No account on our servers |
| **Encryption** | Argon2id → AES-256-GCM |
| **Sync** | Your WebDAV / Drive / file — ciphertext only |
| **Browsers** | Chrome, Edge, Yandex, Firefox (temp) |
| **Languages** | RU · EN · BG · TH |

---

## Features (beta)

| Feature | Status |
|---------|--------|
| Local encrypted vault | ✅ |
| Passwords / notes / bookmarks | ✅ |
| Search, filters, favorites | ✅ |
| Generator + TOTP | ✅ |
| Clipboard auto-clear | ✅ |
| Auto-lock + biometrics | ✅ |
| Import Bitwarden / Chrome | ✅ |
| WebDAV + file + Google Drive | ✅ |
| Extension autofill | ✅ |
| Desktop native host | ✅ |
| Dark / light Material 3 UI | ✅ |
| PQ / iOS / store listings | 📋 optional |

---

## Security model

```
Master password → Argon2id → DEK → AES-256-GCM vault
```

Forgot master password → data unrecoverable. Report vulns: [SECURITY.md](SECURITY.md).

---

## Quick start

```bash
git clone https://github.com/zametkikostik/vrav-pass.git
cd vrav-pass/mobile && ./scripts/bootstrap.sh && flutter run
```

Extension: load unpacked `extensions/chrome` (Chrome / **Edge** / Yandex).  
Firefox: see [extensions/firefox/README.md](extensions/firefox/README.md).  
Edge store path (later): [docs/EDGE_STORE.md](docs/EDGE_STORE.md).

Tag `v0.1.0-beta` → APK on GitHub Releases.

More: [docs/USER_GUIDE.md](docs/USER_GUIDE.md)

## Docs

Architecture · Sync · Drive · Extension · Desktop host · PQ · [EDGE_STORE](docs/EDGE_STORE.md) · [CHANGELOG](CHANGELOG.md)

## License

[MIT](LICENSE)

---

## На русском

**Vrav Pass** — офлайн-менеджер паролей без наших серверов.  
Бета для друзей и себя: шифрование на устройстве, WebDAV, импорт Bitwarden/Chrome, расширение.  
Мастер-пароль не восстанавливается. Это не «прошли аудит Big Four».

[Руководство](docs/USER_GUIDE.md) · [Edge](docs/EDGE_STORE.md)
