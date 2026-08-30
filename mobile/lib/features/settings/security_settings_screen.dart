import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/auto_lock_controller.dart';
import '../../core/session/biometric_service.dart';
import '../../core/session/biometric_vault_unlock.dart';
import '../../core/session/security_settings.dart';
import '../../core/session/session_provider.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  final _bio = BiometricService();
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    _bio.isAvailable().then((v) {
      if (mounted) setState(() => _bioAvailable = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(securitySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('security'.tr())),
      body: ListView(
        children: [
          ListTile(
            title: Text('auto_lock'.tr()),
            subtitle: Text('auto_lock_hint'.tr()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<int>(
              value: settings.autoLockSeconds,
              decoration: InputDecoration(labelText: 'auto_lock_timeout'.tr()),
              items: SecuritySettings.timeoutOptions.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.key == 0 ? 'never'.tr() : e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                ref
                    .read(securitySettingsProvider.notifier)
                    .update(settings.copyWith(autoLockSeconds: v));
              },
            ),
          ),
          const Divider(height: 32),
          SwitchListTile(
            title: Text('biometrics'.tr()),
            subtitle: Text(
              _bioAvailable
                  ? 'biometrics_hint'.tr()
                  : 'biometrics_unavailable'.tr(),
            ),
            value: settings.biometricsEnabled && _bioAvailable,
            onChanged: !_bioAvailable
                ? null
                : (v) async {
                    if (v) {
                      final ok = await _bio.authenticate(
                        reason: 'enable_biometrics_reason'.tr(),
                      );
                      if (!ok) return;
                      final session = ref.read(sessionProvider);
                      if (session != null) {
                        await BiometricVaultUnlock().saveUnlocked(session);
                      }
                    } else {
                      await BiometricVaultUnlock().clear();
                    }
                    await ref.read(securitySettingsProvider.notifier).update(
                          settings.copyWith(biometricsEnabled: v),
                        );
                  },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'biometrics_security_note'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
