/// Hướng dẫn VIP — mở bằng nút "?" ở đầu màn Mốc nạp & VIP, cùng khuôn
/// accessory_how_to_dialog.dart (không tự bật, không thêm cờ lưu). Con số lấy từ
/// core/topup.dart để lời hướng dẫn không lệch khi chỉnh cân bằng.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/topup.dart';
import '../l10n/app_localizations.dart';
import 'web_links.dart';
import 'widgets/app_dialog.dart';

Future<void> showVipHowTo(BuildContext context) => showAppDialog<void>(
      context: context,
      builder: (_) => const _VipHowToDialog(),
    );

class _VipHowToDialog extends ConsumerWidget {
  const _VipHowToDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lines = [
      l10n.vipHtp1,
      // gen-l10n sắp tham số theo THỨ TỰ CHỮ CÁI (cap, exp, gems), không theo thứ tự trong câu.
      l10n.vipHtp2(
        formatNumber(vipExpGemCap.toDouble()),
        vipExpBlock,
        formatNumber(vipExpBlockGems.toDouble()),
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
        TextButton(
          key: const Key('how-to-web-guide'),
          onPressed: () => openWebLink(context, ref, webGuideUrl('vip')),
          child: Text(l10n.guideOnWeb),
        ),
        FilledButton(
          key: const Key('vip-how-to-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
