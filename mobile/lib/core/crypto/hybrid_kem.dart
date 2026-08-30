import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Hybrid key encapsulation: classical X25519 + post-quantum slot.
///
/// Shared secret = HKDF-SHA512( ss_x25519 || ss_pq )
///
/// ML-KEM-768: wire format reserved. Until a pure-Dart / FFI liboqs binding
/// is linked, [PostQuantumKem] uses a **placeholder** that is NOT quantum-safe.
/// Do not rely on PQ security until [PostQuantumKem.isRealImplementation] is true.
class HybridKem {
  HybridKem({
    X25519? x25519,
    PostQuantumKem? pq,
  })  : _x25519 = x25519 ?? X25519(),
        _pq = pq ?? PlaceholderPqKem();

  final X25519 _x25519;
  final PostQuantumKem _pq;

  bool get pqReady => _pq.isRealImplementation;

  Future<HybridKeyPair> generateKeyPair() async {
    final classical = await _x25519.newKeyPair();
    final pq = await _pq.generateKeyPair();
    return HybridKeyPair(classical: classical, pq: pq);
  }

  /// Encapsulate to peer public keys → ciphertext + shared secret.
  Future<HybridEncapsulation> encapsulate({
    required SimplePublicKey peerX25519Public,
    required Uint8List peerPqPublic,
  }) async {
    final eph = await _x25519.newKeyPair();
    final ssClassical = await _x25519.sharedSecretKey(
      keyPair: eph,
      remotePublicKey: peerX25519Public,
    );
    final ephPub = await eph.extractPublicKey();
    final pqEnc = await _pq.encapsulate(peerPqPublic);

    final classicalBytes = await ssClassical.extractBytes();
    final combined = Uint8List.fromList([
      ...classicalBytes,
      ...pqEnc.sharedSecret,
    ]);
    final shared = await _hkdf(combined, 'vrav-hybrid-kem-v1');

    return HybridEncapsulation(
      x25519EphemeralPublic: Uint8List.fromList(ephPub.bytes),
      pqCiphertext: pqEnc.ciphertext,
      sharedSecret: shared,
    );
  }

  /// Decapsulate with our key pair.
  Future<SecretKey> decapsulate({
    required SimpleKeyPair ourX25519,
    required Uint8List ourPqSecret,
    required Uint8List peerEphX25519Public,
    required Uint8List pqCiphertext,
  }) async {
    final ssClassical = await _x25519.sharedSecretKey(
      keyPair: ourX25519,
      remotePublicKey: SimplePublicKey(peerEphX25519Public, type: KeyPairType.x25519),
    );
    final ssPq = await _pq.decapsulate(ourPqSecret, pqCiphertext);
    final classicalBytes = await ssClassical.extractBytes();
    final combined = Uint8List.fromList([...classicalBytes, ...ssPq]);
    return _hkdf(combined, 'vrav-hybrid-kem-v1');
  }

  Future<SecretKey> _hkdf(List<int> ikm, String info) async {
    final hkdf = Hkdf(hmac: Hmac.sha512(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: SecretKey(ikm),
      info: utf8.encode(info),
      nonce: Uint8List(0),
    );
  }
}

class HybridKeyPair {
  HybridKeyPair({required this.classical, required this.pq});
  final SimpleKeyPair classical;
  final PqKeyPair pq;
}

class HybridEncapsulation {
  HybridEncapsulation({
    required this.x25519EphemeralPublic,
    required this.pqCiphertext,
    required this.sharedSecret,
  });
  final Uint8List x25519EphemeralPublic;
  final Uint8List pqCiphertext;
  final SecretKey sharedSecret;
}

abstract class PostQuantumKem {
  bool get isRealImplementation;
  Future<PqKeyPair> generateKeyPair();
  Future<PqEncapsulation> encapsulate(Uint8List publicKey);
  Future<Uint8List> decapsulate(Uint8List secretKey, Uint8List ciphertext);
}

class PqKeyPair {
  PqKeyPair({required this.publicKey, required this.secretKey});
  final Uint8List publicKey;
  final Uint8List secretKey;
}

class PqEncapsulation {
  PqEncapsulation({required this.ciphertext, required this.sharedSecret});
  final Uint8List ciphertext;
  final Uint8List sharedSecret;
}

/// NOT quantum-safe — stands in until ML-KEM (Kyber) via liboqs FFI / pure-Dart.
class PlaceholderPqKem implements PostQuantumKem {
  @override
  bool get isRealImplementation => false;

  final _algo = X25519(); // classical stand-in only

  @override
  Future<PqKeyPair> generateKeyPair() async {
    final kp = await _algo.newKeyPair();
    final pub = await kp.extractPublicKey();
    final priv = await kp.extractPrivateKeyBytes();
    return PqKeyPair(
      publicKey: Uint8List.fromList(pub.bytes),
      secretKey: Uint8List.fromList(priv),
    );
  }

  @override
  Future<PqEncapsulation> encapsulate(Uint8List publicKey) async {
    final eph = await _algo.newKeyPair();
    final ss = await _algo.sharedSecretKey(
      keyPair: eph,
      remotePublicKey: SimplePublicKey(publicKey, type: KeyPairType.x25519),
    );
    final ephPub = await eph.extractPublicKey();
    return PqEncapsulation(
      ciphertext: Uint8List.fromList(ephPub.bytes),
      sharedSecret: Uint8List.fromList(await ss.extractBytes()),
    );
  }

  @override
  Future<Uint8List> decapsulate(Uint8List secretKey, Uint8List ciphertext) async {
    // Reconstruct key pair from secret is non-trivial for X25519 in this API;
    // placeholder returns hash of inputs for structural testing only.
    final sink = sha256;
    final h = await sink.hash([...secretKey, ...ciphertext]);
    return Uint8List.fromList(h.bytes);
  }
}
