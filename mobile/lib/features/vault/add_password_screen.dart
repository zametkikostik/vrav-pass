import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/totp.dart';
import '../../core/vault/vault_items_provider.dart';
import '../../core/vault/vault_models.dart';
import 'password_generator_sheet.dart';

class AddPasswordScreen extends ConsumerStatefulWidget {
  const AddPasswordScreen({super.key, this.existing});

  final PasswordItem? existing;

  @override
  ConsumerState<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends ConsumerState<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _url;
  late final TextEditingController _totp;
  late final TextEditingController _notes;
  bool _obscure = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _username = TextEditingController(text: e?.username ?? '');
    _password = TextEditingController(text: e?.password ?? '');
    _url = TextEditingController(text: e?.url ?? '');
    _totp = TextEditingController(text: e?.totpSecret ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _url.dispose();
    _totp.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _openGenerator() async {
    final pwd = await showPasswordGeneratorSheet(context);
    if (pwd != null) {
      setState(() {
        _password.text = pwd;
        _obscure = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final item = PasswordItem(
        id: widget.existing?.id,
        title: _title.text.trim(),
        username: _username.text.trim().isEmpty ? null : _username.text.trim(),
        password: _password.text.isEmpty ? null : _password.text,
        url: _url.text.trim().isEmpty ? null : _url.text.trim(),
        totpSecret: _totp.text.trim().isEmpty ? null : _totp.text.trim().replaceAll(' ', ''),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
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
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'edit_password'.tr() : 'add_password'.tr()),
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
                  controller: _username,
                  decoration: InputDecoration(labelText: 'username'.tr()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'password'.tr(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'generate_password'.tr(),
                          icon: const Icon(Icons.auto_awesome),
                          onPressed: _openGenerator,
                        ),
                        IconButton(
                          icon: Icon(
                              _obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _url,
                  decoration: InputDecoration(labelText: 'url'.tr()),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _totp,
                  decoration: InputDecoration(
                    labelText: 'totp_secret'.tr(),
                    hintText: 'totp_hint'.tr(),
                    suffixIcon: IconButton(
                      tooltip: 'generate_totp_secret'.tr(),
                      icon: const Icon(Icons.vpn_key),
                      onPressed: () {
                        setState(() {
                          _totp.text = Totp.generateSecret();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  decoration: InputDecoration(labelText: 'notes'.tr()),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('save'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
