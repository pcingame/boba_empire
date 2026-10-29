import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/recap.dart';
import '../l10n/app_localizations.dart';
import 'widgets/app_dialog.dart';

/// Popup "Tổng kết tuần qua" (xem core/recap.dart): các con số tuần vừa rồi; mục bằng 0 thì ẩn (trừ Xu kiếm được).
Future<void> showRecapDialog(BuildContext context, Map<String, double> data) => showAppDialog<void>(
      context: context,
      celebrate: true,
      builder: (_) => _RecapDialog(data: data),
    );

class _RecapDialog extends StatelessWidget {
  const _RecapDialog({required this.data});
  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <(String, String, String)>[
      for (final k in recapKeys)
        if (k == 'earned' || (data[k] ?? 0) > 0)
          switch (k) {
            'earned' => ('💰', l10n.recapEarned, formatNumber(data[k] ?? 0)),
            'taps' => ('👆', l10n.recapTaps, formatNumber(data[k]!)),
            'buys' => ('🛒', l10n.recapBuys, formatNumber(data[k]!)),
            'items' => ('🎀', l10n.recapItems, formatNumber(data[k]!)),
            _ => ('🏅', l10n.recapAchievements, formatNumber(data[k]!)),
          },
    ];
    return AlertDialog(
      title: Text(l10n.recapTitle),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (emoji, label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(child: Text(label)),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ),
        ]),
      ),
      actions: [
        FilledButton(
          key: const Key('recap-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.recapClose),
        ),
      ],
    );
  }
}
