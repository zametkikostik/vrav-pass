import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../config/app_config.dart';
import 'sync_models.dart';

/// E2EE vault blob ↔ Google Drive **appDataFolder**.
///
/// Setup: docs/GOOGLE_DRIVE.md
/// Client ID: AppConfig.googleServerClientId or --dart-define=GOOGLE_SERVER_CLIENT_ID=
class GoogleDriveSync {
  GoogleDriveSync({
    GoogleSignIn? signIn,
  }) : _signIn = signIn ??
            GoogleSignIn(
              scopes: [drive.DriveApi.driveAppdataScope],
              serverClientId: AppConfig.hasGoogleOAuth
                  ? AppConfig.googleServerClientId
                  : null,
            );

  final GoogleSignIn _signIn;
  static const _fileName = 'vault.v1.enc';

  Future<drive.DriveApi?> _api() async {
    var account = _signIn.currentUser;
    account ??= await _signIn.signInSilently();
    account ??= await _signIn.signIn();
    if (account == null) return null;

    final client = await _signIn.authenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  Future<String?> _findFileId(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_fileName' and trashed = false",
      $fields: 'files(id, name)',
    );
    final files = list.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }

  Future<SyncResult> uploadCipher(Uint8List data) async {
    try {
      final api = await _api();
      if (api == null) {
        return SyncResult(success: false, message: 'Google sign-in cancelled');
      }

      final media = drive.Media(
        Stream<List<int>>.value(data),
        data.length,
        contentType: 'application/octet-stream',
      );

      final existingId = await _findFileId(api);
      if (existingId != null) {
        await api.files.update(
          drive.File()..name = _fileName,
          existingId,
          uploadMedia: media,
        );
      } else {
        await api.files.create(
          drive.File()
            ..name = _fileName
            ..parents = ['appDataFolder'],
          uploadMedia: media,
        );
      }

      return SyncResult(
        success: true,
        bytes: data.length,
        message: 'Uploaded to Google Drive (appData)',
      );
    } catch (e) {
      return SyncResult(success: false, message: e.toString());
    }
  }

  Future<SyncResult> downloadCipher() async {
    try {
      final bytes = await downloadBytes();
      if (bytes == null) {
        return SyncResult(success: false, message: 'Download failed or cancelled');
      }
      return SyncResult(
        success: true,
        bytes: bytes.length,
        message: 'Downloaded from Google Drive',
      );
    } catch (e) {
      return SyncResult(success: false, message: e.toString());
    }
  }

  Future<Uint8List?> downloadBytes() async {
    final api = await _api();
    if (api == null) return null;
    final id = await _findFileId(api);
    if (id == null) return null;
    final media = await api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final chunks = <int>[];
    await for (final c in media.stream) {
      chunks.addAll(c);
    }
    return Uint8List.fromList(chunks);
  }

  Future<void> signOut() => _signIn.signOut();
}
