import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balance.dart';
import '../core/economy.dart';
import '../core/format.dart';
import '../state/game_providers.dart';

/// Mở Cửa hàng Kim Cương — chỗ tiêu gems kiếm được từ khách VIP.
Future<void> showGemShop(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _GemShop(),
  );
}

class _GemShop extends ConsumerWidget {
  const _GemShop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    final boostLevel =
        ref.watch(gameControllerProvider.select((s) => s.gemBoostLevel));
    final capLevel =
        ref.watch(gameControllerProvider.select((s) => s.offlineCapLevel));
    final controller = ref.read(gameControllerProvider.notifier);

    final boostPercent = (Balance.gemBoostPerLevel * 100).round();
    final capHours = Balance.offlineCapPerLevelSeconds ~/ 3600;

    return AlertDialog(
      title: Text('Cửa Hàng 💎 (có ${formatNumber(gems)})'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GemItem(
            name: 'Tăng thu nhập',
            level: boostLevel,
            description: '+$boostPercent% thu nhập vĩnh viễn mỗi cấp',
            cost: gemBoostCost(boostLevel),
            gems: gems,
            onBuy: controller.buyGemBoostUpgrade,
          ),
          const Divider(),
          _GemItem(
            name: 'Kho lạnh offline',
            level: capLevel,
            description: '+$capHours giờ trần tiền offline mỗi cấp',
            cost: offlineCapCost(capLevel),
            gems: gems,
            onBuy: controller.buyOfflineCapUpgrade,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _GemItem extends StatelessWidget {
  const _GemItem({
    required this.name,
    required this.level,
    required this.description,
    required this.cost,
    required this.gems,
    required this.onBuy,
  });

  final String name;
  final int level;
  final String description;
  final int cost;
  final double gems;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final canAfford = gems >= cost;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$name  Lv.$level'),
      subtitle: Text(description),
      trailing: FilledButton(
        key: Key('gem-buy-$name'),
        onPressed: canAfford ? onBuy : null,
        child: Text('$cost 💎'),
      ),
    );
  }
}
