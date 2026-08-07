import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Bảng "Cách chơi": liệt kê ngắn gọn các cơ chế. Tự hiện lần đầu (xem
/// tutorialSeen ở HomePage) và mở lại bằng nút ? trên AppBar.
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
      l10n.htpTap,
      l10n.htpBuy,
      l10n.htpStage,
      l10n.htpCat,
      l10n.htpVip,
      l10n.htpGems,
      l10n.htpPrestige,
      l10n.htpOffline,
    ];

    return AlertDialog(
      title: Text(l10n.howToPlayTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(line),
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
