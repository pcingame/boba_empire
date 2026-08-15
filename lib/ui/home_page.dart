import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'achievements_dialog.dart';
import 'daily_dialog.dart';
import 'gem_shop.dart';
import 'how_to_play_dialog.dart';
import 'offline_dialog.dart';
import 'prestige_dialog.dart';
import 'rewards_dialog.dart';
import 'settings_dialog.dart';
import 'widgets/anim_assets.dart';
import 'widgets/animated_count.dart';
import 'widgets/clay.dart';
import 'widgets/mascot.dart';
import 'widgets/one_shot_lottie.dart';

/// Cho phép tự hiện "Cách chơi" ở lần chơi đầu. App luôn bật; test tắt qua
/// flutter_test_config để dialog modal không che thao tác, và test hướng dẫn
/// bật lại để kiểm. (Giống [debugDisableMascotAnimation].)
bool debugAutoShowTutorial = true;

/// Cho phép tự hiện popup điểm danh hằng ngày khi mở app. Test tắt để dialog
/// modal không che thao tác.
bool debugAutoShowDaily = true;

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
      final state = ref.read(gameControllerProvider);
      // Lần chơi đầu (chưa xem hướng dẫn, không vướng popup offline): mở "Cách
      // chơi". Nếu đang có tiền offline thì nhường popup đó, để hướng dẫn lần sau.
      if (debugAutoShowTutorial &&
          !state.tutorialSeen &&
          state.offlineEarned <= 0) {
        ref.read(gameControllerProvider.notifier).markTutorialSeen();
        showHowToPlay(context);
      } else if (state.offlineEarned > 0) {
        _showOfflineDialog(state.offlineEarned);
      } else if (debugAutoShowDaily && state.dailyAvailable) {
        // Điểm danh: chỉ khi không vướng hướng dẫn/offline để tránh chồng dialog.
        showDailyReward(context);
      }
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
      case IapProduct.gemsSmall ||
            IapProduct.gemsMedium ||
            IapProduct.gemsLarge:
        controller.grantGemsPurchase(product.gems);
        message = l10n.iapGemsSnack(formatNumber(product.gems));
      case IapProduct.removeAds:
        final already = ref.read(gameControllerProvider).adsRemoved;
        controller.applyRemoveAds();
        if (already) return; // chỉ khôi phục lại, không báo trùng.
        message = l10n.iapRemoveAdsSnack;
      case IapProduct.starterPack:
        if (!controller.applyStarterPack()) return; // đã sở hữu.
        message = l10n.iapStarterSnack(formatNumber(Balance.iapStarterGems));
      case IapProduct.doubleIncome:
        final already = ref.read(gameControllerProvider).doubleIncomeOwned;
        controller.applyDoubleIncome();
        if (already) return; // chỉ khôi phục, không báo trùng.
        message = l10n.iapDoubleSnack;
      case IapProduct.piggyBreak:
        final gained = controller.breakPiggy();
        if (gained <= 0) return;
        message = l10n.piggySnack(formatNumber(gained));
      case IapProduct.vip30:
        controller.buyVip();
        message = l10n.iapVipSnack;
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

    // Mở khoá thành tựu → chỉ chơi âm thanh; chấm đỏ trên nút 🏆 mời người chơi
    // xem (tránh snackbar tranh chỗ với thông báo hành động khác).
    ref.listen(
      gameControllerProvider.select((s) => s.newAchievements.length),
      (previous, next) {
        if (next > (previous ?? 0)) {
          ref.read(audioServiceProvider).play(Sfx.reward);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('how-to-play-button'),
          icon: const Icon(Icons.help_outline),
          onPressed: () => showHowToPlay(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.appTitle,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Fredoka',
            fontFamilyFallback: ['Roboto'],
          ),
        ),
        titleSpacing: 0,
        actions: [
          IconButton(
            key: const Key('settings-button'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettings(context),
          ),
        ],
      ),
      body: const Stack(
        children: [
          Column(
            children: [
              _MoneyHeader(),
              Expanded(child: _StageScene()),
              _Shop(),
            ],
          ),
          _BoostIndicator(),
          _GoldenCat(),
          _VipCustomer(),
        ],
      ),
      bottomNavigationBar: const _BottomBar(),
    );
  }
}

