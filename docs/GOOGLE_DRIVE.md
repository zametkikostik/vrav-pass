# Google Drive E2EE sync setup

Vrav Pass uploads **only** the encrypted blob (`vault.v1.enc`) into the user's **Application Data** folder on Google Drive. Google never sees plaintext.

## 1. Google Cloud Console

1. Create a project: https://console.cloud.google.com/
2. Enable **Google Drive API**
3. Configure OAuth consent screen (External or Internal)
4. Create OAuth client IDs:
   - **Android**: package `com.vravpass.vrav_pass` (or your `applicationId`), SHA-1 of debug/release keystore
   - **Web** (optional, for some google_sign_in flows)

Get SHA-1:

```bash
cd mobile/android
./gradlew signingReport
```

## 2. Flutter packages

Add to `pubspec.yaml`:

```yaml
google_sign_in: ^6.2.1
googleapis: ^13.2.0
googleapis_auth: ^1.6.0
extension_google_sign_in_as_googleapis_auth: ^2.0.12
```

## 3. Scopes

Use minimal scope:

- `https://www.googleapis.com/auth/drive.appdata`

Do **not** request full Drive access.

## 4. Implementation sketch

```dart
final googleSignIn = GoogleSignIn(
  scopes: [DriveApi.driveAppdataScope],
);
final account = await googleSignIn.signIn();
final authClient = await googleSignIn.authenticatedClient();
final drive = DriveApi(authClient!);

// Upload to appDataFolder
await drive.files.create(
  File()..name = 'vault.v1.enc'..parents = ['appDataFolder'],
  uploadMedia: Media(Stream.value(cipherBytes), cipherBytes.length),
);
```

Set `GoogleDriveSync.integrationEnabled = true` and pass `clientId` when ready.

## 5. Security notes

- Same master password on all devices
- Conflict policy: last manual upload/download wins (same as WebDAV)
- Revoke access anytime in Google Account → Security → Third-party access
