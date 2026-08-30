import 'package:uuid/uuid.dart';

enum VaultItemType { password, note, bookmark, identity }

class VaultItem {
  final String id;
  final VaultItemType type;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final bool favorite;

  VaultItem({
    String? id,
    required this.type,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.tags = const [],
    this.favorite = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();
}

class PasswordItem extends VaultItem {
  final String? username;
  final String? password; // will be encrypted at rest
  final String? url;
  final String? totpSecret;
  final String? notes;

  PasswordItem({
    super.id,
    required super.title,
    this.username,
    this.password,
    this.url,
    this.totpSecret,
    this.notes,
    super.createdAt,
    super.updatedAt,
    super.tags,
    super.favorite,
  }) : super(type: VaultItemType.password);
}

class NoteItem extends VaultItem {
  final String content; // markdown, encrypted at rest

  NoteItem({
    super.id,
    required super.title,
    required this.content,
    super.createdAt,
    super.updatedAt,
    super.tags,
    super.favorite,
  }) : super(type: VaultItemType.note);
}

class BookmarkItem extends VaultItem {
  final String url;
  final String? description;
  final String? folderPath;

  BookmarkItem({
    super.id,
    required super.title,
    required this.url,
    this.description,
    this.folderPath,
    super.createdAt,
    super.updatedAt,
    super.tags,
    super.favorite,
  }) : super(type: VaultItemType.bookmark);
}
