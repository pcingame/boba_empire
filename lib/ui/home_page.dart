import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../core/balance.dart';
import '../core/economy.dart';
import '../core/format.dart';
import '../ads/ad_service.dart';
import '../core/models.dart';
import '../iap/iap_products.dart';
import '../iap/iap_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'gem_shop.dart';
import 'offline_dialog.dart';
import 'prestige_dialog.dart';
import 'widgets/anim_assets.dart';
import 'widgets/animated_count.dart';
import 'widgets/mascot.dart';
import 'widgets/one_shot_lottie.dart';

/// Màn hình chính MVP: đầu trang hiển thị tiền, giữa là nút chạm pha trà,
/// dưới là shop nâng cấp. Cũng lo phần lifecycle (lưu khi app vào nền).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  StreamSubscription<IapProduct>? _iapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Nghe kết quả mua hàng để trao thưởng (stub phát rỗng → an toàn).
    _iapSub = ref.read(iapServiceProvider).purchases.listen(_onPurchase);
    // Tiền offline lúc mở app lạnh: ref.listen chỉ bắt thay đổi nên xử lý
    // giá trị ban đầu ở đây, sau frame đầu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Khôi phục sản phẩm non-consumable (Gỡ QC / Gói khởi động) đã mua.
      unawaited(ref.read(iapServiceProvider).restore());
      final earned = ref.read(gameControllerProvider).offlineEarned;
      if (earned > 0) _showOfflineDialog(earned);
    });
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Trao thưởng cho một sản phẩm vừa mua/khôi phục. Idempotent: không báo trùng
  /// khi restore lặp lại lúc mở app.
  void _onPurchase(IapProduct product) {
    final controller = ref.read(gameControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    String message;
    switch (product) {
      case IapProduct.gems:
        controller.grantGemsPurchase(Balance.iapGemsSmall);
        message = l10n.iapGemsSnack(formatNumber(Balance.iapGemsSmall));
      case IapProduct.removeAds:
        final already = ref.read(gameControllerProvider).adsRemoved;
        controller.applyRemoveAds();
        if (already) return; // chỉ khôi phục lại, không báo trùng.
        message = l10n.iapRemoveAdsSnack;
      case IapProduct.starterPack:
        if (!controller.applyStarterPack()) return; // đã sở hữu.
        message = l10n.iapStarterSnack(formatNumber(Balance.iapStarterGems));
    }
    ref.read(audioServiceProvider).play(Sfx.reward);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(gameControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        controller.saveNow(); // bắt cả trường hợp vuốt tắt app
      case AppLifecycleState.resumed:
        controller.handleResume(); // bù tiền cho lúc ở nền
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  bool _offlineDialogOpen = false;

  Future<void> _showOfflineDialog(double earned) async {
    if (_offlineDialogOpen || !mounted) return;
    _offlineDialogOpen = true;
    await showOfflineDialog(context, earned);
    _offlineDialogOpen = false;
    // Dù đóng bằng cách nào cũng dọn trạng thái popup (no-op nếu đã nhân đôi).
    ref.read(gameControllerProvider.notifier).acknowledgeOffline();
  }

  @override
  Widget build(BuildContext context) {
    // Tiền offline lúc app trở lại foreground (giá trị đổi từ 0 -> X).
    ref.listen(
      gameControllerProvider.select((s) => s.offlineEarned),
      (previous, next) {
        if (next > 0) _showOfflineDialog(next);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        centerTitle: true,
        actions: const [_GemShopButton(), _PrestigeButton()],
      ),
      body: const Stack(
        children: [
          Column(
            children: [
              _MoneyHeader(),
              Expanded(child: _TapArea()),
              _Shop(),
            ],
          ),
          _BoostIndicator(),
          _GoldenCat(),
          _VipCustomer(),
        ],
      ),
    );
  }
}

/// Nút mở Cửa hàng Kim Cương ở AppBar.
class _GemShopButton extends StatelessWidget {
  const _GemShopButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('gem-shop-button'),
      onPressed: () => showGemShop(context),
      icon: const Icon(Icons.diamond),
    );
  }
}

