import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/session/auto_lock_controller.dart';
import 'core/session/session_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/unlock_vault_screen.dart';
import 'features/home/home_screen.dart';

class VravPassApp extends ConsumerWidget {
  const VravPassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure auto-lock controller is created and observes lifecycle
    ref.watch(autoLockProvider);

    // When session becomes null while on a vault route, user must re-unlock
    ref.listen(sessionProvider, (prev, next) {
      if (prev != null && next == null) {
        // Navigating from lock is handled by screens; no-op here
      }
    });

    return MaterialApp(
      title: 'Vrav Pass',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => ref.read(autoLockProvider).touch(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
      // Named route helper for re-lock navigation from anywhere
      routes: {
        '/unlock': (_) => const UnlockVaultScreen(),
      },
    );
  }
}
