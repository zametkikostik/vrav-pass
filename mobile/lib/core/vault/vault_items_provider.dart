import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_provider.dart';
import 'vault_models.dart';
import 'vault_repository.dart';

final vaultRepositoryProvider = Provider<VaultRepository?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  return VaultRepository(dek: session.dek);
});

final vaultItemsProvider =
    AsyncNotifierProvider<VaultItemsNotifier, List<VaultItem>>(
  VaultItemsNotifier.new,
);

class VaultItemsNotifier extends AsyncNotifier<List<VaultItem>> {
  @override
  Future<List<VaultItem>> build() async {
    final repo = ref.watch(vaultRepositoryProvider);
    if (repo == null) return [];
    return repo.loadAll();
  }

  Future<void> refresh() async {
    final repo = ref.read(vaultRepositoryProvider);
    if (repo == null) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(repo.loadAll);
  }

  Future<void> add(VaultItem item) async {
    final repo = ref.read(vaultRepositoryProvider);
    if (repo == null) return;
    await repo.add(item);
    await refresh();
  }

  Future<void> importMany(List<VaultItem> newItems, {bool merge = true}) async {
    final repo = ref.read(vaultRepositoryProvider);
    if (repo == null || newItems.isEmpty) return;
    final existing = merge ? await repo.loadAll() : <VaultItem>[];
    await repo.saveAll([...existing, ...newItems]);
    await refresh();
  }

  Future<void> updateItem(VaultItem item) async {
    final repo = ref.read(vaultRepositoryProvider);
    if (repo == null) return;
    await repo.update(item);
    await refresh();
  }

  Future<void> toggleFavorite(VaultItem item) async {
    await updateItem(withFavoriteToggled(item));
  }

  Future<void> remove(String id) async {
    final repo = ref.read(vaultRepositoryProvider);
    if (repo == null) return;
    await repo.delete(id);
    await refresh();
  }
}
