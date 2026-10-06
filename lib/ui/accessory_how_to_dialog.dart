/// Hướng dẫn sưu tầm phụ kiện — mở bằng nút "Hướng dẫn" ở đầu Kho phụ kiện,
/// cùng khuôn match3_how_to_dialog.dart (không tự bật, không thêm cờ lưu).
library;

import 'package:flutter/material.dart';

import '../core/balance.dart';
import '../l10n/app_localizations.dart';

Future<void> showAccessoryHowTo(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AccessoryHowToDialog(),
  );
}

class _AccessoryHowToDialog extends StatelessWidget {
  const _AccessoryHowToDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Thứ tự theo lúc người chơi cần biết: mục tiêu -> cách nhận -> vòng quay
    // -> độ hiếm -> trùng -> Chợ -> mốc/xếp hạng -> trưng bày.
    final lines = [
      l10n.accessoryHtp1,
      l10n.accessoryHtp2,
      l10n.accessoryHtp3,
      l10n.accessoryHtp4,
      l10n.accessoryHtp5(Balance.duplicateAccessoryGems),
      l10n.accessoryHtp6,
      l10n.accessoryHtp7,
      l10n.accessoryHtp8,
    ];
    return AlertDialog(
      title: Text(l10n.accessoryHowToTitle),
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
          key: const Key('accessory-how-to-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
