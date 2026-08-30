# Post-quantum cryptography in Vrav Pass

## Design

Hybrid KEM (see `mobile/lib/core/crypto/hybrid_kem.dart`):

```
ss = HKDF-SHA512( ss_X25519 || ss_ML-KEM-768 )
```

- Classical: **X25519** (via `package:cryptography`) — production ready
- PQ: **ML-KEM-768** (Kyber) — interface ready, real impl pending

## Current status

| Component | Status |
|-----------|--------|
| X25519 ECDH | ✅ |
| Hybrid API + HKDF combine | ✅ |
| `PostQuantumKem` interface | ✅ |
| Placeholder PQ (NOT quantum-safe) | ⚠️ structural only |
| Real ML-KEM-768 | 📋 liboqs FFI or pure-Dart |

`PlaceholderPqKem.isRealImplementation == false` — do not claim PQ security yet.

## Enabling real ML-KEM

Options:

1. **liboqs** via Dart FFI (recommended for production)
2. Pure-Dart ML-KEM when a audited package appears
3. Platform channels to native PQ libs on Android/iOS

Wire a class `MlKem768` implementing `PostQuantumKem` and pass it to `HybridKem(pq: MlKem768())`.

## Where hybrid KEM will be used

- Multi-device pairing / recovery shares (future)
- Secure sharing links between users (future)
- Not required for local Argon2id + AES-GCM vault (symmetric)
