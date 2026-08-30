import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_provider.dart';
import '../auth/create_vault_screen.dart';
import '../auth/unlock_vault_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool? _vaultExists;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkVault();
  }

  Future<void> _checkVault() async {
    final exists = await ref.read(vaultCryptoServiceProvider).vaultExists();
    if (mounted) {
      setState(() {
        _vaultExists = exists;
        _loading = false;
      });
    }
  }

  void _open() {
    if (_vaultExists == true) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UnlockVaultScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateVaultScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        actions: [
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
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'welcome_message'.tr(),
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'tagline'.tr(),
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _OnboardPoint(
                      icon: Icons.cloud_off_outlined,
                      text: 'onboard_no_servers'.tr(),
                    ),
                    _OnboardPoint(
                      icon: Icons.lock_outline,
                      text: 'onboard_encrypted'.tr(),
                    ),
                    _OnboardPoint(
                      icon: Icons.key_outlined,
                      text: 'onboard_master'.tr(),
                    ),
                    const SizedBox(height: 40),
                    FilledButton.icon(
                      onPressed: _open,
                      icon: Icon(
                        _vaultExists == true ? Icons.lock_open : Icons.vpn_key,
                      ),
                      label: Text(
                        _vaultExists == true
                            ? 'open_vault'.tr()
                            : 'create_vault'.tr(),
                      ),
                    ),
                    if (_vaultExists != true) ...[
                      const SizedBox(height: 12),
                      Text(
                        'onboard_create_hint'.tr(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _OnboardPoint extends StatelessWidget {
  const _OnboardPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
