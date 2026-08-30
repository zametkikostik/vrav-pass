import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/crypto/vault_crypto_service.dart';
import '../../core/session/auto_lock_controller.dart';
import '../../core/session/biometric_service.dart';
import '../../core/session/biometric_vault_unlock.dart';
import '../../core/session/session_provider.dart';
import '../vault/vault_home_screen.dart';

class UnlockVaultScreen extends ConsumerStatefulWidget {
  const UnlockVaultScreen({super.key});

  @override
  ConsumerState<UnlockVaultScreen> createState() => _UnlockVaultScreenState();
}

class _UnlockVaultScreenState extends ConsumerState<UnlockVaultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _bio = BiometricService();
  final _bioVault = BiometricVaultUnlock();
  bool _obscure = true;
  bool _busy = false;
  bool _showBio = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBio();
  }

  Future<void> _checkBio() async {
    final settings = ref.read(securitySettingsProvider);
    if (!settings.biometricsEnabled) return;
    final available = await _bio.isAvailable();
    final has = await _bioVault.hasSaved();
    if (mounted) {
      setState(() => _showBio = available && has);
      if (_showBio) {
        // Auto-prompt biometric once
        await _unlockWithBio();
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _afterUnlock(dynamic vault) async {
    ref.read(sessionProvider.notifier).unlock(vault);
    final settings = ref.read(securitySettingsProvider);
    if (settings.biometricsEnabled) {
      await _bioVault.saveUnlocked(vault);
    }
    ref.read(autoLockProvider).touch();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const VaultHomeScreen()),
    );
  }

  Future<void> _unlockWithBio() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await _bio.authenticate(reason: 'unlock_with_biometrics'.tr());
      if (!ok) {
        setState(() => _error = 'biometrics_failed'.tr());
        return;
      }
      final vault = await _bioVault.load();
      if (vault == null) {
        setState(() => _error = 'biometrics_no_key'.tr());
        return;
      }
      await _afterUnlock(vault);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final service = ref.read(vaultCryptoServiceProvider);
      final vault = await service.unlockVault(_passwordController.text);
      await _afterUnlock(vault);
    } on WrongMasterPasswordException {
      setState(() => _error = 'wrong_password'.tr());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('unlock'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock, size: 64),
                const SizedBox(height: 16),
                Text(
                  'enter_master_password'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  autofocus: !_showBio,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'master_password'.tr(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'required'.tr();
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('unlock'.tr()),
                ),
                if (_showBio) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _unlockWithBio,
                    icon: const Icon(Icons.fingerprint),
                    label: Text('unlock_biometrics'.tr()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
