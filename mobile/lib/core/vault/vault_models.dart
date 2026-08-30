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
  final String? password;
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

  PasswordItem copyWith({
    String? title,
    String? username,
    String? password,
    String? url,
    String? totpSecret,
    String? notes,
    bool? favorite,
    List<String>? tags,
  }) {
    return PasswordItem(
      id: id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      totpSecret: totpSecret ?? this.totpSecret,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      tags: tags ?? this.tags,
      favorite: favorite ?? this.favorite,
    );
  }
}

class NoteItem extends VaultItem {
  final String content;

  NoteItem({
    super.id,
    required super.title,
    required this.content,
    super.createdAt,
    super.updatedAt,
    super.tags,
    super.favorite,
  }) : super(type: VaultItemType.note);

  NoteItem copyWith({
    String? title,
    String? content,
    bool? favorite,
    List<String>? tags,
  }) {
    return NoteItem(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      tags: tags ?? this.tags,
      favorite: favorite ?? this.favorite,
    );
  }
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

  BookmarkItem copyWith({
    String? title,
    String? url,
    String? description,
    String? folderPath,
    bool? favorite,
    List<String>? tags,
  }) {
    return BookmarkItem(
      id: id,
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      folderPath: folderPath ?? this.folderPath,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      tags: tags ?? this.tags,
      favorite: favorite ?? this.favorite,
    );
  }
}

/// Toggle favorite on any concrete item type.
VaultItem withFavoriteToggled(VaultItem item) {
  if (item is PasswordItem) {
    return item.copyWith(favorite: !item.favorite);
  }
  if (item is NoteItem) {
    return item.copyWith(favorite: !item.favorite);
  }
  if (item is BookmarkItem) {
    return item.copyWith(favorite: !item.favorite);
  }
  return item;
}
