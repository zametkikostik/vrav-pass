import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/util/totp.dart';

class TotpCodeWidget extends StatefulWidget {
  const TotpCodeWidget({super.key, required this.secret});

  final String secret;

  @override
  State<TotpCodeWidget> createState() => _TotpCodeWidgetState();
}

class _TotpCodeWidgetState extends State<TotpCodeWidget> {
  late Totp _totp;
  late String _code;
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _totp = Totp(secret: widget.secret);
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _code = _totp.now();
      _remaining = _totp.remainingSeconds();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('totp_code'.tr(),
                    style: Theme.of(context).textTheme.labelSmall),
                Text(
                  _code,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                      ),
                ),
                LinearProgressIndicator(
                  value: _remaining / 30,
                  minHeight: 3,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('copied'.tr())),
              );
            },
          ),
        ],
      ),
    );
  }
}