/// Nút Sao ở AppBar: hiện số Sao, chấm đỏ khi có thể nhượng quyền, mở dialog.
class _PrestigeButton extends ConsumerWidget {
  const _PrestigeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars =
        ref.watch(gameControllerProvider.select((s) => s.prestigeStars));
    final available = ref.watch(
      gameControllerProvider.select((s) => s.prestigeStarsAvailable),
    );

    return IconButton(
      key: const Key('prestige-button'),
      onPressed: () => showPrestigeDialog(context),
      icon: Badge(
        label: Text('$stars'),
        isLabelVisible: stars > 0,
        child: Icon(
          Icons.star,
          color: available > 0 ? Colors.amberAccent : null,
        ),
      ),
    );
  }
}

/// Đầu trang: tiền + thu nhập/giây. Widget riêng để chỉ phần này rebuild mỗi
/// giây, không kéo theo cả màn hình (tối ưu Riverpod).
class _MoneyHeader extends ConsumerWidget {
  const _MoneyHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money =
        ref.watch(gameControllerProvider.select((s) => s.money));
    final income =
        ref.watch(gameControllerProvider.select((s) => s.incomePerSecond));
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: theme.colorScheme.primaryContainer,
      child: Column(
        children: [
          AnimatedCount(
            money,
            suffix: l10n.coinsSuffix,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            l10n.incomePerSecond(formatNumber(income)),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '💎 ${formatNumber(gems)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          if (income > 0) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: const Key('instant-cash'),
              onPressed: () => _claimInstantCash(context, ref),
              icon: const Icon(Icons.card_giftcard),
              label: Text(l10n.instantCashButton),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _claimInstantCash(BuildContext context, WidgetRef ref) async {
    final ads = ref.read(adServiceProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final adsRemoved = ref.read(gameControllerProvider).adsRemoved;
    final outcome =
        adsRemoved ? RewardOutcome.earned : await ads.showRewardedAd();
    if (outcome != RewardOutcome.earned) return;
    final reward = controller.claimInstantCash();
    if (reward > 0) {
      ref.read(audioServiceProvider).play(Sfx.reward);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.instantCashSnack(formatNumber(reward)))),
      );
    }
  }
}

/// Vùng giữa: nút lớn để chạm pha trà. Không watch state nào nên không rebuild
/// theo tick — chỉ đọc notifier để gọi hành động.
class _TapArea extends ConsumerWidget {
  const _TapArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: GestureDetector(
        onTap: () {
          ref.read(gameControllerProvider.notifier).tapCup();
          ref.read(audioServiceProvider).play(Sfx.tap);
          playEffect(context, AnimAssets.coins, size: 140);
        },
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animation nếu có file, ngược lại emoji 🧋.
              const Mascot(asset: AnimAssets.cup, emoji: '🧋', size: 80),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.tapBrew,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Danh sách nâng cấp — chỉ hiện nguồn thu của các giai đoạn đã mở khóa, có
/// tiêu đề giai đoạn + nút mở khóa, và cuộn được khi nhiều mục.
class _Shop extends ConsumerWidget {
  const _Shop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(gameControllerProvider.select((s) => s.stage));
    final unlocked = [
      for (final config in Balance.generators)
        if (config.stage <= stage) config,
    ];

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _StageHeader(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final config in unlocked) _ShopTile(config),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiêu đề giai đoạn hiện tại + nút mở khóa giai đoạn kế (nếu còn).
class _StageHeader extends ConsumerWidget {
  const _StageHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(gameControllerProvider.select((s) => s.stage));
    final money = ref.watch(gameControllerProvider.select((s) => s.money));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final next = Balance.nextStageConfig(stage);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.stageHeader(stageName(l10n, stage)),
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (next != null)
            FilledButton(
              key: const Key('unlock-stage'),
              onPressed: money >= next.unlockCost
                  ? () {
                      if (ref
                          .read(gameControllerProvider.notifier)
                          .unlockStage()) {
                        ref.read(audioServiceProvider).play(Sfx.unlock);
                        playEffect(context, AnimAssets.celebration, size: 280);
                      }
                    }
                  : null,
              child: Text(l10n.unlockStageButton(formatNumber(next.unlockCost))),
            ),
        ],
      ),
    );
  }
}

