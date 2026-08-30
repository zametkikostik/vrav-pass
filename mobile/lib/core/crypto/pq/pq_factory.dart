import '../hybrid_kem.dart';
import 'ml_kem_adapter.dart';
import 'ml_kem_ffi.dart';
import 'ml_kem_interface.dart';
import 'ml_kem_stub.dart';

/// Resolve best available ML-KEM implementation.
MlKem768 createMlKem768() {
  final native = MlKem768Ffi.tryLoad();
  if (native != null) return native;
  return MlKem768Stub();
}

/// Hybrid KEM with real or stub PQ leg.
HybridKem createHybridKem() {
  final mlkem = createMlKem768();
  return HybridKem(pq: MlKemPostQuantumAdapter(mlkem));
}

bool get isPostQuantumNative => createMlKem768().isNative;
