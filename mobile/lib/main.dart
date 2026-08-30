import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
        Locale('bg'),
        Locale('th'),
      ],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: VravPassApp(),
      ),
    ),
  );
}