/// Một dòng shop. Watch riêng cấp của nó + tiền (để bật/mờ nút mua).
class _ShopTile extends ConsumerWidget {
  const _ShopTile(this.config);

  final GeneratorConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(
      gameControllerProvider.select((s) => s.levelOf(config.id)),
    );
    final money =
        ref.watch(gameControllerProvider.select((s) => s.money));
    final cost = nextLevelCost(config, level);
    final canAfford = money >= cost;
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: CircleAvatar(child: Text('$level')),
      title: Text(generatorName(l10n, config.id)),
      subtitle: Text(
        l10n.generatorSubtitle(formatNumber(config.incomePerLevelPerSecond)),
      ),
      trailing: FilledButton(
        onPressed: canAfford
            ? () {
                if (ref
                    .read(gameControllerProvider.notifier)
                    .buy(config.id)) {
                  ref.read(audioServiceProvider).play(Sfx.buy);
                  playEffect(context, AnimAssets.confetti, size: 160);
                }
              }
            : null,
        child: Text(l10n.buyButton(formatNumber(cost))),
      ),
    );
  }
}

/// Đồng hồ đếm ngược khi Mưa vàng đang chạy (×3). Ẩn khi không có boost.
class _BoostIndicator extends ConsumerWidget {
  const _BoostIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(
      gameControllerProvider.select((s) => s.boostRemainingSeconds),
    );
    if (remaining <= 0) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Chip(
          backgroundColor: Colors.amber,
          label: Text(AppLocalizations.of(context)!.boostChip(remaining.ceil())),
        ),
      ),
    );
  }
}

/// Con mèo may mắn: hiện khi có sự kiện, chạm để kích hoạt Mưa vàng.
class _GoldenCat extends ConsumerWidget {
  const _GoldenCat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible =
        ref.watch(gameControllerProvider.select((s) => s.catVisible));
    if (!visible) return const SizedBox.shrink();

    return Positioned(
      right: 24,
      bottom: 24,
      child: GestureDetector(
        key: const Key('golden-cat'),
        onTap: () async {
          // Xem quảng cáo thưởng để nhận Mưa vàng (đúng thiết kế GDD). Nếu đã
          // mua "Gỡ quảng cáo" thì trao ngay, không cần xem.
          final ads = ref.read(adServiceProvider);
          final controller = ref.read(gameControllerProvider.notifier);
          final adsRemoved = ref.read(gameControllerProvider).adsRemoved;
          final outcome =
              adsRemoved ? RewardOutcome.earned : await ads.showRewardedAd();
          if (outcome == RewardOutcome.earned) {
            controller.activateGoldenRush();
            ref.read(audioServiceProvider).play(Sfx.reward);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber,
            boxShadow: [
              BoxShadow(color: Colors.amber, blurRadius: 24, spreadRadius: 4),
            ],
          ),
          child: const Mascot(asset: AnimAssets.cat, emoji: '🐱', size: 56),
        ),
      ),
    );
  }
}

/// Khách VIP đi ô tô đến: chạm để thu tiền lớn + Kim Cương (không cần quảng cáo).
class _VipCustomer extends ConsumerWidget {
  const _VipCustomer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible =
        ref.watch(gameControllerProvider.select((s) => s.vipVisible));
    if (!visible) return const SizedBox.shrink();

    return Positioned(
      left: 24,
      bottom: 24,
      child: GestureDetector(
        key: const Key('vip-customer'),
        onTap: () {
          final messenger = ScaffoldMessenger.of(context);
          final reward = ref.read(gameControllerProvider.notifier).collectVip();
          if (reward.gems > 0) {
            ref.read(audioServiceProvider).play(Sfx.vip);
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .vipSnack(formatNumber(reward.cash), reward.gems),
                ),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.deepPurple,
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurpleAccent,
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Mascot(asset: AnimAssets.car, emoji: '🚗', size: 56),
        ),
      ),
    );
  }
}
