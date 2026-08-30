import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/vault/vault_items_provider.dart';
import '../../core/vault/vault_models.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  const AddNoteScreen({super.key, this.existing});

  final NoteItem? existing;

  @override
  ConsumerState<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _content;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _content = TextEditingController(text: widget.existing?.content ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final item = NoteItem(
        id: widget.existing?.id,
        title: _title.text.trim(),
        content: _content.text,
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
        title: Text(widget.existing == null ? 'add_note'.tr() : 'edit_note'.tr()),
      ),
      body: SafeArea(
        child: Padding(
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
                Expanded(
                  child: TextFormField(
                    controller: _content,
                    decoration: InputDecoration(
                      labelText: 'note_content'.tr(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
                const SizedBox(height: 16),
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
