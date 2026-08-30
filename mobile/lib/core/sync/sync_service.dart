import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../crypto/crypto_engine.dart';
import '../vault/vault_repository.dart';
import 'google_drive_sync.dart';
import 'sync_models.dart';
import 'webdav_client.dart';

class SyncService {
  SyncService({
    required this.dek,
    FlutterSecureStorage? storage,
    CryptoEngine? engine,
    GoogleDriveSync? drive,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _engine = engine ?? CryptoEngine.instance,
        _drive = drive ?? GoogleDriveSync();

  final SecretKey dek;
  final FlutterSecureStorage _storage;
  final CryptoEngine _engine;
  final GoogleDriveSync _drive;

  static const _prefsKey = 'sync_config_json';
  static const _securePwdKey = 'sync_webdav_password';

  Future<File> _localVaultFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'vault.v1.enc'));
  }

  Future<Uint8List> readLocalCipher() async {
    final file = await _localVaultFile();
    if (!await file.exists()) {
      final repo = VaultRepository(dek: dek, engine: _engine);
      await repo.saveAll([]);
    }
    return Uint8List.fromList(await (await _localVaultFile()).readAsBytes());
  }

  Future<void> writeLocalCipher(Uint8List data) async {
    final file = await _localVaultFile();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(data, flush: true);
    if (await file.exists()) await file.delete();
    await tmp.rename(file.path);
  }

  Future<SyncConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    SyncConfig cfg = const SyncConfig();
    if (jsonStr != null) {
      cfg = SyncConfig.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }
    final pwd = await _storage.read(key: _securePwdKey);
    return cfg.copyWith(webdavPassword: pwd);
  }

  Future<void> saveConfig(SyncConfig cfg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(cfg.toJson()));
    if (cfg.webdavPassword != null) {
      await _storage.write(key: _securePwdKey, value: cfg.webdavPassword);
    }
  }

  Future<File> exportToFile() async {
    final cipher = await readLocalCipher();
    final dir = await getApplicationDocumentsDirectory();
    final name =
        'vrav-pass-export-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.enc';
    final out = File(p.join(dir.path, name));
    await out.writeAsBytes(cipher, flush: true);
    return out;
  }

  Future<void> importFromFile(File source) async {
    final data = await source.readAsBytes();
    if (data.length < 28) {
      throw ArgumentError('File too small to be a valid vault');
    }
    try {
      await _engine.decrypt(
        key: dek,
        data: Uint8List.fromList(data),
        aad: utf8.encode('vrav-vault-v1'),
      );
    } catch (_) {
      throw StateError(
        'Cannot decrypt: wrong master password or corrupted file',
      );
    }
    await writeLocalCipher(Uint8List.fromList(data));
  }

  Future<SyncResult> uploadToWebDav() async {
    final cfg = await loadConfig();
    if (!cfg.hasWebdav) {
      return SyncResult(success: false, message: 'WebDAV not configured');
    }
    try {
      final client = WebDavClient(
        baseUrl: cfg.webdavUrl!,
        username: cfg.webdavUsername!,
        password: cfg.webdavPassword!,
      );
      final data = await readLocalCipher();
      await client.put(cfg.remotePath, data);
      await saveConfig(cfg.copyWith(lastSyncAt: DateTime.now().toUtc()));
      return SyncResult(success: true, bytes: data.length, message: 'Uploaded');
    } catch (e) {
      return SyncResult(success: false, message: e.toString());
    }
  }

  Future<SyncResult> downloadFromWebDav() async {
    final cfg = await loadConfig();
    if (!cfg.hasWebdav) {
      return SyncResult(success: false, message: 'WebDAV not configured');
    }
    try {
      final client = WebDavClient(
        baseUrl: cfg.webdavUrl!,
        username: cfg.webdavUsername!,
        password: cfg.webdavPassword!,
      );
      final data = await client.get(cfg.remotePath);
      await _engine.decrypt(
        key: dek,
        data: data,
        aad: utf8.encode('vrav-vault-v1'),
      );
      await writeLocalCipher(data);
      await saveConfig(cfg.copyWith(lastSyncAt: DateTime.now().toUtc()));
      return SyncResult(success: true, bytes: data.length, message: 'Downloaded');
    } catch (e) {
      return SyncResult(success: false, message: e.toString());
    }
  }

  // ── Google Drive ─────────────────────────────────────────

  Future<SyncResult> uploadToGoogleDrive() async {
    try {
      final data = await readLocalCipher();
      final result = await _drive.uploadCipher(data);
      if (result.success) {
        final cfg = await loadConfig();
        await saveConfig(cfg.copyWith(lastSyncAt: DateTime.now().toUtc()));
      }
      return result;
    } catch (e) {
      return SyncResult(success: false, message: e.toString());
    }
  }

  Future<SyncResult> downloadFromGoogleDrive() async {
    try {
      final bytes = await _drive.downloadBytes();
      if (bytes == null) {
        return SyncResult(success: false, message: 'Download failed or cancelled');
      }
      await _engine.decrypt(
        key: dek,
        data: bytes,
        aad: utf8.encode('vrav-vault-v1'),
      );
      await writeLocalCipher(bytes);
      final cfg = await loadConfig();
      await saveConfig(cfg.copyWith(lastSyncAt: DateTime.now().toUtc()));
      return SyncResult(
        success: true,
        bytes: bytes.length,
        message: 'Downloaded from Google Drive',
      );
    } catch (e) {
      return SyncResult(success: false, message: e.toString());
    }
  }
}
