/// Cloud sync configuration (stored encrypted or in secure storage).
class SyncConfig {
  const SyncConfig({
    this.webdavUrl,
    this.webdavUsername,
    this.webdavPassword,
    this.remotePath = '/vrav-pass/vault.v1.enc',
    this.lastSyncAt,
  });

  final String? webdavUrl;
  final String? webdavUsername;
  final String? webdavPassword;
  final String remotePath;
  final DateTime? lastSyncAt;

  bool get hasWebdav =>
      webdavUrl != null &&
      webdavUrl!.isNotEmpty &&
      webdavUsername != null &&
      webdavPassword != null;

  SyncConfig copyWith({
    String? webdavUrl,
    String? webdavUsername,
    String? webdavPassword,
    String? remotePath,
    DateTime? lastSyncAt,
  }) {
    return SyncConfig(
      webdavUrl: webdavUrl ?? this.webdavUrl,
      webdavUsername: webdavUsername ?? this.webdavUsername,
      webdavPassword: webdavPassword ?? this.webdavPassword,
      remotePath: remotePath ?? this.remotePath,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'webdavUrl': webdavUrl,
        'webdavUsername': webdavUsername,
        // password stored separately in secure storage
        'remotePath': remotePath,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
      };

  factory SyncConfig.fromJson(Map<String, dynamic> j) => SyncConfig(
        webdavUrl: j['webdavUrl'] as String?,
        webdavUsername: j['webdavUsername'] as String?,
        remotePath: j['remotePath'] as String? ?? '/vrav-pass/vault.v1.enc',
        lastSyncAt: j['lastSyncAt'] != null
            ? DateTime.tryParse(j['lastSyncAt'] as String)
            : null,
      );
}

enum SyncDirection { upload, download }

class SyncResult {
  SyncResult({
    required this.success,
    this.message,
    this.bytes,
  });

  final bool success;
  final String? message;
  final int? bytes;
}
