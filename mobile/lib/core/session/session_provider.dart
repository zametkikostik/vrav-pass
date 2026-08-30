import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crypto/vault_crypto_service.dart';

/// Holds the currently unlocked vault (or null when locked).
final sessionProvider =
    StateNotifierProvider<SessionNotifier, UnlockedVault?>((ref) {
  return SessionNotifier();
});

class SessionNotifier extends StateNotifier<UnlockedVault?> {
  SessionNotifier() : super(null);

  void unlock(UnlockedVault vault) {
    state = vault;
  }

  void lock() {
    // Best-effort: keys will be GC'd; we don't keep copies elsewhere.
    state = null;
  }

  bool get isUnlocked => state != null;
}

/// Convenience provider for the crypto service singleton.
final vaultCryptoServiceProvider = Provider<VaultCryptoService>((ref) {
  return VaultCryptoService();
});
