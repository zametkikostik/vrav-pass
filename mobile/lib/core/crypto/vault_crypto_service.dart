import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'crypto_engine.dart';

/// Manages vault existence, salt, verification and key derivation.
///
/// Stored in secure storage:
/// - vault_salt          (base64)
/// - vault_verifier      (base64 of encrypted known string)
/// - vault_created_at    (ISO8601)
class VaultCryptoService {
  VaultCryptoService({
    FlutterSecureStorage? storage,
    CryptoEngine? engine,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _engine = engine ?? CryptoEngine.instance;

  final FlutterSecureStorage _storage;
  final CryptoEngine _engine;

  static const _keySalt = 'vault_salt';
  static const _keyVerifier = 'vault_verifier';
  static const _keyCreatedAt = 'vault_created_at';
  static const _verifierPlain = 'vrav-pass-vault-ok-v1';

  /// Returns true if a vault has already been created on this device.
  Future<bool> vaultExists() async {
    final salt = await _storage.read(key: _keySalt);
    final verifier = await _storage.read(key: _keyVerifier);
    return salt != null && salt.isNotEmpty && verifier != null && verifier.isNotEmpty;
  }

  /// Create a new vault.
  /// Throws if vault already exists.
  Future<UnlockedVault> createVault(String masterPassword) async {
    if (await vaultExists()) {
      throw StateError('Vault already exists');
    }
    if (masterPassword.length < 8) {
      throw ArgumentError('Master password must be at least 8 characters');
    }

    final salt = _engine.randomBytes(CryptoEngine.saltLength);
    final masterKey = await _engine.deriveMasterKey(
      password: masterPassword,
      salt: salt,
    );

    final dek = await _engine.deriveSubKey(masterKey: masterKey, info: 'vrav-dek-v1');
    final macKey = await _engine.deriveSubKey(masterKey: masterKey, info: 'vrav-mac-v1');

    // Store encrypted verifier so we can check password later without storing the password
    final verifier = await _engine.encryptString(
      key: dek,
      plaintext: _verifierPlain,
      aad: utf8.encode('verifier'),
    );

    await _storage.write(key: _keySalt, value: base64Encode(salt));
    await _storage.write(key: _keyVerifier, value: verifier);
    await _storage.write(
      key: _keyCreatedAt,
      value: DateTime.now().toUtc().toIso8601String(),
    );

    return UnlockedVault(
      masterKey: masterKey,
      dek: dek,
      macKey: macKey,
      salt: salt,
    );
  }

  /// Unlock existing vault with master password.
  /// Throws [WrongMasterPasswordException] on failure.
  Future<UnlockedVault> unlockVault(String masterPassword) async {
    final saltB64 = await _storage.read(key: _keySalt);
    final verifierB64 = await _storage.read(key: _keyVerifier);

    if (saltB64 == null || verifierB64 == null) {
      throw StateError('Vault does not exist');
    }

    final salt = base64Decode(saltB64);
    final masterKey = await _engine.deriveMasterKey(
      password: masterPassword,
      salt: Uint8List.fromList(salt),
    );

    final dek = await _engine.deriveSubKey(masterKey: masterKey, info: 'vrav-dek-v1');
    final macKey = await _engine.deriveSubKey(masterKey: masterKey, info: 'vrav-mac-v1');

    try {
      final plain = await _engine.decryptString(
        key: dek,
        ciphertextB64: verifierB64,
        aad: utf8.encode('verifier'),
      );
      if (plain != _verifierPlain) {
        throw WrongMasterPasswordException();
      }
    } catch (_) {
      throw WrongMasterPasswordException();
    }

    return UnlockedVault(
      masterKey: masterKey,
      dek: dek,
      macKey: macKey,
      salt: Uint8List.fromList(salt),
    );
  }

  /// Wipe all vault metadata (danger — data loss).
  Future<void> destroyVaultMetadata() async {
    await _storage.delete(key: _keySalt);
    await _storage.delete(key: _keyVerifier);
    await _storage.delete(key: _keyCreatedAt);
  }
}

class UnlockedVault {
  UnlockedVault({
    required this.masterKey,
    required this.dek,
    required this.macKey,
    required this.salt,
  });

  final SecretKey masterKey;
  final SecretKey dek;
  final SecretKey macKey;
  final Uint8List salt;
}

class WrongMasterPasswordException implements Exception {
  @override
  String toString() => 'Wrong master password';
}
