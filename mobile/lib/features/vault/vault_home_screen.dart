import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_provider.dart';
import '../../core/util/secure_clipboard.dart';
import '../../core/vault/vault_items_provider.dart';
import '../../core/vault/vault_models.dart';
import '../auth/unlock_vault_screen.dart';
import '../home/home_screen.dart';
import '../settings/import_hub_screen.dart';
import '../settings/security_settings_screen.dart';
import '../settings/sync_settings_screen.dart';
import 'add_bookmark_screen.dart';
import 'add_note_screen.dart';
import 'add_password_screen.dart';
import 'totp_code_widget.dart';

enum _TypeFilter { all, password, note, bookmark }

class VaultHomeScreen extends ConsumerStatefulWidget {
  const VaultHomeScreen({super.key});

  @override
  ConsumerState<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends ConsumerState<VaultHomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _TypeFilter _typeFilter = _TypeFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<VaultItem> _filter(List<VaultItem> items) {
    var list = items;
    switch (_typeFilter) {
      case _TypeFilter.all:
        break;
      case _TypeFilter.password:
        list = list.where((e) => e.type == VaultItemType.password).toList();
        break;
      case _TypeFilter.note:
        list = list.where((e) => e.type == VaultItemType.note).toList();
        break;
      case _TypeFilter.bookmark:
        list = list.where((e) => e.type == VaultItemType.bookmark).toList();
        break;
    }

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((item) {
      if (item.title.toLowerCase().contains(q)) return true;
      if (item is PasswordItem) {
        final u = item.username?.toLowerCase() ?? '';
        final url = item.url?.toLowerCase() ?? '';
        final n = item.notes?.toLowerCase() ?? '';
        return u.contains(q) || url.contains(q) || n.contains(q);
      }
      if (item is NoteItem) return item.content.toLowerCase().contains(q);
      if (item is BookmarkItem) {
        final d = item.description?.toLowerCase() ?? '';
        return item.url.toLowerCase().contains(q) || d.contains(q);
      }
      return false;
    }).toList();
  }

  void _openImport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportHubScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const UnlockVaultScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final itemsAsync = ref.watch(vaultItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        actions: [
          IconButton(
            tooltip: 'import_hub'.tr(),
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _openImport,
          ),
          IconButton(
            tooltip: 'security'.tr(),
            icon: const Icon(Icons.shield_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SecuritySettingsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'settings'.tr(),
            icon: const Icon(Icons.cloud_sync_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SyncSettingsScreen()),
              );
            },
          ),
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (locale) => context.setLocale(locale),
            itemBuilder: (context) => const [
              PopupMenuItem(value: Locale('ru'), child: Text('Русский')),
              PopupMenuItem(value: Locale('en'), child: Text('English')),
              PopupMenuItem(value: Locale('bg'), child: Text('Български')),
              PopupMenuItem(value: Locale('th'), child: Text('ไทย')),
            ],
          ),
          IconButton(
            tooltip: 'lock'.tr(),
            icon: const Icon(Icons.lock_outline),
            onPressed: () {
              ref.read(sessionProvider.notifier).lock();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'vault_empty'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _openImport,
                      icon: const Icon(Icons.file_download_outlined),
                      label: Text('import_hub'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = _filter(items);
          final sorted = [...filtered]..sort((a, b) {
              if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'search'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _chip(_TypeFilter.all, 'filter_all'.tr()),
                    _chip(_TypeFilter.password, 'passwords'.tr()),
                    _chip(_TypeFilter.note, 'notes'.tr()),
                    _chip(_TypeFilter.bookmark, 'bookmarks'.tr()),
                  ],
                ),
              ),
              Expanded(
                child: sorted.isEmpty
                    ? Center(child: Text('search_empty'.tr()))
                    : ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          return _VaultItemTile(item: sorted[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _chip(_TypeFilter value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _typeFilter == value,
        onSelected: (_) => setState(() => _typeFilter = value),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.password),
              title: Text('add_password'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddPasswordScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_alt_outlined),
              title: Text('add_note'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddNoteScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: Text('add_bookmark'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddBookmarkScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: Text('import_hub'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                _openImport();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultItemTile extends ConsumerWidget {
  const _VaultItemTile({required this.item});

  final VaultItem item;

  IconData get _icon {
    switch (item.type) {
      case VaultItemType.password:
        return Icons.password;
      case VaultItemType.note:
        return Icons.note_alt_outlined;
      case VaultItemType.bookmark:
        return Icons.bookmark_outline;
      case VaultItemType.identity:
        return Icons.badge_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = item is PasswordItem
        ? (item as PasswordItem).username ?? (item as PasswordItem).url
        : item is BookmarkItem
            ? (item as BookmarkItem).url
            : item is NoteItem
                ? ((item as NoteItem).content.length > 60
                    ? '${(item as NoteItem).content.substring(0, 60)}…'
                    : (item as NoteItem).content)
                : null;

    return ListTile(
      leading: CircleAvatar(child: Icon(_icon, size: 20)),
      title: Text(item.title),
      subtitle: subtitle != null && subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: IconButton(
        tooltip: 'favorite'.tr(),
        icon: Icon(
          item.favorite ? Icons.star : Icons.star_border,
          color: item.favorite ? Colors.amber : null,
        ),
        onPressed: () {
          ref.read(vaultItemsProvider.notifier).toggleFavorite(item);
        },
      ),
      onTap: () => _showDetail(context, ref),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.title,
                        style: Theme.of(ctx).textTheme.titleLarge),
                  ),
                  IconButton(
                    tooltip: 'favorite'.tr(),
                    icon: Icon(
                      item.favorite ? Icons.star : Icons.star_border,
                      color: item.favorite ? Colors.amber : null,
                    ),
                    onPressed: () async {
                      await ref
                          .read(vaultItemsProvider.notifier)
                          .toggleFavorite(item);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (item is PasswordItem)
                ..._passwordDetails(ctx, item as PasswordItem),
              if (item is NoteItem) SelectableText((item as NoteItem).content),
              if (item is BookmarkItem) ...[
                _copyRow(ctx, 'url'.tr(), (item as BookmarkItem).url),
                if ((item as BookmarkItem).description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text((item as BookmarkItem).description!),
                  ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openEdit(context);
                      },
                      icon: const Icon(Icons.edit),
                      label: Text('edit'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(vaultItemsProvider.notifier)
                            .remove(item.id);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text('delete'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(ctx).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  void _openEdit(BuildContext context) {
    if (item is PasswordItem) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddPasswordScreen(existing: item as PasswordItem),
        ),
      );
    } else if (item is NoteItem) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddNoteScreen(existing: item as NoteItem),
        ),
      );
    } else if (item is BookmarkItem) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddBookmarkScreen(existing: item as BookmarkItem),
        ),
      );
    }
  }

  List<Widget> _passwordDetails(BuildContext context, PasswordItem p) {
    return [
      if (p.username != null) _copyRow(context, 'username'.tr(), p.username!),
      if (p.password != null)
        _copyRow(context, 'password'.tr(), p.password!, secret: true),
      if (p.url != null) _copyRow(context, 'url'.tr(), p.url!),
      if (p.totpSecret != null && p.totpSecret!.isNotEmpty)
        TotpCodeWidget(secret: p.totpSecret!),
      if (p.notes != null && p.notes!.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(p.notes!),
      ],
    ];
  }

  Widget _copyRow(BuildContext context, String label, String value,
      {bool secret = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(secret ? '••••••••' : value),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await SecureClipboard.copy(value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('copied_clears'.tr())),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
