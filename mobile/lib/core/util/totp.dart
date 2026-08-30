import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// RFC 6238 TOTP (default: SHA1, 30s, 6 digits).
class Totp {
  Totp({
    required this.secret,
    this.period = 30,
    this.digits = 6,
    this.algorithm = 'SHA1',
  });

  /// Base32 secret (as in authenticator apps).
  final String secret;
  final int period;
  final int digits;
  final String algorithm;

  /// Current code.
  String now([DateTime? time]) {
    final t = time ?? DateTime.now().toUtc();
    final counter = t.millisecondsSinceEpoch ~/ 1000 ~/ period;
    return atCounter(counter);
  }

  /// Seconds remaining in current period.
  int remainingSeconds([DateTime? time]) {
    final t = time ?? DateTime.now().toUtc();
    final sec = t.millisecondsSinceEpoch ~/ 1000;
    return period - (sec % period);
  }

  String atCounter(int counter) {
    final key = _base32Decode(secret.replaceAll(' ', '').toUpperCase());
    final data = ByteData(8)..setInt64(0, counter, Endian.big);
    final hmac = Hmac(sha1, key);
    final hash = hmac.convert(data.buffer.asUint8List()).bytes;

    final offset = hash[hash.length - 1] & 0x0f;
    final binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    final otp = binary % pow(10, digits).toInt();
    return otp.toString().padLeft(digits, '0');
  }

  /// Parse otpauth:// URI (optional helper).
  static Totp? fromOtpAuthUri(String uri) {
    final u = Uri.tryParse(uri);
    if (u == null || u.scheme != 'otpauth') return null;
    final secret = u.queryParameters['secret'];
    if (secret == null) return null;
    final period = int.tryParse(u.queryParameters['period'] ?? '30') ?? 30;
    final digits = int.tryParse(u.queryParameters['digits'] ?? '6') ?? 6;
    final algo = (u.queryParameters['algorithm'] ?? 'SHA1').toUpperCase();
    return Totp(secret: secret, period: period, digits: digits, algorithm: algo);
  }

  static Uint8List _base32Decode(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final cleaned = input.replaceAll(RegExp(r'[^A-Z2-7]'), '');
    var buffer = 0;
    var bitsLeft = 0;
    final out = <int>[];
    for (final c in cleaned.codeUnits) {
      final val = alphabet.indexOf(String.fromCharCode(c));
      if (val < 0) continue;
      buffer = (buffer << 5) | val;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        out.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }
    return Uint8List.fromList(out);
  }

  /// Generate a new random base32 secret (160-bit).
  static String generateSecret({int bytes = 20}) {
    final r = Random.secure();
    final data = List<int>.generate(bytes, (_) => r.nextInt(256));
    return _base32Encode(Uint8List.fromList(data));
  }

  static String _base32Encode(Uint8List data) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    var buffer = 0;
    var bitsLeft = 0;
    final out = StringBuffer();
    for (final b in data) {
      buffer = (buffer << 8) | b;
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        out.write(alphabet[(buffer >> (bitsLeft - 5)) & 31]);
        bitsLeft -= 5;
      }
    }
    if (bitsLeft > 0) {
      out.write(alphabet[(buffer << (5 - bitsLeft)) & 31]);
    }
    return out.toString();
  }
}
