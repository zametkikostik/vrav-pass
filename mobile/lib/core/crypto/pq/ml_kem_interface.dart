import 'dart:typed_data';

/// FIPS 203 ML-KEM-768 parameter sizes (bytes).
abstract final class MlKem768Sizes {
  static const int publicKey = 1184;
  static const int secretKey = 2400;
  static const int ciphertext = 1088;
  static const int sharedSecret = 32;
}

/// Platform-backed ML-KEM-768 (liboqs / native).
abstract class MlKem768 {
  /// true when linked to real liboqs (or equivalent).
  bool get isNative;

  Future<MlKemKeyPair> generateKeyPair();

  /// Encapsulate → ciphertext + shared secret (32 bytes).
  Future<MlKemEncapResult> encapsulate(Uint8List publicKey);

  /// Decapsulate ciphertext with secret key → shared secret.
  Future<Uint8List> decapsulate(Uint8List secretKey, Uint8List ciphertext);
}

class MlKemKeyPair {
  const MlKemKeyPair({required this.publicKey, required this.secretKey});
  final Uint8List publicKey;
  final Uint8List secretKey;
}

class MlKemEncapResult {
  const MlKemEncapResult({
    required this.ciphertext,
    required this.sharedSecret,
  });
  final Uint8List ciphertext;
  final Uint8List sharedSecret;
}
