import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'sync_models.dart';

/// Google Drive App Data folder sync for encrypted vault blob.
///
/// Requires:
/// 1. Google Cloud Console OAuth client (Android + optional Web)
/// 2. Packages: google_sign_in, googleapis, extension_google_sign_in_as_googleapis_auth
/// 3. SHA-1 of signing key registered in Cloud Console
///
/// Until credentials are configured, [isConfigured] is false and methods return errors.
///
/// Only ciphertext is uploaded (same as WebDAV).
class GoogleDriveSync {
  GoogleDriveSync({
    this.clientId,
  });

  /// Optional web client id for some platforms.
  final String? clientId;

  /// Set true after wiring google_sign_in in app.
  static bool integrationEnabled = false;

  bool get isConfigured => integrationEnabled && (clientId != null && clientId!.isNotEmpty);

  /// Placeholder: implement with google_sign_in + drive.DriveApi.
  Future<SyncResult> uploadCipher(Uint8List data, {String fileName = 'vault.v1.enc'}) async {
    if (!isConfigured) {
      return SyncResult(
        success: false,
        message: 'Google Drive not configured. See docs/GOOGLE_DRIVE.md',
      );
    }
    // Integration point for Drive API media upload to appDataFolder.
    return SyncResult(success: false, message: 'Wire google_sign_in to enable');
  }

  Future<SyncResult> downloadCipher({String fileName = 'vault.v1.enc'}) async {
    if (!isConfigured) {
      return SyncResult(
        success: false,
        message: 'Google Drive not configured. See docs/GOOGLE_DRIVE.md',
      );
    }
    return SyncResult(success: false, message: 'Wire google_sign_in to enable');
  }

  /// Test network reachability (no auth).
  Future<bool> pingGoogle() async {
    try {
      final res = await http.head(Uri.parse('https://www.googleapis.com'));
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
