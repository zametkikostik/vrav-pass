import 'package:flutter_test/flutter_test.dart';
import 'package:vrav_pass/core/import/bitwarden_import.dart';
import 'package:vrav_pass/core/vault/vault_models.dart';

void main() {
  test('parses Bitwarden JSON login item', () {
    const json = '''
{
  "items": [
    {
      "type": 1,
      "name": "Example",
      "notes": "n",
      "favorite": true,
      "login": {
        "username": "user",
        "password": "secret",
        "totp": "otpauth://totp/Example?secret=JBSWY3DPEHPK3PXP",
        "uris": [ { "uri": "https://example.com" } ]
      }
    },
    {
      "type": 2,
      "name": "Note1",
      "notes": "hello"
    }
  ]
}
''';
    final items = BitwardenImport().parse(json);
    expect(items.length, 2);
    final p = items.first as PasswordItem;
    expect(p.title, 'Example');
    expect(p.username, 'user');
    expect(p.password, 'secret');
    expect(p.url, 'https://example.com');
    expect(p.totpSecret, 'JBSWY3DPEHPK3PXP');
    expect(p.favorite, isTrue);
    final n = items[1] as NoteItem;
    expect(n.content, 'hello');
  });
}
