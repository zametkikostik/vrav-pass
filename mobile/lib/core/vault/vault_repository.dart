import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../crypto/crypto_engine.dart';
import 'vault_models.dart';

/// Local encrypted vault storage.
///
/// Format on disk:
///   vault.v1.enc  = AES-256-GCM( JSON(list of items) )
///
/// Only ciphertext is written. Keys never leave memory.
class VaultRepository {
  VaultRepository({
    required this.dek,
    CryptoEngine? engine,
  }) : _engine = engine ?? CryptoEngine.instance;

  final SecretKey dek;
  final CryptoEngine _engine;

  static const _fileName = 'vault.v1.enc';
  static const _aad = 'vrav-vault-v1';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  /// Load all items. Returns empty list if file does not exist.
  Future<List<VaultItem>> loadAll() async {
    final file = await _file();
    if (!await file.exists()) return [];

    final cipher = await file.readAsBytes();
    final plain = await _engine.decrypt(
      key: dek,
      data: Uint8List.fromList(cipher),
      aad: utf8.encode(_aad),
    );

    final list = jsonDecode(utf8.decode(plain)) as List<dynamic>;
    return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Replace entire vault content (atomic write).
  Future<void> saveAll(List<VaultItem> items) async {
    final jsonList = items.map(_toJson).toList();
    final plain = Uint8List.fromList(utf8.encode(jsonEncode(jsonList)));
    final cipher = await _engine.encrypt(
      key: dek,
      plaintext: plain,
      aad: utf8.encode(_aad),
    );

    final file = await _file();
    // Write to temp then rename for safer replace
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(cipher, flush: true);
    if (await file.exists()) await file.delete();
    await tmp.rename(file.path);
  }

  Future<void> add(VaultItem item) async {
    final items = await loadAll();
    items.add(item);
    await saveAll(items);
  }

  Future<void> update(VaultItem item) async {
    final items = await loadAll();
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx < 0) throw StateError('Item not found');
    items[idx] = item;
    await saveAll(items);
  }

  Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((e) => e.id == id);
    await saveAll(items);
  }

  Map<String, dynamic> _toJson(VaultItem item) {
    final base = {
      'id': item.id,
      'type': item.type.name,
      'title': item.title,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': item.updatedAt.toIso8601String(),
      'tags': item.tags,
      'favorite': item.favorite,
    };

    if (item is PasswordItem) {
      return {
        ...base,
        'username': item.username,
        'password': item.password,
        'url': item.url,
        'totpSecret': item.totpSecret,
        'notes': item.notes,
      };
    }
    if (item is NoteItem) {
      return {...base, 'content': item.content};
    }
    if (item is BookmarkItem) {
      return {
        ...base,
        'url': item.url,
        'description': item.description,
        'folderPath': item.folderPath,
      };
    }
    return base;
  }

  VaultItem _fromJson(Map<String, dynamic> j) {
    final type = VaultItemType.values.byName(j['type'] as String);
    final id = j['id'] as String;
    final title = j['title'] as String;
    final createdAt = DateTime.parse(j['createdAt'] as String);
    final updatedAt = DateTime.parse(j['updatedAt'] as String);
    final tags = (j['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    final favorite = j['favorite'] as bool? ?? false;

    switch (type) {
      case VaultItemType.password:
        return PasswordItem(
          id: id,
          title: title,
          username: j['username'] as String?,
          password: j['password'] as String?,
          url: j['url'] as String?,
          totpSecret: j['totpSecret'] as String?,
          notes: j['notes'] as String?,
          createdAt: createdAt,
          updatedAt: updatedAt,
          tags: tags,
          favorite: favorite,
        );
      case VaultItemType.note:
        return NoteItem(
          id: id,
          title: title,
          content: j['content'] as String? ?? '',
          createdAt: createdAt,
          updatedAt: updatedAt,
          tags: tags,
          favorite: favorite,
        );
      case VaultItemType.bookmark:
        return BookmarkItem(
          id: id,
          title: title,
          url: j['url'] as String? ?? '',
          description: j['description'] as String?,
          folderPath: j['folderPath'] as String?,
          createdAt: createdAt,
          updatedAt: updatedAt,
          tags: tags,
          favorite: favorite,
        );
      case VaultItemType.identity:
        return VaultItem(
          id: id,
          type: type,
          title: title,
          createdAt: createdAt,
          updatedAt: updatedAt,
          tags: tags,
          favorite: favorite,
        );
    }
  }
}
