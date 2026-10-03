/// Dải thông báo sự kiện cuối tuần (phí Chợ 0% + tăng tỉ lệ rớt phụ kiện hiếm).
/// Không chiếm chỗ ngoài cuối tuần. Giờ lấy từ clockProvider để test ghi đè được.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/market_fee.dart';
import '../../l10n/app_localizations.dart';
import '../../state/game_providers.dart';

class WeekendBanner extends ConsumerWidget {
  const WeekendBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.fromMillisecondsSinceEpoch(
        ref.read(clockProvider)(),
        isUtc: true);
    if (!weekendEventActive(now)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      key: const Key('weekend-banner'),
      width: double.infinity,
      color: theme.colorScheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        AppLocalizations.of(context)!.marketWeekendBanner,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge,
      ),
    );
  }
}
