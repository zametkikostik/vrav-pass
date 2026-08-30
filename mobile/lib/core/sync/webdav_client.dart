import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Minimal WebDAV client for putting/getting a single encrypted blob.
/// Works with Yandex Disk WebDAV, Nextcloud, ownCloud, etc.
class WebDavClient {
  WebDavClient({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  final String baseUrl;
  final String username;
  final String password;

  Map<String, String> get _authHeaders {
    final token = base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': 'Basic $token',
    };
  }

  Uri _uri(String remotePath) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final path = remotePath.startsWith('/') ? remotePath : '/$remotePath';
    return Uri.parse('$base$path');
  }

  /// Ensure parent directories exist (MKCOL).
  Future<void> ensureParentDirs(String remotePath) async {
    final parts = remotePath.split('/').where((e) => e.isNotEmpty).toList();
    if (parts.length <= 1) return;

    var current = '';
    for (var i = 0; i < parts.length - 1; i++) {
      current += '/${parts[i]}';
      final res = await http.Request('MKCOL', _uri(current))
        ..headers.addAll(_authHeaders);
      final streamed = await res.send();
      // 201 created, 405 already exists — both ok
      if (streamed.statusCode != 201 &&
          streamed.statusCode != 405 &&
          streamed.statusCode != 301 &&
          streamed.statusCode != 200) {
        // ignore non-fatal
      }
    }
  }

  Future<void> put(String remotePath, Uint8List data) async {
    await ensureParentDirs(remotePath);
    final res = await http.put(
      _uri(remotePath),
      headers: {
        ..._authHeaders,
        'Content-Type': 'application/octet-stream',
      },
      body: data,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw WebDavException('PUT failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<Uint8List> get(String remotePath) async {
    final res = await http.get(
      _uri(remotePath),
      headers: _authHeaders,
    );
    if (res.statusCode == 404) {
      throw WebDavException('Remote file not found');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw WebDavException('GET failed: ${res.statusCode}');
    }
    return Uint8List.fromList(res.bodyBytes);
  }

  Future<bool> exists(String remotePath) async {
    final res = await http.head(
      _uri(remotePath),
      headers: _authHeaders,
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}

class WebDavException implements Exception {
  WebDavException(this.message);
  final String message;
  @override
  String toString() => 'WebDavException: $message';
}
