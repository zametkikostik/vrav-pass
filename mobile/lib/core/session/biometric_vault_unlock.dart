import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../crypto/vault_crypto_service.dart';

/// Persists DEK material protected by platform secure storage
/// so biometric auth can unlock without re-entering master password.
class BiometricVaultUnlock {
  BiometricVaultUnlock({
    FlutterSecureStorage? storage,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _keyPayload = 'bio_vault_payload';

  Future<void> saveUnlocked(UnlockedVault vault) async {
    final dek = await vault.dek.extractBytes();
    final mac = await vault.macKey.extractBytes();
    final master = await vault.masterKey.extractBytes();
    final payload = {
      'dek': base64Encode(dek),
      'mac': base64Encode(mac),
      'master': base64Encode(master),
      'salt': base64Encode(vault.salt),
    };
    await _storage.write(key: _keyPayload, value: jsonEncode(payload));
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyPayload);
  }

  Future<bool> hasSaved() async {
    final v = await _storage.read(key: _keyPayload);
    return v != null && v.isNotEmpty;
  }

  Future<UnlockedVault?> load() async {
    final raw = await _storage.read(key: _keyPayload);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return UnlockedVault(
        masterKey: SecretKey(base64Decode(j['master'] as String)),
        dek: SecretKey(base64Decode(j['dek'] as String)),
        macKey: SecretKey(base64Decode(j['mac'] as String)),
        salt: Uint8List.fromList(base64Decode(j['salt'] as String)),
      );
    } catch (_) {
      return null;
    }
  }
}
