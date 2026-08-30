import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'ml_kem_interface.dart';

/// Native ML-KEM-768 via liboqs (`OQS_KEM_kyber_768` / `ml_kem_768`).
///
/// Build liboqs and ship as:
/// - Android: jniLibs / cmake
/// - Linux: liboqs.so in LD_LIBRARY_PATH
/// - Windows: oqs.dll
/// - macOS: liboqs.dylib
///
/// If the library is missing, [tryLoad] returns null → use [MlKem768Stub].
class MlKem768Ffi implements MlKem768 {
  MlKem768Ffi._(this._lib, this._kem);

  final DynamicLibrary _lib;
  final Pointer<_OqsKem> _kem;

  static MlKem768Ffi? tryLoad() {
    try {
      final lib = _openLib();
      final newKem = lib.lookupFunction<Pointer<_OqsKem> Function(Pointer<Utf8>),
          Pointer<_OqsKem> Function(Pointer<Utf8>)>('OQS_KEM_new');

      // Prefer FIPS name, fall back to Kyber768 alias used in older liboqs
      Pointer<_OqsKem> kem = nullptr;
      for (final name in ['ML-KEM-768', 'Kyber768']) {
        final cName = name.toNativeUtf8();
        kem = newKem(cName);
        malloc.free(cName);
        if (kem != nullptr) break;
      }
      if (kem == nullptr) return null;
      return MlKem768Ffi._(lib, kem);
    } catch (_) {
      return null;
    }
  }

  static DynamicLibrary _openLib() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('liboqs.so');
    }
    if (Platform.isLinux) {
      return DynamicLibrary.open('liboqs.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('oqs.dll');
    }
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('liboqs.dylib');
    }
    throw UnsupportedError('Unsupported platform for liboqs');
  }

  @override
  bool get isNative => true;

  @override
  Future<MlKemKeyPair> generateKeyPair() async {
    final keypair = _lib.lookupFunction<
      Int32 Function(
          Pointer<_OqsKem>, Pointer<Uint8>, Pointer<Uint8>),
      int Function(
          Pointer<_OqsKem>, Pointer<Uint8>, Pointer<Uint8>)>('OQS_KEM_keypair');

    final pk = malloc<Uint8>(MlKem768Sizes.publicKey);
    final sk = malloc<Uint8>(MlKem768Sizes.secretKey);
    try {
      final rc = keypair(_kem, pk, sk);
      if (rc != 0) throw StateError('OQS_KEM_keypair failed: $rc');
      return MlKemKeyPair(
        publicKey: Uint8List.fromList(pk.asTypedList(MlKem768Sizes.publicKey)),
        secretKey: Uint8List.fromList(sk.asTypedList(MlKem768Sizes.secretKey)),
      );
    } finally {
      malloc.free(pk);
      malloc.free(sk);
    }
  }

  @override
  Future<MlKemEncapResult> encapsulate(Uint8List publicKey) async {
    final enc = _lib.lookupFunction<
      Int32 Function(Pointer<_OqsKem>, Pointer<Uint8>, Pointer<Uint8>,
          Pointer<Uint8>),
      int Function(Pointer<_OqsKem>, Pointer<Uint8>, Pointer<Uint8>,
          Pointer<Uint8>)>('OQS_KEM_encaps');

    final ct = malloc<Uint8>(MlKem768Sizes.ciphertext);
    final ss = malloc<Uint8>(MlKem768Sizes.sharedSecret);
    final pk = malloc<Uint8>(publicKey.length);
    pk.asTypedList(publicKey.length).setAll(0, publicKey);
    try {
      final rc = enc(_kem, ct, ss, pk);
      if (rc != 0) throw StateError('OQS_KEM_encaps failed: $rc');
      return MlKemEncapResult(
        ciphertext:
            Uint8List.fromList(ct.asTypedList(MlKem768Sizes.ciphertext)),
        sharedSecret:
            Uint8List.fromList(ss.asTypedList(MlKem768Sizes.sharedSecret)),
      );
    } finally {
      malloc.free(ct);
      malloc.free(ss);
      malloc.free(pk);
    }
  }

  @override
  Future<Uint8List> decapsulate(
    Uint8List secretKey,
    Uint8List ciphertext,
  ) async {
    final dec = _lib.lookupFunction<
      Int32 Function(Pointer<_OqsKem>, Pointer<Uint8>, Pointer<Uint8>,
          Pointer<Uint8>),
      int Function(Pointer<_OqsKem>, Pointer<Uint8>, Pointer<Uint8>,
          Pointer<Uint8>)>('OQS_KEM_decaps');

    final ss = malloc<Uint8>(MlKem768Sizes.sharedSecret);
    final ct = malloc<Uint8>(ciphertext.length);
    final sk = malloc<Uint8>(secretKey.length);
    ct.asTypedList(ciphertext.length).setAll(0, ciphertext);
    sk.asTypedList(secretKey.length).setAll(0, secretKey);
    try {
      final rc = dec(_kem, ss, ct, sk);
      if (rc != 0) throw StateError('OQS_KEM_decaps failed: $rc');
      return Uint8List.fromList(ss.asTypedList(MlKem768Sizes.sharedSecret));
    } finally {
      malloc.free(ss);
      malloc.free(ct);
      malloc.free(sk);
    }
  }
}

/// Opaque OQS_KEM struct (we only pass the pointer).
final class _OqsKem extends Opaque {}
