import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/rival.dart';
import '../core/story_content.dart';
import '../l10n/app_localizations.dart';

/// Dialog một sự kiện đối thủ. Trả về chỉ số lựa chọn (0/1), hoặc `null` khi
/// phớt lờ / thoát. KHÔNG đóng được bằng chạm nền — chỉ nút "Phớt lờ" trả `null`.
Future<int?> showRivalEvent(
  BuildContext context, {
  required RivalEventType type,
  required List<RivalOutcome> options,
  required List<bool> affordable,
}) {
  return showDialog<int?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RivalEventDialog(
      type: type,
      options: options,
      affordable: affordable,
    ),
  );
}

class _RivalEventDialog extends StatelessWidget {
  const _RivalEventDialog({
    required this.type,
    required this.options,
    required this.affordable,
  });

  final RivalEventType type;
  final List<RivalOutcome> options;
  final List<bool> affordable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final code = Localizations.localeOf(context).languageCode;
    final text = rivalEventText(type, code);

    String costLabel(RivalOutcome o) {
      if (o.spendGems > 0) return '${o.spendGems} 💎';
      if (o.spendMoney > 0) return '${formatNumber(o.spendMoney)} 🪙';
      return '';
    }

    return AlertDialog(
      title: Row(
        children: [
          const ExcludeSemantics(
            child: Text('😼', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.rivalEventTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(text.body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 14),
            _OptionButton(
              buttonKey: const Key('rival-option-0'),
              label: text.optionA,
              cost: costLabel(options[0]),
              enabled: affordable[0],
              onTap: () => Navigator.of(context).pop(0),
            ),
            const SizedBox(height: 8),
            _OptionButton(
              buttonKey: const Key('rival-option-1'),
              label: text.optionB,
              cost: costLabel(options[1]),
              enabled: affordable[1],
              onTap: () => Navigator.of(context).pop(1),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('rival-ignore'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.rivalEventIgnore),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.buttonKey,
    required this.label,
    required this.cost,
    required this.enabled,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final String cost;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: buttonKey,
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(cost, style: theme.textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
