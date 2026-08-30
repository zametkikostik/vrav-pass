import 'package:flutter_test/flutter_test.dart';
import 'package:vrav_pass/core/crypto/pq/ml_kem_interface.dart';
import 'package:vrav_pass/core/crypto/pq/ml_kem_stub.dart';

void main() {
  test('stub key sizes match FIPS 203 ML-KEM-768', () async {
    final kem = MlKem768Stub();
    expect(kem.isNative, isFalse);
    final kp = await kem.generateKeyPair();
    expect(kp.publicKey.length, MlKem768Sizes.publicKey);
    expect(kp.secretKey.length, MlKem768Sizes.secretKey);

    final enc = await kem.encapsulate(kp.publicKey);
    expect(enc.ciphertext.length, MlKem768Sizes.ciphertext);
    expect(enc.sharedSecret.length, MlKem768Sizes.sharedSecret);
  });
}
