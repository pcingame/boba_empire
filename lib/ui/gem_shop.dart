import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balance.dart';
import '../leaderboard/flair.dart';
import '../core/topup.dart';
import '../core/daily_deal.dart';
import '../core/daily.dart' show dayIndex;
import '../core/economy.dart';
import '../core/format.dart';
import '../iap/iap_products.dart';
import '../iap/iap_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'email_gate.dart';
import 'topup_dialog.dart';
import '../analytics/analytics.dart';
import 'widgets/clay.dart';

/// Mở Cửa hàng Kim Cương — chỗ tiêu gems kiếm từ VIP, và nạp bằng tiền thật.
Future<void> showGemShop(BuildContext context) {
  trackEvent(context, 'open_gem_shop');
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

  /// Gói 💎 mà người chơi chưa mua lần nào → còn thưởng "mua lần đầu gấp đôi".
  bool _firstBonus(IapProduct p) =>
      p.isGems &&
      !ref.read(gameControllerProvider).firstBuyClaimed.contains(p.id);

  /// Nạp tiền thật cần đã liên kết email (xem email_gate.dart).
  Future<void> _onBuyTap(IapProduct p) async {
    if (!await ensureEmailLinked(context, ref)) return;
    if (!mounted) return;
    _startBuy(p);
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
    final coldOwned =
        ref.watch(gameControllerProvider.select((s) => s.coldStorageOwned));

    final l10n = AppLocalizations.of(context)!;
    final boostPercent = (Balance.gemBoostPerLevel * 100).round();
    final capHours = Balance.offlineCapPerLevelSeconds ~/ 3600;

    return AlertDialog(
      title: Text(l10n.gemShopTitle(formatNumber(gems))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _VipEntryCard(),
            const _DailyDealCard(),
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
                coldOwned: coldOwned,
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
    required bool coldOwned,
  }) {
    final iap = ref.read(iapServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    final products = [
      for (final p in IapProduct.values)
        // Heo đất có UI riêng ở dialog "Kiếm thêm" → không liệt kê ở đây.
        if (p != IapProduct.piggyBreak &&
            !(p == IapProduct.removeAds && adsRemoved) &&
            !(p == IapProduct.starterPack && starterOwned) &&
            !(p == IapProduct.doubleIncome && doubleOwned) &&
            !(p == IapProduct.coldStorage && coldOwned) &&
            // Combo chỉ hiện khi chưa có gói nào trong hai gói lẻ.
            !(p == IapProduct.comboNoAdsX2 && (adsRemoved || doubleOwned)))
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
            subtitle: Text(_firstBonus(p)
                ? '${iapDescription(l10n, p)}\n${l10n.iapFirstBuyNote}'
                : iapDescription(l10n, p)),
            trailing: FilledButton.tonal(
              key: Key('iap-buy-${p.id}'),
              // Chặn bấm tiếp trong lúc CÓ BẤT KỲ lượt mua nào đang xử lý
              // (màn thanh toán của store vốn đã modal, tránh bấm chồng gây
              // rối luồng plugin) hoặc đang khôi phục.
              onPressed: _pendingPurchase == null && !_restoring
                  ? () => _onBuyTap(p)
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
const double _priceButtonWidth = 92;

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

/// Thẻ "Ưu đãi hôm nay": một món giảm giá, mua một lần mỗi ngày (UTC), đổi món lúc 00:00 UTC.
class _DailyDealCard extends ConsumerWidget {
  const _DailyDealCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final now = ref.read(clockProvider)();
    final today = dayIndex(now);
    final deal = dailyDealFor(today);
    final claimed =
        ref.watch(gameControllerProvider.select((s) => s.dealClaimedDay)) == today;
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    final name = switch (deal.kind) {
      DealKind.packBasic => l10n.accessoryPackBasic,
      DealKind.packRare => l10n.accessoryPackRare,
      DealKind.packEpic => l10n.accessoryPackEpic,
      DealKind.timeSkip => l10n.gemTimeSkipName,
    };
    void snack(String text) => ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));

    return ClayTile(
      key: const Key('daily-deal'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(deal.kind == DealKind.timeSkip ? '⏩' : '🎁',
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.dealTitle,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(name,
                        key: const Key('daily-deal-name'),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                key: const Key('daily-deal-off'),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('-${deal.discountPercent}%',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Wrap (không phải Row): hộp thoại ở màn 320px chỉ rộng ~140px cho thẻ này.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text('${deal.baseGems} 💎',
                  key: const Key('daily-deal-base'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(decoration: TextDecoration.lineThrough)),
              if (claimed)
                Text(l10n.dealClaimed,
                    key: const Key('daily-deal-claimed'),
                    style: theme.textTheme.bodySmall),
              FilledButton.tonal(
                key: const Key('daily-deal-buy'),
                onPressed: claimed || gems < deal.price
                    ? null
                    : () {
                        final r = ref.read(gameControllerProvider.notifier).buyDailyDeal();
                        if (r == null) {
                          snack(l10n.dealUnavailable);
                        } else if (r.drop != null) {
                          snack(l10n.dealGotAccessory(
                              accessoryName(l10n, r.drop!.accessory.id)));
                        } else {
                          snack(l10n.instantCashSnack(formatNumber(r.cash)));
                        }
                      },
                child: Text('${deal.price} 💎'),
              ),
            ],
          ),
          Text(l10n.dealResets(formatDuration(dealSecondsLeft(now))),
              key: const Key('daily-deal-resets'), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Lối vào màn "Mốc nạp & VIP": thẻ toàn chiều ngang ở đầu cửa hàng, nền theo màu cấp VIP hiện tại
/// (mặc định vàng khi chưa có cấp), kèm cấp/biệt danh/EXP và chấm đỏ khi còn quà VIP chưa nhận.
class _VipEntryCard extends ConsumerWidget {
  const _VipEntryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final exp = ref.watch(gameControllerProvider.select((s) => s.vipExp));
    // Theo dõi các mốc đã nhận để chấm đỏ cập nhật ngay sau khi nhận quà.
    ref.watch(gameControllerProvider.select(
        (s) => '${s.vipClaimDay}/${s.vipClaimWeek}/${s.vipClaimMonth}'));
    final level = topupVipLevel(exp);
    final unclaimed = ref.read(gameControllerProvider.notifier).vipUnclaimedNow;
    final colors = vipTagColors[level == 0 ? 2 : level - 1];
    final fg = vipOnColor(colors);
    final subtitle = level == 0
        ? l10n.vipEntryHint
        : '${vipName(l10n, level)} · ${l10n.topupSummary(formatNumber(exp.toDouble()))}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        key: const Key('topup-open'),
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: colors.first.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => showTopupDialog(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.topupTitle,
                            key: const Key('topup-open-title'),
                            style: TextStyle(
                                color: fg, fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(subtitle,
                            key: const Key('topup-open-subtitle'),
                            style: TextStyle(color: fg.withValues(alpha: 0.9), fontSize: 12)),
                      ],
                    ),
                  ),
                  if (unclaimed)
                    Container(
                      key: const Key('topup-open-dot'),
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                          color: Color(0xFFE53935), shape: BoxShape.circle),
                    ),
                  Icon(Icons.chevron_right, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
