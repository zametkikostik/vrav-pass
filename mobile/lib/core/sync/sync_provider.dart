import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_provider.dart';
import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  return SyncService(dek: session.dek);
});
