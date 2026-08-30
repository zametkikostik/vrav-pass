import 'package:uuid/uuid.dart';

import '../vault/vault_models.dart';

/// Import passwords exported from Chrome / Edge / Chromium.
///
/// Chrome: Settings → Passwords → ⋮ → Export passwords → CSV
/// Columns typically: name,url,username,password,note
class ChromeImport {
  ChromeImport({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  List<VaultItem> parse(String raw) {
    final lines = const LineSplitter().convert(raw.trim());
    if (lines.isEmpty) return [];

    final header =
        _splitCsvLine(lines.first).map((e) => e.toLowerCase().trim()).toList();
    int idx(String name) => header.indexOf(name);

    final iName = idx('name');
    final iUrl = idx('url');
    final iUser = idx('username');
    final iPass = idx('password');
    final iNote = idx('note');

    if (iUrl < 0 && iUser < 0 && iPass < 0) {
      throw FormatException(
        'Not a Chrome password CSV (expected name,url,username,password)',
      );
    }

    final out = <VaultItem>[];
    final now = DateTime.now().toUtc();

    for (var li = 1; li < lines.length; li++) {
      if (lines[li].trim().isEmpty) continue;
      final cols = _splitCsvLine(lines[li]);
      String? cell(int i) =>
          (i >= 0 && i < cols.length && cols[i].isNotEmpty) ? cols[i] : null;

      final url = cell(iUrl);
      final user = cell(iUser);
      final pass = cell(iPass);
      if (url == null && user == null && pass == null) continue;

      var title = cell(iName);
      if (title == null || title.isEmpty) {
        title = _hostFromUrl(url) ?? user ?? 'Imported';
      }

      out.add(PasswordItem(
        id: _uuid.v4(),
        title: title,
        username: user,
        password: pass,
        url: url,
        notes: cell(iNote),
        createdAt: now,
        updatedAt: now,
      ));
    }
    return out;
  }

  String? _hostFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      final u = Uri.parse(url.contains('://') ? url : 'https://$url');
      final h = u.host;
      return h.isEmpty ? null : h.replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return url;
    }
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString());
    return result;
  }
}

// Avoid importing dart:convert LineSplitter name clash — use simple split
class LineSplitter {
  const LineSplitter();
  List<String> convert(String source) =>
      source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
}
