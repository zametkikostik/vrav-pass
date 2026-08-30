import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_provider.dart';
import '../../core/vault/vault_items_provider.dart';
import '../../core/vault/vault_models.dart';
import '../auth/unlock_vault_screen.dart';
import '../home/home_screen.dart';
import '../settings/sync_settings_screen.dart';
import 'add_bookmark_screen.dart';
import 'add_note_screen.dart';
import 'add_password_screen.dart';

class VaultHomeScreen extends ConsumerWidget {
  const VaultHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UnlockVaultScreen()),
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
                  ],
                ),
              ),
            );
          }

          final sorted = [...items]..sort((a, b) {
              if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            });

          return ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              return _VaultItemTile(item: sorted[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        child: const Icon(Icons.add),
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
      trailing: item.favorite ? const Icon(Icons.star, color: Colors.amber) : null,
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
              Text(item.title, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (item is PasswordItem) ..._passwordDetails(ctx, item as PasswordItem),
              if (item is NoteItem)
                SelectableText((item as NoteItem).content),
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
                        await ref.read(vaultItemsProvider.notifier).remove(item.id);
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
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('copied'.tr())),
              );
            },
          ),
        ],
      ),
    );
  }
}
