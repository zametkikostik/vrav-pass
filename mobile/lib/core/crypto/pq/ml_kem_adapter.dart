import 'dart:typed_data';

import '../hybrid_kem.dart';
import 'ml_kem_interface.dart';

/// Bridges [MlKem768] into [PostQuantumKem] used by [HybridKem].
class MlKemPostQuantumAdapter implements PostQuantumKem {
  MlKemPostQuantumAdapter(this._impl);

  final MlKem768 _impl;

  @override
  bool get isRealImplementation => _impl.isNative;

  @override
  Future<PqKeyPair> generateKeyPair() async {
    final kp = await _impl.generateKeyPair();
    return PqKeyPair(publicKey: kp.publicKey, secretKey: kp.secretKey);
  }

  @override
  Future<PqEncapsulation> encapsulate(Uint8List publicKey) async {
    final r = await _impl.encapsulate(publicKey);
    return PqEncapsulation(
      ciphertext: r.ciphertext,
      sharedSecret: r.sharedSecret,
    );
  }

  @override
  Future<Uint8List> decapsulate(
    Uint8List secretKey,
    Uint8List ciphertext,
  ) {
    return _impl.decapsulate(secretKey, ciphertext);
  }
}
