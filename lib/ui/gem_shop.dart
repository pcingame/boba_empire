import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balance.dart';
import '../core/economy.dart';
import '../core/format.dart';
import '../iap/iap_products.dart';
import '../iap/iap_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';

/// Mở Cửa hàng Kim Cương — chỗ tiêu gems kiếm từ VIP, và nạp bằng tiền thật.
Future<void> showGemShop(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _GemShop(),
  );
}

class _GemShop extends ConsumerStatefulWidget {
  const _GemShop();

  @override
  ConsumerState<_GemShop> createState() => _GemShopState();
}

class _GemShopState extends ConsumerState<_GemShop> {
  // Tải giá một lần khi mở dialog (stub trả rỗng → mục IAP tự ẩn nút mua).
  late final Future<Map<IapProduct, String>> _prices =
      ref.read(iapServiceProvider).loadPrices();

  // Từ lúc bấm "mua" tới lúc màn thanh toán của store hiện ra có 1 khoảng
  // chờ (gọi API store, có thể vài trăm ms tới vài giây) mà trước đây UI im
  // lặng hoàn toàn — trông như treo máy. Theo dõi sản phẩm đang xử lý để
  // hiện vòng xoay, tắt khi CÓ 1 TRONG 2 stream báo về (thành công/thất bại
  // — xem IapService.purchaseFailed) hoặc hết thời gian chờ an toàn (phòng
  // trường hợp không có tín hiệu nào quay lại).
  IapProduct? _pendingPurchase;
  bool _restoring = false;
  StreamSubscription<IapProduct>? _purchaseSub;
  StreamSubscription<IapProduct>? _purchaseFailedSub;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    final iap = ref.read(iapServiceProvider);
    _purchaseSub = iap.purchases.listen(_clearPending);
    _purchaseFailedSub = iap.purchaseFailed.listen(_clearPending);
  }

  void _clearPending(IapProduct p) {
    _safetyTimer?.cancel();
    if (mounted && _pendingPurchase == p) {
      setState(() => _pendingPurchase = null);
    }
  }

  void _startBuy(IapProduct p) {
    setState(() => _pendingPurchase = p);
    ref.read(iapServiceProvider).buy(p);
    // Lưới an toàn: không để nút kẹt loading mãi nếu vì lý do gì đó không
    // có tín hiệu thành công/thất bại nào quay lại. Dùng Timer (huỷ được ở
    // dispose) thay vì Future.delayed trần — nếu không huỷ, test framework
    // báo "Timer is still pending" khi dialog đóng trước khi hết giờ.
    _safetyTimer?.cancel();
    _safetyTimer =
        Timer(const Duration(seconds: 10), () => _clearPending(p));
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _purchaseFailedSub?.cancel();
    _safetyTimer?.cancel();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    final boostLevel =
        ref.watch(gameControllerProvider.select((s) => s.gemBoostLevel));
    final capLevel =
        ref.watch(gameControllerProvider.select((s) => s.offlineCapLevel));
    final stage = ref.watch(gameControllerProvider.select((s) => s.stage));
    final timeSkipRemaining = ref
        .watch(gameControllerProvider.select((s) => s.gemTimeSkipRemainingToday));
    final controller = ref.read(gameControllerProvider.notifier);
    final nextStage = Balance.nextStageConfig(stage);

    final adsRemoved =
        ref.watch(gameControllerProvider.select((s) => s.adsRemoved));
    final starterOwned =
        ref.watch(gameControllerProvider.select((s) => s.starterPackOwned));
    final doubleOwned =
        ref.watch(gameControllerProvider.select((s) => s.doubleIncomeOwned));

    final l10n = AppLocalizations.of(context)!;
    final boostPercent = (Balance.gemBoostPerLevel * 100).round();
    final capHours = Balance.offlineCapPerLevelSeconds ~/ 3600;

    return AlertDialog(
      title: Text(l10n.gemShopTitle(formatNumber(gems))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GemItem(
              name: l10n.gemBoostName,
              level: boostLevel,
              description: l10n.gemBoostDesc(boostPercent),
              cost: gemBoostCost(boostLevel),
              gems: gems,
              onBuy: controller.buyGemBoostUpgrade,
            ),
            _GemItem(
              name: l10n.offlineCapName,
              level: capLevel,
              description: l10n.offlineCapDesc(capHours),
              cost: offlineCapCost(capLevel),
              gems: gems,
              onBuy: controller.buyOfflineCapUpgrade,
            ),
            if (nextStage != null)
              _GemAction(
                name: l10n.gemInstantStageName,
                description: l10n.gemInstantStageDesc(
                    stageName(l10n, nextStage.stage)),
                cost: instantStageGemCost(stage),
                gems: gems,
                buttonKey: const Key('gem-instant-stage'),
                onBuy: () {
                  if (controller.buyInstantStage()) {
                    _snack(l10n.gemStageUnlockedSnack(
                        stageName(l10n, nextStage.stage)));
                  }
                },
              ),
            _GemAction(
              name: l10n.gemTimeSkipName,
              description:
                  '${l10n.gemTimeSkipDesc(Balance.gemTimeSkipSeconds ~/ 3600)}\n'
                  '${l10n.gemTimeSkipRemaining(timeSkipRemaining, Balance.maxGemTimeSkipPerDay)}',
              cost: Balance.gemTimeSkipCost,
              gems: gems,
              enabled: timeSkipRemaining > 0,
              buttonKey: const Key('gem-time-skip'),
              onBuy: () {
                final r = controller.buyGemTimeSkipReward();
                if (r > 0) _snack(l10n.instantCashSnack(formatNumber(r)));
              },
            ),
            FutureBuilder<Map<IapProduct, String>>(
              future: _prices,
              builder: (context, snap) => _iapSectionBuilder(
                snap.data ?? const {},
                adsRemoved: adsRemoved,
                starterOwned: starterOwned,
                doubleOwned: doubleOwned,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  /// Phần "nạp bằng tiền thật" — chỉ hiện khi store trả về giá (mobile thật).
  Widget _iapSectionBuilder(
    Map<IapProduct, String> prices, {
    required bool adsRemoved,
    required bool starterOwned,
    required bool doubleOwned,
  }) {
    final iap = ref.read(iapServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    final products = [
      for (final p in IapProduct.values)
        // Heo đất có UI riêng ở dialog "Kiếm thêm" → không liệt kê ở đây.
        if (p != IapProduct.piggyBreak &&
            !(p == IapProduct.removeAds && adsRemoved) &&
            !(p == IapProduct.starterPack && starterOwned) &&
            !(p == IapProduct.doubleIncome && doubleOwned))
          p,
    ];
    if (prices.isEmpty || products.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.iapSectionTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final p in products)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(iapTitle(l10n, p)),
            subtitle: Text(iapDescription(l10n, p)),
            trailing: FilledButton.tonal(
              key: Key('iap-buy-${p.id}'),
              // Chặn bấm tiếp trong lúc CÓ BẤT KỲ lượt mua nào đang xử lý
              // (màn thanh toán của store vốn đã modal, tránh bấm chồng gây
              // rối luồng plugin) hoặc đang khôi phục.
              onPressed: _pendingPurchase == null && !_restoring
                  ? () => _startBuy(p)
                  : null,
              child: _pendingPurchase == p
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(prices[p] ?? '—'),
            ),
          ),
        TextButton(
          onPressed: _pendingPurchase == null && !_restoring
              ? () async {
                  setState(() => _restoring = true);
                  try {
                    await iap.restore();
                  } finally {
                    if (mounted) setState(() => _restoring = false);
                  }
                }
              : null,
          child: _restoring
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.restorePurchases),
        ),
      ],
    );
  }
}

/// Mục "hành động" trong Cửa hàng 💎 (mua giai đoạn / tua nhanh): không có cấp,
/// bấm là dùng ngay. Nút mờ khi không đủ 💎.
class _GemAction extends StatelessWidget {
  const _GemAction({
    required this.name,
    required this.description,
    required this.cost,
    required this.gems,
    required this.onBuy,
    required this.buttonKey,
    this.enabled = true,
  });

  final String name;
  final String description;
  final int cost;
  final double gems;
  final VoidCallback onBuy;
  final Key buttonKey;

  /// false khi mục này còn 1 điều kiện khác (ngoài đủ 💎) chưa thoả — VD hết
  /// lượt "Tua nhanh" hôm nay (xem Balance.maxGemTimeSkipPerDay).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ClayTile(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Chiều rộng cố định: bốn nút giá trong Cửa hàng Kim Cương thuộc 2
          // widget khác nhau (_GemAction/_GemItem), mỗi nút vốn tự co theo độ
          // dài số của riêng nó (5/10/40/30 chữ số khác nhau) nên không thẳng
          // cột — bug thật gặp trên máy. Ép cùng 1 chiều rộng + FittedBox co
          // chữ nếu số dài hơn (giá có thể tăng theo cấp) để luôn thẳng hàng.
          SizedBox(
            width: _priceButtonWidth,
            child: FilledButton(
              key: buttonKey,
              onPressed: (gems >= cost && enabled) ? onBuy : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l10n.gemCost(cost)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chiều rộng chung cho mọi nút giá trong Cửa hàng Kim Cương (_GemAction +
/// _GemItem) — để 4 nút thẳng cột dù số chữ số khác nhau.
const double _priceButtonWidth = 72;

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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ClayTile(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.gemItemLevel(name, level),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Chiều rộng cố định (xem _priceButtonWidth) + FittedBox: giá tăng
          // theo cấp số nhân KHÔNG có trần cấp (khác các nguồn thu chính đã
          // có Balance.maxGeneratorLevel) — cấp đủ cao thì `cost` (int thô,
          // không qua formatNumber) có thể dài hàng chục chữ số. FittedBox co
          // chữ vừa khung cố định thay vì tràn (cùng lớp bug đã gặp ở
          // _ShopTile, xem shop-tile-overflow-pattern memory) — an toàn hơn
          // Flexible cũ vì khung không bao giờ cần rộng hơn 72, luôn đủ chỗ
          // cho nút "Mở giai đoạn tức thì"/"Tua nhanh" bên trên thẳng cột.
          SizedBox(
            width: _priceButtonWidth,
            child: FilledButton(
              key: Key('gem-buy-$name'),
              onPressed: canAfford ? onBuy : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l10n.gemCost(cost)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
