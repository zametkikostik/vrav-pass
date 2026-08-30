import 'package:flutter_test/flutter_test.dart';
import 'package:vrav_pass/core/import/chrome_import.dart';
import 'package:vrav_pass/core/vault/vault_models.dart';

void main() {
  test('parses Chrome password CSV', () {
    const csv = '''name,url,username,password,note
Example,https://example.com,user,secret,hi
''';
    final items = ChromeImport().parse(csv);
    expect(items.length, 1);
    final p = items.first as PasswordItem;
    expect(p.title, 'Example');
    expect(p.url, 'https://example.com');
    expect(p.username, 'user');
    expect(p.password, 'secret');
    expect(p.notes, 'hi');
  });
}
