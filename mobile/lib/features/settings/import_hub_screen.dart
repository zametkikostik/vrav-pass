import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/import/bitwarden_import.dart';
import '../../core/import/chrome_import.dart';
import '../../core/vault/vault_items_provider.dart';
import '../../core/vault/vault_models.dart';

enum ImportSource { bitwarden, chrome }

class ImportHubScreen extends ConsumerStatefulWidget {
  const ImportHubScreen({super.key, this.initial = ImportSource.bitwarden});

  final ImportSource initial;

  @override
  ConsumerState<ImportHubScreen> createState() => _ImportHubScreenState();
}

class _ImportHubScreenState extends ConsumerState<ImportHubScreen> {
  late ImportSource _source;
  bool _busy = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _source = widget.initial;
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _status = null;
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

      final file = result.files.single;
      final String raw;
      if (file.bytes != null) {
        raw = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        raw = await File(file.path!).readAsString();
      } else {
        throw StateError('Cannot read file');
      }

      final List<VaultItem> items;
      if (_source == ImportSource.chrome) {
        items = ChromeImport().parse(raw);
      } else {
        items = BitwardenImport().parse(raw);
      }

      if (items.isEmpty) {
        setState(() {
          _status = 'import_empty'.tr();
          _busy = false;
        });
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('import'.tr()),
          content: Text(
            '${'import_confirm_prefix'.tr()} ${items.length} ${'import_confirm_suffix'.tr()}',
          ),
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
        _status =
            '${'import_ok_prefix'.tr()} ${items.length} ${'import_ok_suffix'.tr()}';
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
      appBar: AppBar(title: Text('import_hub'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('import_hub_hint'.tr(),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          SegmentedButton<ImportSource>(
            segments: [
              ButtonSegment(
                value: ImportSource.bitwarden,
                label: Text('import_bitwarden_short'.tr()),
                icon: const Icon(Icons.lock_outline),
              ),
              ButtonSegment(
                value: ImportSource.chrome,
                label: Text('import_chrome_short'.tr()),
                icon: const Icon(Icons.language),
              ),
            ],
            selected: {_source},
            onSelectionChanged: (s) => setState(() => _source = s.first),
          ),
          const SizedBox(height: 16),
          Text(
            _source == ImportSource.chrome
                ? 'import_chrome_steps'.tr()
                : 'import_bitwarden_steps'.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.upload_file),
            label: Text('choose_file'.tr()),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
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
