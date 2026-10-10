/// Hướng dẫn VIP — mở bằng nút "?" ở đầu màn Mốc nạp & VIP, cùng khuôn
/// accessory_how_to_dialog.dart (không tự bật, không thêm cờ lưu). Con số lấy từ
/// core/topup.dart để lời hướng dẫn không lệch khi chỉnh cân bằng.
library;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/topup.dart';
import '../l10n/app_localizations.dart';

Future<void> showVipHowTo(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _VipHowToDialog(),
    );

class _VipHowToDialog extends StatelessWidget {
  const _VipHowToDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = [
      l10n.vipHtp1,
      l10n.vipHtp2(
        formatNumber(vipExpBlockGems.toDouble()),
        vipExpBlock,
        formatNumber(vipExpGemCap.toDouble()),
      ),
      l10n.vipHtp3((vipIncomeBonusPerLevel * 100).round()),
      l10n.vipHtp4,
      l10n.vipHtp5,
      l10n.vipHtp6,
    ];
    return AlertDialog(
      title: Text(l10n.vipHowToTitle),
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
          key: const Key('vip-how-to-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
