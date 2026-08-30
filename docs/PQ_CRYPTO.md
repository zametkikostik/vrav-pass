# Post-quantum cryptography in Vrav Pass

## Design

Hybrid KEM (`mobile/lib/core/crypto/hybrid_kem.dart`):

```
ss = HKDF-SHA512( ss_X25519 || ss_ML-KEM-768 )
```

## Code layout

```
mobile/lib/core/crypto/pq/
  ml_kem_interface.dart   # FIPS 203 sizes + API
  ml_kem_stub.dart        # NOT quantum-safe (CI / no liboqs)
  ml_kem_ffi.dart         # liboqs OQS_KEM_* bindings
  ml_kem_adapter.dart     # → PostQuantumKem
  pq_factory.dart         # try FFI, else stub
```

| Component | Status |
|-----------|--------|
| X25519 | ✅ production |
| Hybrid + HKDF | ✅ |
| ML-KEM API + sizes | ✅ |
| liboqs FFI scaffold | ✅ |
| Stub fallback | ✅ |
| Prebuilt liboqs in APK/desktop | 📋 you build & ship |

`isPostQuantumNative` / `MlKem768.isNative` is **true** only when `liboqs` loads.

## Build liboqs (Linux example)

```bash
git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs && mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DOQS_USE_OPENSSL=ON ..
make -j"$(nproc)"
# produces liboqs.so → copy next to app or set LD_LIBRARY_PATH
```

Android: build with NDK and place `liboqs.so` under `android/app/src/main/jniLibs/<abi>/`.

## Usage

```dart
import 'package:vrav_pass/core/crypto/pq/pq_factory.dart';

final hybrid = createHybridKem();
final kp = await hybrid.generateKeyPair();
// encapsulate / decapsulate…
```

Local vault (Argon2id + AES-GCM) does **not** require PQ; hybrid KEM is for future pairing / sharing.
