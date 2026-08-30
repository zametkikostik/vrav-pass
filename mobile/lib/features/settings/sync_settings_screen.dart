import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/sync/sync_models.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/vault/vault_items_provider.dart';
import 'export_json_helper.dart';

class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pathCtrl = TextEditingController(text: '/vrav-pass/vault.v1.enc');
  bool _obscure = true;
  bool _loading = true;
  bool _busy = false;
  String? _status;
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(syncServiceProvider);
    if (svc == null) return;
    final cfg = await svc.loadConfig();
    setState(() {
      _urlCtrl.text = cfg.webdavUrl ?? '';
      _userCtrl.text = cfg.webdavUsername ?? '';
      _passCtrl.text = cfg.webdavPassword ?? '';
      _pathCtrl.text = cfg.remotePath;
      _lastSync = cfg.lastSyncAt;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final svc = ref.read(syncServiceProvider);
    if (svc == null) return;
    final cfg = SyncConfig(
      webdavUrl: _urlCtrl.text.trim(),
      webdavUsername: _userCtrl.text.trim(),
      webdavPassword: _passCtrl.text,
      remotePath: _pathCtrl.text.trim().isEmpty
          ? '/vrav-pass/vault.v1.enc'
          : _pathCtrl.text.trim(),
      lastSyncAt: _lastSync,
    );
    await svc.saveConfig(cfg);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('saved'.tr())),
      );
    }
  }

  Future<void> _upload() async {
    await _saveConfig();
    setState(() {
      _busy = true;
      _status = null;
    });
    final svc = ref.read(syncServiceProvider);
    final result = await svc!.uploadToWebDav();
    setState(() {
      _busy = false;
      _status = result.message;
      if (result.success) _lastSync = DateTime.now().toUtc();
    });
  }

  Future<void> _download() async {
    await _saveConfig();
    setState(() {
      _busy = true;
      _status = null;
    });
    final svc = ref.read(syncServiceProvider);
    final result = await svc!.downloadFromWebDav();
    if (result.success) {
      await ref.read(vaultItemsProvider.notifier).refresh();
    }
    setState(() {
      _busy = false;
      _status = result.message;
      if (result.success) _lastSync = DateTime.now().toUtc();
    });
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final svc = ref.read(syncServiceProvider)!;
      final file = await svc.exportToFile();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Vrav Pass encrypted vault',
      );
      setState(() => _status = 'export_ok'.tr());
    } catch (e) {
      setState(() => _status = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _busy = true);
    try {
      final svc = ref.read(syncServiceProvider)!;
      await svc.importFromFile(File(result.files.single.path!));
      await ref.read(vaultItemsProvider.notifier).refresh();
      setState(() => _status = 'import_ok'.tr());
    } catch (e) {
      setState(() => _status = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _exportJson() async {
    setState(() => _busy = true);
    try {
      final items = ref.read(vaultItemsProvider).valueOrNull ?? [];
      await exportItemsAsJson(items);
      setState(() => _status = 'export_json_ok'.tr());
    } catch (e) {
      setState(() => _status = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('sync_settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'sync_e2ee_hint'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          Text('webdav'.tr(), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              labelText: 'webdav_url'.tr(),
              hintText: 'https://webdav.yandex.ru',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userCtrl,
            decoration: InputDecoration(labelText: 'username'.tr()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'password'.tr(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pathCtrl,
            decoration: InputDecoration(labelText: 'remote_path'.tr()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _upload,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text('upload'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _download,
                  icon: const Icon(Icons.cloud_download),
                  label: Text('download'.tr()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : _saveConfig,
            child: Text('save_config'.tr()),
          ),

          if (_lastSync != null) ...[
            const SizedBox(height: 8),
            Text(
              '${'last_sync'.tr()}: ${_lastSync!.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],

          const Divider(height: 40),

          Text('file_export_import'.tr(),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _export,
                  icon: const Icon(Icons.share),
                  label: Text('export'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.file_open),
                  label: Text('import'.tr()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportJson,
            icon: const Icon(Icons.data_object),
            label: Text('export_json_extension'.tr()),
          ),
          Text(
            'export_json_warning'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),

          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(
              _status!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],

          const SizedBox(height: 32),
          Text(
            'yandex_hint'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
