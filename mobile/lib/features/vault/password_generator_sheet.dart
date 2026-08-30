import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/util/password_generator.dart';

/// Shows a generator sheet and returns the chosen password, or null if cancelled.
Future<String?> showPasswordGeneratorSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _GeneratorBody(),
  );
}

class _GeneratorBody extends StatefulWidget {
  const _GeneratorBody();

  @override
  State<_GeneratorBody> createState() => _GeneratorBodyState();
}

class _GeneratorBodyState extends State<_GeneratorBody> {
  final _gen = PasswordGenerator();
  var _opts = const PasswordGeneratorOptions();
  late String _password;

  @override
  void initState() {
    super.initState();
    _password = _gen.generate(_opts);
  }

  void _regen() {
    setState(() => _password = _gen.generate(_opts));
  }

  @override
  Widget build(BuildContext context) {
    final entropy = _gen.estimateEntropy(_password);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('generate_password'.tr(),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SelectableText(
            _password,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'monospace',
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${'entropy'.tr()}: ${entropy.toStringAsFixed(0)} bit',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('length'.tr()),
              Expanded(
                child: Slider(
                  value: _opts.length.toDouble(),
                  min: 8,
                  max: 64,
                  divisions: 56,
                  label: '${_opts.length}',
                  onChanged: (v) {
                    setState(() {
                      _opts = _opts.copyWith(length: v.round());
                      _password = _gen.generate(_opts);
                    });
                  },
                ),
              ),
              Text('${_opts.length}'),
            ],
          ),
          SwitchListTile(
            title: Text('lowercase'.tr()),
            value: _opts.lowercase,
            onChanged: (v) {
              setState(() {
                _opts = _opts.copyWith(lowercase: v);
                _regen();
              });
            },
          ),
          SwitchListTile(
            title: Text('uppercase'.tr()),
            value: _opts.uppercase,
            onChanged: (v) {
              setState(() {
                _opts = _opts.copyWith(uppercase: v);
                _regen();
              });
            },
          ),
          SwitchListTile(
            title: Text('digits'.tr()),
            value: _opts.digits,
            onChanged: (v) {
              setState(() {
                _opts = _opts.copyWith(digits: v);
                _regen();
              });
            },
          ),
          SwitchListTile(
            title: Text('symbols'.tr()),
            value: _opts.symbols,
            onChanged: (v) {
              setState(() {
                _opts = _opts.copyWith(symbols: v);
                _regen();
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _regen,
                  icon: const Icon(Icons.refresh),
                  label: Text('regenerate'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _password));
                    Navigator.of(context).pop(_password);
                  },
                  child: Text('use_password'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
