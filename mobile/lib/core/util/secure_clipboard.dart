import 'dart:async';

import 'package:flutter/services.dart';

/// Copies text and schedules clearing the clipboard after [ttl].
///
/// Note: on some Android versions other apps may still read history;
/// this is best-effort hygiene, not a hard OS guarantee.
class SecureClipboard {
  SecureClipboard._();

  static Timer? _timer;
  static String? _lastValue;

  static Future<void> copy(
    String value, {
    Duration ttl = const Duration(seconds: 45),
  }) async {
    _timer?.cancel();
    _lastValue = value;
    await Clipboard.setData(ClipboardData(text: value));

    _timer = Timer(ttl, () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      // Only clear if still our value (user may have copied something else)
      if (current?.text == _lastValue) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
      _lastValue = null;
    });
  }

  static void cancelPendingClear() {
    _timer?.cancel();
    _timer = null;
  }
}
