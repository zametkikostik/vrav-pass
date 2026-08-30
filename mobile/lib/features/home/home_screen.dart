import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80),
              const SizedBox(height: 24),
              Text(
                'welcome_message'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'tagline'.tr(),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () {
                  // TODO: navigate to unlock / create vault
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('coming_soon'.tr())),
                  );
                },
                icon: const Icon(Icons.vpn_key),
                label: Text('open_vault'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
