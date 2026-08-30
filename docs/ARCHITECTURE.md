# Vrav Pass — Architecture

## 1. Goals

- **Sovereign**: no vendor servers, no telemetry, no phone-home.
- **Offline-first**: full functionality without internet.
- **Zero-knowledge**: even if cloud storage is compromised, data is unreadable.
- **Post-quantum ready**: hybrid classical + PQ cryptography.
- **Cross-platform**: Mobile (Android first) + Browser extensions + future Desktop.
- **Multi-language**: ru / en / bg / th from day one.

## 2. High-level components

```
+------------------+     Native Messaging / Local API     +---------------------+
| Browser Extension| <----------------------------------> | Flutter App (Core)  |
| (Chrome/Yandex..) |                                       |  - Vault            |
+------------------+                                       |  - Crypto Engine    |
                                                           |  - Sync Engine      |
                                                           |  - UI + i18n        |
                                                           +----------+----------+
                                                                      |
                                                         Encrypted blob only
                                                                      |
                                      +-------------------------------+-------------------------------+
                                      |                               |                               |
                               Google Drive                    Yandex Disk                      WebDAV / Local
                               (user account)                  (user account)                   folder
```

## 3. Cryptography design

### 3.1 Master Key derivation

```
MasterPassword + Salt (32 bytes random)
        |
        v
   Argon2id (memory=64MB+, iterations=3+, parallelism=4)
        |
        v
   Master Key (32 bytes)
        |
        +---> HKDF-SHA512 ---> Data Encryption Key (DEK)
        +---> HKDF-SHA512 ---> MAC Key
        +---> HKDF-SHA512 ---> Sync Key (for cloud blobs)
```

### 3.2 Data encryption

- Algorithm: **AES-256-GCM** (primary) or **ChaCha20-Poly1305**
- Nonce: 12 bytes random per item
- AAD: item type + version + timestamp

### 3.3 Post-quantum hybrid (key exchange / future sharing)

- Classical: X25519
- PQ: ML-KEM-768 (Kyber)
- Hybrid: shared secret = HKDF( X25519_ss || ML-KEM_ss )

Signatures (future):
- Ed25519 + ML-DSA-65 (Dilithium)

### 3.4 Vault format

- Local: SQLite (SQLCipher) or encrypted JSON files + index.
- Cloud: single encrypted blob or chunked encrypted objects + manifest (also encrypted).
- Versioned header with crypto algorithm identifiers for future migration.

### 3.5 Memory safety

- Sensitive keys zeroed after use where possible.
- No plaintext secrets in logs.
- Optional biometric unlock (Android Keystore / biometric) that unlocks DEK, not Master Password.

## 4. Data model (simplified)

```dart
VaultItem {
  id: Uuid
  type: password | note | bookmark | identity
  title: String
  // encrypted fields depend on type
  createdAt, updatedAt
  tags: List<String>
  favorite: bool
}

PasswordItem extends VaultItem {
  username, password, url, totpSecret, notes...
}

NoteItem {
  content: Markdown
  attachments: List<EncryptedBlob>
}

BookmarkItem {
  url, title, faviconHash, folderPath, description
}
```

## 5. Sync model

1. User authenticates to **their** cloud provider (OAuth or WebDAV credentials stored encrypted).
2. App encrypts entire vault (or delta) with Sync Key.
3. Uploads only ciphertext + encrypted manifest.
4. Conflict resolution: last-write-wins with vector clocks / CRDT-lite (future).

No central server ever sees plaintext or even knows user identity beyond what the cloud provider already knows.

## 6. Browser extension architecture

- Manifest V3
- Options:
  A. Native Messaging host (Flutter app acts as host) — preferred for full vault access
  B. Extension has its own encrypted local store + periodic sync with mobile via QR / local network / cloud
- Autofill via content scripts + secure messaging
- Bookmarks import/export and management UI in extension popup/options

## 7. Build & CI

- Flutter project under `mobile/`
- GitHub Actions:
  - `flutter build apk --release`
  - Artifact upload
  - Optional signed release (user provides keystore secrets)

## 8. i18n

- `easy_localization` or Flutter gen-l10n
- Locales: `ru`, `en`, `bg`, `th`
- All user-facing strings externalized from day one

## 9. Security threats we mitigate

| Threat                    | Mitigation                                      |
|---------------------------|-------------------------------------------------|
| Cloud provider breach     | E2EE, zero-knowledge                            |
| Device theft              | Master password + optional biometric + auto-lock|
| Memory dump               | Key zeroing, secure storage                     |
| Quantum computer (future) | Hybrid PQ KEM + signatures                      |
| Supply chain              | Open source, reproducible builds (goal)         |
| Phishing / MITM           | No servers of ours; certificate pinning for APIs|

## 10. Roadmap (high level)

1. Crypto core + local vault (passwords + notes)
2. Flutter UI + 4 languages
3. Android APK via Actions
4. Bookmarks support
5. Google Drive / WebDAV E2EE sync
6. Chrome + Yandex extension (Native Messaging)
7. Desktop targets
8. Advanced PQ features & audit

---

This document is the source of truth for design decisions. Changes must be discussed and recorded here.
