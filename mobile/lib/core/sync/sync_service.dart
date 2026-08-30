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
import 'sync_models.dart';
import 'webdav_client.dart';

/// Handles E2EE blob export/import and WebDAV sync.
///
/// The file on disk / in cloud is already AES-GCM ciphertext
/// (same format as local vault.v1.enc). No plaintext ever leaves the device.
class SyncService {
  SyncService({
    required this.dek,
    FlutterSecureStorage? storage,
    CryptoEngine? engine,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _engine = engine ?? CryptoEngine.instance;

  final SecretKey dek;
  final FlutterSecureStorage _storage;
  final CryptoEngine _engine;

  static const _prefsKey = 'sync_config_json';
  static const _securePwdKey = 'sync_webdav_password';

  Future<File> _localVaultFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'vault.v1.enc'));
  }

  /// Read current encrypted vault bytes (must already exist).
  Future<Uint8List> readLocalCipher() async {
    final file = await _localVaultFile();
    if (!await file.exists()) {
      // Create empty vault first
      final repo = VaultRepository(dek: dek, engine: _engine);
      await repo.saveAll([]);
    }
    return Uint8List.fromList(await (await _localVaultFile()).readAsBytes());
  }

  /// Write ciphertext to local vault file (after download).
  Future<void> writeLocalCipher(Uint8List data) async {
    final file = await _localVaultFile();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(data, flush: true);
    if (await file.exists()) await file.delete();
    await tmp.rename(file.path);
  }

  // ── Config ──────────────────────────────────────────────

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

  // ── File export / import ────────────────────────────────

  /// Copy encrypted vault to a shareable path (Documents/vrav-pass-export-...enc).
  Future<File> exportToFile() async {
    final cipher = await readLocalCipher();
    final dir = await getApplicationDocumentsDirectory();
    final name =
        'vrav-pass-export-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.enc';
    final out = File(p.join(dir.path, name));
    await out.writeAsBytes(cipher, flush: true);
    return out;
  }

  /// Import ciphertext from an external file (replaces local vault).
  Future<void> importFromFile(File source) async {
    final data = await source.readAsBytes();
    if (data.length < 28) {
      throw ArgumentError('File too small to be a valid vault');
    }
    // Verify we can decrypt with current DEK
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

  // ── WebDAV ──────────────────────────────────────────────

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
      // Verify decryptable
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
}
