import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/vault/vault_items_provider.dart';
import '../../core/vault/vault_models.dart';

class AddBookmarkScreen extends ConsumerStatefulWidget {
  const AddBookmarkScreen({super.key, this.existing});

  final BookmarkItem? existing;

  @override
  ConsumerState<AddBookmarkScreen> createState() => _AddBookmarkScreenState();
}

class _AddBookmarkScreenState extends ConsumerState<AddBookmarkScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _url;
  late final TextEditingController _description;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _url = TextEditingController(text: widget.existing?.url ?? '');
    _description = TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final item = BookmarkItem(
        id: widget.existing?.id,
        title: _title.text.trim(),
        url: _url.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        createdAt: widget.existing?.createdAt,
        updatedAt: DateTime.now().toUtc(),
        tags: widget.existing?.tags ?? const [],
        favorite: widget.existing?.favorite ?? false,
      );
      if (widget.existing == null) {
        await ref.read(vaultItemsProvider.notifier).add(item);
      } else {
        await ref.read(vaultItemsProvider.notifier).updateItem(item);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'add_bookmark'.tr() : 'edit_bookmark'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(labelText: 'title'.tr()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'required'.tr() : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _url,
                  decoration: InputDecoration(labelText: 'url'.tr()),
                  keyboardType: TextInputType.url,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'required'.tr() : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: InputDecoration(labelText: 'description'.tr()),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text('save'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
