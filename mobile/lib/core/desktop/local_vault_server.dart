import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import '../vault/vault_models.dart';
import '../vault/vault_repository.dart';

/// Tiny localhost-only HTTP API used by the Native Messaging host.
///
/// Listens on 127.0.0.1 only. Token required on every request.
/// Does not serve plaintext over the network beyond localhost.
class LocalVaultServer {
  LocalVaultServer({
    required this.dek,
    required this.authToken,
    this.port = 17321,
  });

  final SecretKey dek;
  final String authToken;
  final int port;

  HttpServer? _server;
  bool get isRunning => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server!.listen(_handle);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handle(HttpRequest req) async {
    // CORS not needed; host is same machine
    void json(int code, Map<String, dynamic> body) {
      req.response.statusCode = code;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode(body));
      req.response.close();
    }

    final auth = req.headers.value('authorization') ?? '';
    final token = auth.startsWith('Bearer ') ? auth.substring(7) : auth;
    if (token != authToken) {
      json(401, {'ok': false, 'error': 'unauthorized'});
      return;
    }

    try {
      final path = req.uri.path;
      if (req.method == 'GET' && path == '/ping') {
        json(200, {'ok': true, 'service': 'vrav-desktop', 'version': '0.1.0'});
        return;
      }
      if (req.method == 'GET' && path == '/status') {
        json(200, {'ok': true, 'unlocked': true});
        return;
      }
      if (req.method == 'GET' && path == '/find') {
        final url = req.uri.queryParameters['url'] ?? '';
        final matches = await _findForUrl(url);
        json(200, {'ok': true, 'matches': matches});
        return;
      }
      json(404, {'ok': false, 'error': 'not found'});
    } catch (e) {
      json(500, {'ok': false, 'error': e.toString()});
    }
  }

  Future<List<Map<String, dynamic>>> _findForUrl(String url) async {
    if (url.isEmpty) return [];
    final repo = VaultRepository(dek: dek);
    final items = await repo.loadAll();
    final host = _hostOf(url);
    final out = <Map<String, dynamic>>[];
    for (final it in items) {
      if (it is! PasswordItem) continue;
      final u = it.url;
      if (u == null || u.isEmpty) continue;
      if (_hostOf(u) == host || u.contains(host) || host.contains(_hostOf(u))) {
        out.add({
          'id': it.id,
          'title': it.title,
          'username': it.username,
          'password': it.password,
          'url': it.url,
        });
      }
    }
    return out;
  }

  String _hostOf(String url) {
    try {
      final u = Uri.parse(url.contains('://') ? url : 'https://$url');
      return (u.host).toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return url.toLowerCase();
    }
  }
}
