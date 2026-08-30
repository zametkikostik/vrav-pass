import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/import/bitwarden_import.dart';
import '../../core/vault/vault_items_provider.dart';

class ImportBitwardenScreen extends ConsumerStatefulWidget {
  const ImportBitwardenScreen({super.key});

  @override
  ConsumerState<ImportBitwardenScreen> createState() =>
      _ImportBitwardenScreenState();
}

class _ImportBitwardenScreenState extends ConsumerState<ImportBitwardenScreen> {
  bool _busy = false;
  String? _status;
  int? _previewCount;

  Future<void> _pickAndImport() async {
    setState(() {
      _busy = true;
      _status = null;
      _previewCount = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'txt'],
        withData: true,
      );
      if (result == null) {
        setState(() => _busy = false);
        return;
      }

      String raw;
      final file = result.files.single;
      if (file.bytes != null) {
        raw = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        raw = await File(file.path!).readAsString();
      } else {
        throw StateError('Cannot read file');
      }

      final items = BitwardenImport().parse(raw);
      if (items.isEmpty) {
        setState(() {
          _status = 'import_empty'.tr();
          _busy = false;
        });
        return;
      }

      setState(() => _previewCount = items.length);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('import_bitwarden'.tr()),
          content: Text('import_confirm'.tr(args: ['${items.length}'])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('import'.tr()),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() => _busy = false);
        return;
      }

      await ref.read(vaultItemsProvider.notifier).importMany(items);
      setState(() {
        _status = 'import_ok_count'.tr(args: ['${items.length}']);
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _status = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('import_bitwarden'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'import_bitwarden_hint'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'import_bitwarden_steps'.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _pickAndImport,
            icon: const Icon(Icons.upload_file),
            label: Text('choose_file'.tr()),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_previewCount != null) ...[
            const SizedBox(height: 16),
            Text('${'import_preview'.tr()}: $_previewCount'),
          ],
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(_status!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
