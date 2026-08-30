# Vrav Pass — E2EE Sync

## Principles

- Only **ciphertext** leaves the device (`vault.v1.enc`).
- Same AES-256-GCM blob as local storage.
- Master password / DEK never sent anywhere.
- Cloud provider = dumb storage.

## File export / import

1. **Export** — copies local `vault.v1.enc` and shares it (file manager / messengers).
2. **Import** — picks a `.enc` file, verifies it decrypts with current master key, replaces local vault.

Use the **same master password** on both devices.

## WebDAV

Works with:

| Provider | URL example |
|----------|-------------|
| Yandex Disk | `https://webdav.yandex.ru` |
| Nextcloud | `https://cloud.example.com/remote.php/dav/files/USER` |
| ownCloud | similar |
| Any standard WebDAV | your server URL |

### Yandex Disk

1. Create an **app password**: https://id.yandex.ru/security/app-passwords
2. WebDAV URL: `https://webdav.yandex.ru`
3. Username: your Yandex login (email)
4. Password: the app password
5. Remote path: `/vrav-pass/vault.v1.enc` (created automatically)

### Flow

- **Upload** — push local encrypted vault to remote path.
- **Download** — pull remote blob, verify decrypt, replace local.

Conflict policy (current): last manual action wins. Automatic merge is future work.

## Google Drive (planned)

Will use Google Sign-In + Drive API App Data folder. Only ciphertext uploaded. Requires OAuth client ID in the app.
