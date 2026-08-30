import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'ml_kem_interface.dart';

/// Development stub — **NOT quantum-safe**.
/// Uses random keys + SHA-256 so call sites and hybrid_kem can be tested.
class MlKem768Stub implements MlKem768 {
  @override
  bool get isNative => false;

  final _rng = Random.secure();

  Uint8List _rand(int n) {
    return Uint8List.fromList(List.generate(n, (_) => _rng.nextInt(256)));
  }

  @override
  Future<MlKemKeyPair> generateKeyPair() async {
    // Store "secret" as random; public derived for deterministic stub
    final sk = _rand(MlKem768Sizes.secretKey);
    final pk = Uint8List.fromList(
      crypto.sha256.convert(sk).bytes +
          _rand(MlKem768Sizes.publicKey - 32),
    );
    return MlKemKeyPair(publicKey: pk, secretKey: sk);
  }

  @override
  Future<MlKemEncapResult> encapsulate(Uint8List publicKey) async {
    final ct = _rand(MlKem768Sizes.ciphertext);
    final ss = Uint8List.fromList(
      crypto.sha256.convert([...publicKey.take(32), ...ct.take(32)]).bytes,
    );
    return MlKemEncapResult(ciphertext: ct, sharedSecret: ss);
  }

  @override
  Future<Uint8List> decapsulate(
    Uint8List secretKey,
    Uint8List ciphertext,
  ) async {
    // Cannot recover real ss without matching encapsulate state;
    // stub returns hash(sk||ct) for structural tests only.
    return Uint8List.fromList(
      crypto.sha256.convert([...secretKey.take(32), ...ciphertext.take(32)]).bytes,
    );
  }
}
