import 'dart:math';

class PasswordGeneratorOptions {
  const PasswordGeneratorOptions({
    this.length = 20,
    this.lowercase = true,
    this.uppercase = true,
    this.digits = true,
    this.symbols = true,
    this.excludeAmbiguous = true,
  });

  final int length;
  final bool lowercase;
  final bool uppercase;
  final bool digits;
  final bool symbols;
  final bool excludeAmbiguous;

  PasswordGeneratorOptions copyWith({
    int? length,
    bool? lowercase,
    bool? uppercase,
    bool? digits,
    bool? symbols,
    bool? excludeAmbiguous,
  }) {
    return PasswordGeneratorOptions(
      length: length ?? this.length,
      lowercase: lowercase ?? this.lowercase,
      uppercase: uppercase ?? this.uppercase,
      digits: digits ?? this.digits,
      symbols: symbols ?? this.symbols,
      excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
    );
  }
}

class PasswordGenerator {
  PasswordGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const _lower = 'abcdefghijkmnopqrstuvwxyz'; // no l if ambiguous
  static const _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I O
  static const _digits = '23456789'; // no 0 1
  static const _symbols = '!@#\$%^&*-_=+?';

  static const _lowerAll = 'abcdefghijklmnopqrstuvwxyz';
  static const _upperAll = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digitsAll = '0123456789';

  String generate([PasswordGeneratorOptions opts = const PasswordGeneratorOptions()]) {
    final pools = <String>[];
    if (opts.lowercase) {
      pools.add(opts.excludeAmbiguous ? _lower : _lowerAll);
    }
    if (opts.uppercase) {
      pools.add(opts.excludeAmbiguous ? _upper : _upperAll);
    }
    if (opts.digits) {
      pools.add(opts.excludeAmbiguous ? _digits : _digitsAll);
    }
    if (opts.symbols) {
      pools.add(_symbols);
    }
    if (pools.isEmpty) {
      pools.add(_lowerAll);
    }

    final all = pools.join();
    // Ensure at least one char from each selected pool
    final chars = <String>[];
    for (final pool in pools) {
      chars.add(pool[_random.nextInt(pool.length)]);
    }
    while (chars.length < opts.length) {
      chars.add(all[_random.nextInt(all.length)]);
    }
    chars.shuffle(_random);
    return chars.take(opts.length).join();
  }

  /// Rough entropy estimate in bits.
  double estimateEntropy(String password) {
    if (password.isEmpty) return 0;
    var pool = 0;
    if (password.contains(RegExp(r'[a-z]'))) pool += 26;
    if (password.contains(RegExp(r'[A-Z]'))) pool += 26;
    if (password.contains(RegExp(r'[0-9]'))) pool += 10;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) pool += 20;
    if (pool == 0) pool = 26;
    return password.length * (log(pool) / ln2);
  }
}
