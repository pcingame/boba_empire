import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Bảng "Cách chơi": tra cứu ngắn gọn các cơ chế, mở từ Cài đặt. Người mới được
/// hướng dẫn bằng lớp phủ tương tác (xem tutorial_overlay.dart), không phải hộp này.
Future<void> showHowToPlay(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _HowToPlayDialog(),
  );
}

class _HowToPlayDialog extends StatelessWidget {
  const _HowToPlayDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = [
      (Icons.touch_app, l10n.htpTap),
      (Icons.trending_up, l10n.htpBuy),
      (Icons.storefront, l10n.htpStage),
      (Icons.pets, l10n.htpCat),
      (Icons.person, l10n.htpVip),
      (Icons.diamond, l10n.htpGems),
      (Icons.workspace_premium, l10n.htpPrestige),
      (Icons.bedtime, l10n.htpOffline),
      (Icons.pin, l10n.htpNumberFormat),
    ];
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.howToPlayTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (icon, text) in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.secondaryContainer,
                      child: Icon(icon,
                          size: 18, color: scheme.onSecondaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(text)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          key: const Key('how-to-play-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
