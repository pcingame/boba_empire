/// "Nhập mã quà tặng" — mã bù đắp thủ công (VD sự cố crash). Mở từ Cài đặt
/// (`settings_dialog.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/redeem.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';

Future<void> showRedeemDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _RedeemDialog(),
  );
}

class _RedeemDialog extends ConsumerStatefulWidget {
  const _RedeemDialog();

  @override
  ConsumerState<_RedeemDialog> createState() => _RedeemDialogState();
}

class _RedeemDialogState extends ConsumerState<_RedeemDialog> {
  final _ctrl = TextEditingController();
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(AppLocalizations l10n) {
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;
    final result = ref.read(gameControllerProvider.notifier).redeemCode(code);
    setState(() {
      _isError = result.status != RedeemStatus.success;
      _message = switch (result.status) {
        RedeemStatus.success => l10n.redeemSuccess(result.gems.toInt()),
        RedeemStatus.alreadyClaimed => l10n.redeemAlreadyClaimed,
        RedeemStatus.invalid => l10n.redeemInvalid,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.redeemTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('redeem-code-field'),
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.redeemHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(l10n),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('redeem-submit'),
            onPressed: () => _submit(l10n),
            child: Text(l10n.redeemButton),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              key: const Key('redeem-message'),
              style: TextStyle(
                color: _isError ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
