import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'security_settings.dart';
import 'session_provider.dart';

final securitySettingsProvider =
    StateNotifierProvider<SecuritySettingsNotifier, SecuritySettings>((ref) {
  return SecuritySettingsNotifier();
});

class SecuritySettingsNotifier extends StateNotifier<SecuritySettings> {
  SecuritySettingsNotifier() : super(const SecuritySettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await SecuritySettings.load();
  }

  Future<void> update(SecuritySettings s) async {
    state = s;
    await s.save();
  }
}

/// Tracks user activity and locks session after timeout.
final autoLockProvider = Provider<AutoLockController>((ref) {
  final controller = AutoLockController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

class AutoLockController with WidgetsBindingObserver {
  AutoLockController(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  final Ref _ref;
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  void touch() {
    _lastActivity = DateTime.now();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final timeout = _ref.read(securitySettingsProvider).autoLockSeconds;
    if (timeout <= 0) return;
    if (_ref.read(sessionProvider) == null) return;

    _timer = Timer(Duration(seconds: timeout), () {
      final elapsed = DateTime.now().difference(_lastActivity).inSeconds;
      if (elapsed >= timeout) {
        _ref.read(sessionProvider.notifier).lock();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Lock immediately when app goes to background if timeout > 0
      final timeout = _ref.read(securitySettingsProvider).autoLockSeconds;
      if (timeout > 0 && _ref.read(sessionProvider) != null) {
        // Soft: start timer from pause; for max security lock now:
        _ref.read(sessionProvider.notifier).lock();
      }
    }
    if (state == AppLifecycleState.resumed) {
      touch();
    }
  }
}
