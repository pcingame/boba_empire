/// Thời tiết & Giao hàng (xem core/weather_delivery.dart): chọn menu hợp thời tiết mỗi 3 giờ + hợp đồng giao hàng cược Xu.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/weather_delivery.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'widgets/app_dialog.dart';
import 'widgets/bobbing.dart';
import 'widgets/clay.dart';
import 'widgets/reward_burst.dart';

Future<void> showDelivery(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _DeliveryDialog());

class _DeliveryDialog extends ConsumerStatefulWidget {
  const _DeliveryDialog();

  @override
  ConsumerState<_DeliveryDialog> createState() => _DeliveryDialogState();
}

class _DeliveryDialogState extends ConsumerState<_DeliveryDialog> {
  Timer? _tick;
  final _weatherKey = GlobalKey();
  final _truckKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Đếm ngược thời tiết + hợp đồng: vẽ lại mỗi giây (dừng khi đóng hộp).
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _weatherName(AppLocalizations l, int w) => [l.weatherName0, l.weatherName1, l.weatherName2, l.weatherName3][w];
  String _menuName(AppLocalizations l, int m) => [l.weatherMenu0, l.weatherMenu1, l.weatherMenu2, l.weatherMenu3][m];

  void _pickMenu(int menu) {
    final l10n = AppLocalizations.of(context)!;
    final ctl = ref.read(gameControllerProvider.notifier);
    final now = ref.read(clockProvider)();
    final right = menu == weatherBestMenu(weatherOf(weatherSlot(now)));
    final cash = ctl.pickWeatherMenu(menu);
    if (cash <= 0) return;
    showRewardBurst(_weatherKey.currentContext ?? context,
        emojis: right ? [weatherMenuEmoji[menu], '✨'] : [weatherMenuEmoji[menu]], label: '+${formatNumber(cash)}');
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(right ? l10n.weatherRight(formatNumber(cash)) : l10n.weatherWrong(formatNumber(cash)))));
  }

  void _finish() {
    final l10n = AppLocalizations.of(context)!;
    final gain = ref.read(gameControllerProvider.notifier).finishDelivery();
    if (gain == null) return;
    if (gain > 0) showRewardBurst(_truckKey.currentContext ?? context, emojis: const ['🪙', '✨'], label: '+${formatNumber(gain)}');
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(gain > 0 ? l10n.deliveryWin(formatNumber(gain)) : l10n.deliveryLose)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final g = ref.watch(gameControllerProvider);
    final ctl = ref.read(gameControllerProvider.notifier);
    final now = ref.read(clockProvider)();
    final slot = weatherSlot(now);
    final weather = weatherOf(slot);
    final picked = g.weatherSlotPicked == slot;
    final income = ctl.petIncome;
    final running = g.contractTier >= 0;
    final ready = running && now >= g.contractEnd;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.deliveryTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClayTile(
              child: Column(children: [
                Row(children: [
                  Container(key: _weatherKey, child: Bobbing(child: Text(weatherEmoji[weather], style: const TextStyle(fontSize: 44)))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_weatherName(l10n, weather), key: const Key('weather-name'), style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(l10n.weatherChanges(formatDuration(weatherSecondsLeft(now))), style: theme.textTheme.bodySmall),
                    ]),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(picked ? l10n.weatherPicked : l10n.weatherHint, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
                  for (var m = 0; m < weatherKinds; m++)
                    Tooltip(
                      message: _menuName(l10n, m),
                      child: OutlinedButton(
                        key: Key('weather-menu-$m'),
                        onPressed: picked ? null : () => _pickMenu(m),
                        child: Text('${weatherMenuEmoji[m]} ${_menuName(l10n, m)}', maxLines: 1),
                      ),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 10),
            ClayTile(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(key: _truckKey, child: const Text('🛵', style: TextStyle(fontSize: 32))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.deliveryHint, style: theme.textTheme.bodySmall)),
                ]),
                const SizedBox(height: 8),
                if (!running)
                  for (var t = 0; t < deliveryTiers.length; t++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          key: Key('delivery-tier-$t'),
                          onPressed: g.money >= deliveryStake(t, income) ? () => ctl.startDelivery(t) : null,
                          child: Text(
                            '${l10n.deliveryTierHours(deliveryTiers[t].hours)} · ${(deliveryTiers[t].winChance * 100).round()}% · ×${deliveryTiers[t].payout}\n${l10n.deliveryStart(formatNumber(deliveryStake(t, income)))}',
                            textAlign: TextAlign.center,
                            maxLines: 3,
                          ),
                        ),
                      ),
                    )
                else if (ready)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(key: const Key('delivery-finish'), onPressed: _finish, child: Text(l10n.deliveryReady, maxLines: 2, textAlign: TextAlign.center)),
                  )
                else
                  Center(
                    child: Text(l10n.deliveryRunning(formatDuration(((g.contractEnd - now) / 1000).ceil())),
                        key: const Key('delivery-running'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
              ]),
            ),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}
