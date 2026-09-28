/// Bảng hướng dẫn riêng cho Trân Châu Rơi. Tự hiện LẦN ĐẦU mở tab (xem
/// `m3HowToSeen`) và mở lại bất cứ lúc nào bằng nút ? trên AppBar — cùng khuôn
/// với bảng "Cách chơi" của màn chính (how_to_play_dialog.dart).
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

Future<void> showMatch3HowTo(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _Match3HowToDialog(),
  );
}

class _Match3HowToDialog extends StatelessWidget {
  const _Match3HowToDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Thứ tự theo lúc người chơi cần biết: đổi ô -> mục tiêu -> giới hạn nước
    // -> dây chuyền -> kẹo đặc biệt -> sao -> thưởng.
    final lines = [
      l10n.m3HtpSwap,
      l10n.m3HtpGoal,
      l10n.m3HtpMoves,
      l10n.m3HtpChain,
      l10n.m3HtpSpecial,
      l10n.m3HtpStars,
      l10n.m3HtpReward,
    ];

    return AlertDialog(
      title: Text(l10n.m3HowToTitle),
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
          key: const Key('m3-how-to-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
