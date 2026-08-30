import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../session/session_provider.dart';
import 'local_vault_server.dart';

final desktopBridgeProvider = Provider<DesktopBridge>((ref) {
  final bridge = DesktopBridge(ref);
  ref.onDispose(() => bridge.stop());
  // React to session
  ref.listen(sessionProvider, (prev, next) {
    if (next != null) {
      bridge.start(next.dek);
    } else {
      bridge.stop();
    }
  });
  return bridge;
});

class DesktopBridge {
  DesktopBridge(this._ref);

  final Ref _ref;
  LocalVaultServer? _server;
  String? _token;

  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  Future<void> start(dynamic dek) async {
    if (!isDesktop) return;
    await stop();
    _token = _randomToken();
    _server = LocalVaultServer(dek: dek, authToken: _token!);
    await _server!.start();
    await _writeHostConfig();
  }

  Future<void> stop() async {
    await _server?.stop();
    _server = null;
    await _clearHostConfig();
  }

  /// Host reads this file to know token + port.
  Future<void> _writeHostConfig() async {
    final file = await _configFile();
    await file.writeAsString(
      '{"port":${_server!.port},"token":"$_token","version":"0.1.0"}\n',
      flush: true,
    );
  }

  Future<void> _clearHostConfig() async {
    try {
      final file = await _configFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<File> _configFile() async {
    // Stable path the Python host can find
    if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '.';
      final dir = Directory('$home/.config/vrav-pass');
      if (!await dir.exists()) await dir.create(recursive: true);
      return File('${dir.path}/desktop-api.json');
    }
    if (Platform.isWindows) {
      final appdata = Platform.environment['APPDATA'] ?? '.';
      final dir = Directory('$appdata\\vrav-pass');
      if (!await dir.exists()) await dir.create(recursive: true);
      return File('${dir.path}\\desktop-api.json');
    }
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/desktop-api.json');
  }

  String _randomToken() {
    final r = Random.secure();
    final bytes = List<int>.generate(24, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
