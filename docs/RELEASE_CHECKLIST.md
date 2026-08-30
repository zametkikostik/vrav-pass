# Vrav Pass — Release checklist

## Crypto / security

- [ ] Master password never logged or synced in plaintext
- [ ] Local vault = AES-256-GCM only on disk
- [ ] Cloud (WebDAV / Drive) = same ciphertext blob
- [ ] Biometric DEK only in platform secure storage
- [ ] Auto-lock on background (default on)
- [ ] `isPostQuantumNative` documented as false until liboqs shipped
- [ ] JSON export for extension warned as temporary plaintext bridge

## Mobile

- [ ] `./scripts/bootstrap.sh` or `flutter create .`
- [ ] Biometric permissions in AndroidManifest
- [ ] `flutter analyze` clean enough for release
- [ ] `flutter build apk --release --split-per-abi`
- [ ] Manual: create vault → add password/note/bookmark → lock → unlock
- [ ] Manual: TOTP code refreshes
- [ ] Manual: WebDAV upload/download with Yandex or Nextcloud
- [ ] Optional: Google Drive with your OAuth client ID

## Extension

- [ ] Load unpacked `extensions/chrome`
- [ ] Import JSON + lock + unlock popup
- [ ] Autofill on a test login page
- [ ] Options → Test native host (desktop only)

## Desktop host

- [ ] `install_linux.sh <extension-id>`
- [ ] `flutter run -d linux` → unlock → host ping shows `desktop: true`
- [ ] `findForUrl` returns matches for saved domain

## CI

- [ ] GitHub Actions **Build APK** green on `main`
- [ ] Artifact downloadable

## Store / distribution (later)

- [ ] Privacy policy: no accounts, no our servers
- [ ] Application ID / signing key final
- [ ] Screenshots + short description RU/EN

## Version bump

- [ ] `pubspec.yaml` version
- [ ] Extension `manifest.json` version
- [ ] Git tag `v0.x.y`
