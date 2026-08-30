import 'package:shared_preferences/shared_preferences.dart';

class SecuritySettings {
  const SecuritySettings({
    this.autoLockSeconds = 120,
    this.biometricsEnabled = false,
  });

  /// 0 = never auto-lock
  final int autoLockSeconds;
  final bool biometricsEnabled;

  static const _keyTimeout = 'sec_auto_lock_seconds';
  static const _keyBio = 'sec_biometrics_enabled';

  SecuritySettings copyWith({
    int? autoLockSeconds,
    bool? biometricsEnabled,
  }) {
    return SecuritySettings(
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    );
  }

  static Future<SecuritySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SecuritySettings(
      autoLockSeconds: prefs.getInt(_keyTimeout) ?? 120,
      biometricsEnabled: prefs.getBool(_keyBio) ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimeout, autoLockSeconds);
    await prefs.setBool(_keyBio, biometricsEnabled);
  }

  static const timeoutOptions = <int, String>{
    0: 'never',
    30: '30s',
    60: '1m',
    120: '2m',
    300: '5m',
    600: '10m',
    1800: '30m',
  };
}
