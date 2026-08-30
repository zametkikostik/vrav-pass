import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/export.dart' as pc;

/// Core cryptographic engine for Vrav Pass.
///
/// Design goals:
/// - Argon2id for master password KDF
/// - AES-256-GCM for data encryption
/// - Foundation ready for hybrid post-quantum (X25519 + ML-KEM) later
class CryptoEngine {
  CryptoEngine._();
  static final instance = CryptoEngine._();

  static const int saltLength = 32;
  static const int keyLength = 32; // 256 bit
  static const int nonceLength = 12;

  // Argon2id parameters (can be tuned; higher = more secure & slower)
  static const int argon2Memory = 65536; // 64 MB
  static const int argon2Iterations = 3;
  static const int argon2Parallelism = 4;

  final _aesGcm = AesGcm.with256bits();
  final _secureRandom = Random.secure();

  /// Generate cryptographically secure random bytes.
  Uint8List randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return bytes;
  }

  /// Derive Master Key from password using Argon2id (via pointycastle).
  Future<SecretKey> deriveMasterKey({
    required String password,
    required Uint8List salt,
  }) async {
    final argon2 = pc.Argon2BytesGenerator();
    final params = pc.Argon2Parameters(
      pc.Argon2Parameters.ARGON2_id,
      salt,
      desiredKeyLength: keyLength,
      memory: argon2Memory,
      iterations: argon2Iterations,
      lanes: argon2Parallelism,
      version: pc.Argon2Parameters.ARGON2_VERSION_13,
    );
    argon2.init(params);

    final passwordBytes = utf8.encode(password);
    final out = Uint8List(keyLength);
    argon2.deriveKey(passwordBytes, 0, out, 0);

    // Zero password bytes as best-effort
    for (var i = 0; i < passwordBytes.length; i++) {
      passwordBytes[i] = 0;
    }

    return SecretKey(out);
  }

  /// Derive sub-keys via HKDF-SHA512.
  Future<SecretKey> deriveSubKey({
    required SecretKey masterKey,
    required String info,
    int length = keyLength,
  }) async {
    final hkdf = Hkdf(hmac: Hmac.sha512(), outputLength: length);
    final masterBytes = await masterKey.extractBytes();
    return hkdf.deriveKey(
      secretKey: SecretKey(masterBytes),
      info: utf8.encode(info),
      nonce: Uint8List(0), // salt optional for HKDF here
    );
  }

  /// Encrypt plaintext with AES-256-GCM.
  /// Returns: nonce || ciphertext || mac (concatenated)
  Future<Uint8List> encrypt({
    required SecretKey key,
    required Uint8List plaintext,
    List<int>? aad,
  }) async {
    final nonce = randomBytes(nonceLength);
    final secretBox = await _aesGcm.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
      aad: aad ?? <int>[],
    );

    // Layout: nonce (12) + cipherText + mac (16)
    final result = BytesBuilder();
    result.add(secretBox.nonce);
    result.add(secretBox.cipherText);
    result.add(secretBox.mac.bytes);
    return result.toBytes();
  }

  /// Decrypt data produced by [encrypt].
  Future<Uint8List> decrypt({
    required SecretKey key,
    required Uint8List data,
    List<int>? aad,
  }) async {
    if (data.length < nonceLength + 16) {
      throw ArgumentError('Ciphertext too short');
    }

    final nonce = data.sublist(0, nonceLength);
    final mac = Mac(data.sublist(data.length - 16));
    final cipherText = data.sublist(nonceLength, data.length - 16);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final clear = await _aesGcm.decrypt(
      secretBox,
      secretKey: key,
      aad: aad ?? <int>[],
    );
    return Uint8List.fromList(clear);
  }

  /// Encrypt a UTF-8 string and return base64.
  Future<String> encryptString({
    required SecretKey key,
    required String plaintext,
    List<int>? aad,
  }) async {
    final data = await encrypt(
      key: key,
      plaintext: Uint8List.fromList(utf8.encode(plaintext)),
      aad: aad,
    );
    return base64Encode(data);
  }

  /// Decrypt a base64 string produced by [encryptString].
  Future<String> decryptString({
    required SecretKey key,
    required String ciphertextB64,
    List<int>? aad,
  }) async {
    final data = base64Decode(ciphertextB64);
    final clear = await decrypt(key: key, data: data, aad: aad);
    return utf8.decode(clear);
  }
}
