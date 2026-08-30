import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../vault/vault_models.dart';

/// Import from Bitwarden **unencrypted** export.
///
/// Supports:
/// - JSON export ("Export vault" → .json)
/// - CSV export (login rows)
///
/// Encrypted Bitwarden exports are NOT supported (need account key).
class BitwardenImport {
  BitwardenImport({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  List<VaultItem> parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return _fromJson(trimmed);
    }
    return _fromCsv(trimmed);
  }

  List<VaultItem> _fromJson(String raw) {
    final decoded = jsonDecode(raw);
    final List itemsJson;

    if (decoded is Map<String, dynamic>) {
      // Full vault export: { "items": [ ... ], "folders": ... }
      final items = decoded['items'];
      if (items is! List) {
        throw FormatException('Bitwarden JSON: missing items[]');
      }
      itemsJson = items;
    } else if (decoded is List) {
      itemsJson = decoded;
    } else {
      throw FormatException('Unsupported Bitwarden JSON shape');
    }

    final out = <VaultItem>[];
    final now = DateTime.now().toUtc();

    for (final rawItem in itemsJson) {
      if (rawItem is! Map) continue;
      final m = Map<String, dynamic>.from(rawItem);
      final type = m['type']; // 1 login, 2 secure note, 3 card, 4 identity
      final name = (m['name'] as String?)?.trim() ?? 'Imported';
      final notes = m['notes'] as String?;
      final favorite = m['favorite'] == true;
      final id = _uuid.v4();

      if (type == 1 || m['login'] != null) {
        final login = m['login'] is Map
            ? Map<String, dynamic>.from(m['login'] as Map)
            : <String, dynamic>{};
        final uris = login['uris'];
        String? url;
        if (uris is List && uris.isNotEmpty && uris.first is Map) {
          url = (uris.first as Map)['uri'] as String?;
        }
        out.add(PasswordItem(
          id: id,
          title: name,
          createdAt: now,
          updatedAt: now,
          favorite: favorite,
          username: login['username'] as String?,
          password: login['password'] as String?,
          url: url,
          notes: notes,
          totpSecret: _normalizeTotp(login['totp'] as String?),
        ));
      } else if (type == 2 || (type == null && notes != null && m['login'] == null)) {
        out.add(NoteItem(
          id: id,
          title: name,
          createdAt: now,
          updatedAt: now,
          favorite: favorite,
          content: notes ?? '',
        ));
      }
      // cards / identity skipped in v1
    }
    return out;
  }

  List<VaultItem> _fromCsv(String raw) {
    final lines = const LineSplitter().convert(raw);
    if (lines.isEmpty) return [];

    final header = _splitCsvLine(lines.first).map((e) => e.toLowerCase()).toList();
    int idx(String name) => header.indexOf(name);

    final iName = idx('name');
    final iUser = idx('login_username');
    final iPass = idx('login_password');
    final iUri = idx('login_uri');
    final iNotes = idx('notes');
    final iTotp = idx('login_totp');
    final iType = idx('type');
    final iFav = idx('favorite');

    // Minimal fallback headers
    final hasLogin = iUser >= 0 || iPass >= 0;

    final out = <VaultItem>[];
    final now = DateTime.now().toUtc();

    for (var li = 1; li < lines.length; li++) {
      if (lines[li].trim().isEmpty) continue;
      final cols = _splitCsvLine(lines[li]);
      String? cell(int i) =>
          (i >= 0 && i < cols.length && cols[i].isNotEmpty) ? cols[i] : null;

      final type = cell(iType)?.toLowerCase() ?? (hasLogin ? 'login' : 'note');
      final title = cell(iName) ?? 'Imported';
      final favorite = cell(iFav) == '1' || cell(iFav)?.toLowerCase() == 'true';
      final id = _uuid.v4();

      if (type == 'login' || type == '1' || (hasLogin && type != 'note')) {
        out.add(PasswordItem(
          id: id,
          title: title,
          createdAt: now,
          updatedAt: now,
          favorite: favorite,
          username: cell(iUser),
          password: cell(iPass),
          url: cell(iUri),
          notes: cell(iNotes),
          totpSecret: _normalizeTotp(cell(iTotp)),
        ));
      } else if (type.contains('note') || type == '2') {
        out.add(NoteItem(
          id: id,
          title: title,
          createdAt: now,
          updatedAt: now,
          favorite: favorite,
          content: cell(iNotes) ?? '',
        ));
      }
    }
    return out;
  }

  /// Bitwarden may store otpauth://... or raw base32.
  String? _normalizeTotp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('otpauth://')) {
      final uri = Uri.tryParse(raw);
      final secret = uri?.queryParameters['secret'];
      return secret ?? raw;
    }
    return raw.replaceAll(' ', '').toUpperCase();
  }

  /// Simple CSV splitter (handles quoted fields).
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
