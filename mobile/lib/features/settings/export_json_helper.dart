import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/vault/vault_models.dart';

/// Export vault items as JSON for browser extension import bridge.
/// WARNING: This file contains plaintext secrets — share only via secure channel
/// and delete after import. Prefer E2EE .enc + future Argon2 in extension.
Future<void> exportItemsAsJson(List<VaultItem> items) async {
  final list = items.map((item) {
    if (item is PasswordItem) {
      return {
        'type': 'password',
        'id': item.id,
        'title': item.title,
        'username': item.username,
        'password': item.password,
        'url': item.url,
        'notes': item.notes,
      };
    }
    if (item is NoteItem) {
      return {
        'type': 'note',
        'id': item.id,
        'title': item.title,
        'content': item.content,
      };
    }
    if (item is BookmarkItem) {
      return {
        'type': 'bookmark',
        'id': item.id,
        'title': item.title,
        'url': item.url,
        'description': item.description,
      };
    }
    return {'type': item.type.name, 'id': item.id, 'title': item.title};
  }).toList();

  final json = const JsonEncoder.withIndent('  ').convert(list);
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, 'vrav-pass-items.json'));
  await file.writeAsString(json);
  await Share.shareXFiles([XFile(file.path)], text: 'Vrav Pass items (sensitive)');
}