/// Thanh điều hướng dưới cùng: Nhà · Cửa hàng · Nhượng quyền · Thành tựu. Các
/// mục (trừ Nhà) mở dialog tương ứng; giữ key cũ để test/quen thao tác.
class _BottomBar extends ConsumerWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final stars =
        ref.watch(gameControllerProvider.select((s) => s.prestigeStars));
    final starsAvail = ref.watch(
      gameControllerProvider.select((s) => s.prestigeStarsAvailable),
    );
    final newAch = ref.watch(
      gameControllerProvider.select((s) => s.newAchievements.isNotEmpty),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _navItem(theme, icon: Icons.home_rounded, label: l10n.navHome,
                  onTap: () {}),
              _navItem(theme,
                  buttonKey: const Key('gem-shop-button'),
                  icon: Icons.storefront,
                  label: l10n.navShop,
                  onTap: () => showGemShop(context)),
              _navItem(theme,
                  buttonKey: const Key('prestige-button'),
                  icon: Icons.star_rounded,
                  label: l10n.navPrestige,
                  badgeCount: stars > 0 ? '$stars' : null,
                  highlight: starsAvail > 0,
                  onTap: () => showPrestigeDialog(context)),
              _navItem(theme,
                  buttonKey: const Key('achievements-button'),
                  icon: Icons.emoji_events,
                  label: l10n.navAchievements,
                  badge: newAch,
                  onTap: () {
                    ref
                        .read(gameControllerProvider.notifier)
                        .acknowledgeAchievements();
                    showAchievements(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    ThemeData theme, {
    Key? buttonKey,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool badge = false,
    String? badgeCount,
    bool highlight = false,
  }) {
    return Expanded(
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              label: badgeCount != null ? Text(badgeCount) : null,
              isLabelVisible: badgeCount != null || badge,
              child: Icon(
                icon,
                color: highlight ? Colors.amber : theme.colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
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
    final vip = ref.watch(gameControllerProvider.select((s) => s.vipActive));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final onContainer = theme.colorScheme.onPrimaryContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
          ],
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Hàng trên: nút "Ưu đãi" (xem QC thưởng) bên trái, chip 💎 bên phải.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => showRewards(context),
                child: ClayChip(
                  child: Text(
                    AppLocalizations.of(context)!.rewardsTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onContainer,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vip) ...[
                    ClayChip(
                      color: Colors.amber.shade200,
                      child: Text(
                        '👑 VIP',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ClayChip(
                    child: Text(
                      '💎 ${formatNumber(gems)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: onContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          AnimatedCount(
            money,
            suffix: l10n.coinsSuffix,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: onContainer,
            ),
          ),
          Text(
            l10n.incomePerSecond(formatNumber(income)),
            style: theme.textTheme.titleMedium?.copyWith(
              color: onContainer.withValues(alpha: 0.85),
            ),
          ),
          // AnimatedSize: header giãn mượt khi nút xuất hiện (lần mua đầu) thay
          // vì nhảy giật.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: income > 0
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton.tonalIcon(
                      key: const Key('instant-cash'),
                      onPressed: () => _claimInstantCash(context, ref),
                      icon: const Icon(Icons.card_giftcard),
                      label: Text(l10n.instantCashButton),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Future<void> _claimInstantCash(BuildContext context, WidgetRef ref) async {
    final ads = ref.read(adServiceProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final adFree = ref.read(gameControllerProvider).adFree;
    final outcome =
        adFree ? RewardOutcome.earned : await ads.showRewardedAd();
    if (outcome != RewardOutcome.earned) return;
    final reward = controller.claimInstantCash();
    if (reward > 0) {
      HapticFeedback.mediumImpact();
      ref.read(audioServiceProvider).play(Sfx.reward);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.instantCashSnack(formatNumber(reward)))),
      );
    }
  }
}

/// Backdrop cảnh quán theo giai đoạn (Xe đẩy → Kiosk → Chuỗi cafe) với vùng
/// chạm nổi lên trên. Đổi cảnh mượt (crossfade) khi mở khóa giai đoạn mới —
/// phần thưởng thị giác cho tiến trình.
class _StageScene extends ConsumerWidget {
  const _StageScene();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(gameControllerProvider.select((s) => s.stage));
    final theme = Theme.of(context);
    final n = stage.clamp(1, 6);

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Image.asset(
            'assets/scene/stage$n.png',
            key: ValueKey(n),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            // Thiếu asset (vd môi trường test) thì nền trơn thay vì vỡ.
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),
        // Dark mode: phủ lớp mờ để cảnh sáng hoà với nền tối + cup nổi rõ.
        if (theme.brightness == Brightness.dark)
          ColoredBox(
            color: theme.colorScheme.surface.withValues(alpha: 0.4),
          ),
        const _TapArea(),
      ],
    );
  }
}

/// Vùng giữa: nút lớn để chạm pha trà. Có hiệu ứng nhấn (thu nhỏ + bật lại) và
/// rung nhẹ để "đã tay" — yếu tố quan trọng nhất của game chạm.
class _TapArea extends ConsumerStatefulWidget {
  const _TapArea();

  @override
  ConsumerState<_TapArea> createState() => _TapAreaState();
}

class _TapAreaState extends ConsumerState<_TapArea>
    with TickerProviderStateMixin {
  // Chạm → "squish rồi bật vượt" (0.9 → 1.06 → 1.0) cho cảm giác đã tay.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final Animation<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.9).chain(CurveTween(curve: Curves.easeOut)),
      weight: 28,
    ),
    TweenSequenceItem(
      tween:
          Tween(begin: 0.9, end: 1.06).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween:
          Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
      weight: 32,
    ),
  ]).animate(_pop);

  // Combo: mỗi cú chạm khi controller còn chạy sẽ +1; ngừng chạm ~1.1s thì
  // controller kết thúc và combo ẩn đi. Dùng AnimationController (không Timer)
  // để pumpAndSettle trong test không bị treo/kẹt timer.
  late final AnimationController _combo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _comboCount = 0);
      }
    });
  int _comboCount = 0;

  // Nhịp "thở" nhẹ của ly (mascot có sức sống). Tắt trong test (ticker lặp).
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  final math.Random _rng = math.Random();
  final List<_Floater> _floaters = [];

  @override
  void initState() {
    super.initState();
    if (!debugDisableMascotAnimation) _bob.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pop.dispose();
    _combo.dispose();
    _bob.dispose();
    super.dispose();
  }

  void _onTap() {
    // Squish rồi bật vượt (hữu hạn nên pumpAndSettle không treo).
    _pop.forward(from: 0);
    HapticFeedback.lightImpact();
    final gained = ref.read(gameControllerProvider.notifier).tapCup();
    ref.read(audioServiceProvider).play(Sfx.tap);
    playEffect(context, AnimAssets.coins, size: 140);

    final key = UniqueKey();
    setState(() {
      _comboCount = _combo.isAnimating ? _comboCount + 1 : 1;
      _floaters.add(_Floater(
        key: key,
        text: '+${formatNumber(gained)}',
        dx: (_rng.nextDouble() - 0.5) * 0.7,
        onDone: () {
          if (mounted) setState(() => _floaters.removeWhere((f) => f.key == key));
        },
      ));
    });
    _combo.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        ..._floaters,
        if (_comboCount >= 2)
          Align(
            alignment: const Alignment(0, -0.62),
            child: AnimatedBuilder(
              animation: _combo,
              builder: (context, child) => Opacity(
                opacity: (1 - _combo.value * _combo.value).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1 + 0.25 * (1 - _combo.value),
                  child: child,
                ),
              ),
              child: Text(
                'COMBO ×$_comboCount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
          ),
        Center(
          child: GestureDetector(
            onTap: _onTap,
            child: ScaleTransition(
              scale: _popScale,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color:
                          theme.colorScheme.shadow.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                // Co lại khi vòng bị ép nhỏ (ngôn ngữ dài) thay vì tràn.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animation nếu có file, ngược lại emoji 🧋. Bob nhẹ cho có hồn.
                      AnimatedBuilder(
                        animation: _bob,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(
                              0, -7 * Curves.easeInOut.transform(_bob.value)),
                          child: child,
                        ),
                        child: const Mascot(
                            asset: AnimAssets.cup, emoji: '🧋', size: 72),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 150,
                        child: Text(
                          AppLocalizations.of(context)!.tapBrew,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Số "+X" bay lên và mờ dần khi chạm ly — phản hồi tức thì cho mỗi cú chạm.
class _Floater extends StatefulWidget {
  const _Floater({
    required super.key,
    required this.text,
    required this.dx,
    required this.onDone,
  });

  final String text;
  final double dx;
  final VoidCallback onDone;

  @override
  State<_Floater> createState() => _FloaterState();
}

class _FloaterState extends State<_Floater>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        return Align(
          alignment: Alignment(widget.dx, -0.05 - t * 0.55),
          child: Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: child),
        );
      },
      child: Text(
        widget.text,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black26)],
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
            const _QuestBar(),
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

/// Thanh nhiệm vụ hiện tại: mô tả + tiến độ; đủ điều kiện thì hiện nút "Nhận".
/// Ẩn khi đã hoàn thành toàn bộ chuỗi.
class _QuestBar extends ConsumerWidget {
  const _QuestBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quest =
        ref.watch(gameControllerProvider.select((s) => s.currentQuest));
    if (quest == null) return const SizedBox.shrink();
    final progress =
        ref.watch(gameControllerProvider.select((s) => s.questProgress));
    final done = ref.watch(gameControllerProvider.select((s) => s.questDone));
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ratio = (progress / quest.threshold).clamp(0.0, 1.0).toDouble();
    final cur = progress > quest.threshold ? quest.threshold : progress;

    return Container(
      width: double.infinity,
      color: theme.colorScheme.secondaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  questDesc(l10n, quest),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.onSecondaryContainer
                        .withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (done)
            FilledButton(
              key: const Key('quest-claim'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () {
                if (ref
                        .read(gameControllerProvider.notifier)
                        .claimCurrentQuest() >
                    0) {
                  HapticFeedback.mediumImpact();
                  ref.read(audioServiceProvider).play(Sfx.reward);
                }
              },
              child: Text('${l10n.questClaim} +${quest.rewardGems}💎'),
            )
          else
            Text(
              '${formatNumber(cur.toDouble())}/'
              '${formatNumber(quest.threshold.toDouble())}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (next != null)
            Flexible(
              child: FilledButton(
                key: const Key('unlock-stage'),
                onPressed: money >= next.unlockCost
                    ? () {
                        if (ref
                            .read(gameControllerProvider.notifier)
                            .unlockStage()) {
                          HapticFeedback.mediumImpact();
                          ref.read(audioServiceProvider).play(Sfx.unlock);
                          playEffect(context, AnimAssets.celebration,
                              size: 280);
                        }
                      }
                    : null,
                child: Text(
                  l10n.unlockStageButton(formatNumber(next.unlockCost)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Emoji minh họa cho từng nguồn thu (không phụ thuộc ngôn ngữ).
const Map<String, String> _generatorEmoji = {
  'tra_den': '🍵',
  'tran_chau': '🧋',
  'thach': '🍮',
  'pudding': '🍰',
  'kem_nuong': '🔥',
  'matcha': '🍵',
  'duong_den': '🥤',
  'brulee': '🍯',
  'cheese_foam': '🧀',
  'tra_trai_cay': '🍓',
  'boba_vang': '🌟',
  'galaxy': '🌌',
};

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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: ClayCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Emoji + huy hiệu cấp để đọc lướt nhanh.
            Badge(
              label: Text('$level'),
              isLabelVisible: level > 0,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(
                  _generatorEmoji[config.id] ?? '🧋',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    generatorName(l10n, config.id),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    l10n.generatorSubtitle(
                        formatNumber(config.incomePerLevelPerSecond)),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  _MilestoneBar(level: level),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: canAfford
                  ? () {
                      if (ref
                          .read(gameControllerProvider.notifier)
                          .buy(config.id)) {
                        HapticFeedback.selectionClick();
                        ref.read(audioServiceProvider).play(Sfx.buy);
                        playEffect(context, AnimAssets.confetti, size: 160);
                      }
                    }
                  : null,
              child: Text(l10n.buyButton(formatNumber(cost))),
            ),
          ],
        ),
      ),
    );
  }
}

/// Huy hiệu mốc nhân bội của một nguồn thu: chip ×N hiện tại + thanh tiến độ
/// tới mốc kế → ×target. Thuần số/ký hiệu nên không cần dịch.
class _MilestoneBar extends StatelessWidget {
  const _MilestoneBar({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mult = generatorMilestoneMultiplier(level).round();
    final target = (mult * Balance.milestoneFactor).round();
    final progress = (level % Balance.milestoneStep) / Balance.milestoneStep;

    return Row(
      children: [
        if (mult > 1) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '×$mult',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '→×$target',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
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

/// Nhấp nháy (scale in/out lặp) để hút mắt vào cơ hội giới hạn thời gian (mèo
/// may mắn / khách VIP). Tắt trong test qua [debugDisableMascotAnimation] để
/// pumpAndSettle không treo bởi ticker lặp vô hạn.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (!debugDisableMascotAnimation) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
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
          final adFree = ref.read(gameControllerProvider).adFree;
          final outcome =
              adFree ? RewardOutcome.earned : await ads.showRewardedAd();
          if (outcome == RewardOutcome.earned) {
            controller.activateGoldenRush();
            HapticFeedback.mediumImpact();
            ref.read(audioServiceProvider).play(Sfx.reward);
          }
        },
        child: _Pulse(
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
            HapticFeedback.mediumImpact();
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
        child: _Pulse(
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
      ),
    );
  }
}
