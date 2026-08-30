import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/desktop/desktop_bridge.dart';
import 'core/session/auto_lock_controller.dart';
import 'core/session/session_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/unlock_vault_screen.dart';
import 'features/home/home_screen.dart';

class VravPassApp extends ConsumerWidget {
  const VravPassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(autoLockProvider);
    // Desktop: local API for native messaging host
    ref.watch(desktopBridgeProvider);

    ref.listen(sessionProvider, (prev, next) {
      if (prev != null && next == null) {
        // lock handled by screens
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
      routes: {
        '/unlock': (_) => const UnlockVaultScreen(),
      },
    );
  }
}
