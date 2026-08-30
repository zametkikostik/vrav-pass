import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_provider.dart';
import '../auth/unlock_vault_screen.dart';
import '../home/home_screen.dart';

class VaultHomeScreen extends ConsumerWidget {
  const VaultHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    // Safety: if somehow locked, go back to unlock
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UnlockVaultScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'vault_unlocked'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'vault_ready_hint'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _FeatureChip(icon: Icons.password, label: 'passwords'.tr()),
                  _FeatureChip(icon: Icons.note_alt_outlined, label: 'notes'.tr()),
                  _FeatureChip(icon: Icons.bookmark_outline, label: 'bookmarks'.tr()),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'next_step_storage'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
