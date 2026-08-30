/// Runtime / compile-time configuration.
///
/// Fill [googleServerClientId] with the **Web** OAuth client ID from
/// Google Cloud Console (needed by google_sign_in on Android for ID token).
/// Android client is matched by package name + SHA-1 — no string needed here.
///
/// You can also pass via --dart-define:
///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
class AppConfig {
  AppConfig._();

  /// Web client ID (OAuth 2.0 Client type "Web application").
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '', // <-- paste your Web client ID or use --dart-define
  );

  static bool get hasGoogleOAuth => googleServerClientId.isNotEmpty;
}
