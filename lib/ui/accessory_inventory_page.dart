/// "Kho phụ kiện" — sưu tập cosmetic thuần (không ảnh hưởng số liệu). Rớt từ
/// nhiệm vụ ngày (xem GameController.claimDailyBonus). Mở từ nút ✨ ở màn chính
/// (home_page.dart `_CollectionChip`); từ đây vào Chợ (icon cửa hàng) và BXH Sưu tập (🏆).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessories.dart';
import '../core/collection_milestones.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../leaderboard/flair.dart';
import '../state/game_providers.dart';
import 'accessory_how_to_dialog.dart';
import 'accessory_leaderboard_page.dart';
import 'accessory_pack_dialog.dart';
import 'collection_share_dialog.dart';
import '../market/market_highlight.dart';
import 'accessory_market_page.dart';
import 'widgets/accessory_rarity.dart';
import 'widgets/clay.dart';
import 'widgets/motion.dart';
import 'widgets/phone_width.dart';
import 'widgets/weekend_banner.dart';

Future<void> showAccessoryInventory(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AccessoryInventoryPage()));
}

class AccessoryInventoryPage extends ConsumerWidget {
  const AccessoryInventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final owned = ref.watch(
      gameControllerProvider.select((s) => s.ownedAccessories.length),
    );
    final equippedCount = ref.watch(
      gameControllerProvider.select((s) => s.equippedAccessories.length),
    );
    final maxEquipped = maxEquippedFor(
      vip: ref.watch(gameControllerProvider.select((s) => s.vipActive)),
    );

    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(
          // 3 nút bên phải chiếm chỗ: tiêu đề dài ('Accessory Collection') bị cắt
          // '…'. Co chữ cho vừa (tĩnh, 0 khung hình nền) thay vì chạy chữ: trang
          // này đã nặng (lưới 50 ô) và không nên có animation vô hạn.
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(l10n.accessoryInventoryTitle, maxLines: 1),
          ),
          actions: [
            IconButton(
              key: const Key('collection-share'),
              icon: const Icon(Icons.ios_share),
              tooltip: l10n.collectionShareTooltip,
              onPressed: () => showCollectionShare(context),
            ),
            IconButton(
              key: const Key('collection-market-button'),
              icon: Badge(
                key: const Key('collection-market-dot'),
                isLabelVisible:
                    ref.watch(marketHighlightProvider).value != null,
                child: const Icon(Icons.storefront),
              ),
              tooltip: l10n.marketTitle,
              onPressed: () => showAccessoryMarket(context),
            ),
            IconButton(
              icon: const Text('🏆', style: TextStyle(fontSize: 20)),
              tooltip: l10n.accessoryLbTitle,
              onPressed: () => showAccessoryLeaderboard(context),
            ),
          ],
        ),
        // Cả trang cuộn chung (tiêu đề + mốc + lưới): máy nhỏ/chữ to thì phần
        // đầu cao hơn, để cố định thì tràn dọc.
        body: ScrollConfiguration(
          // Tắt hiệu ứng kéo giãn của Android (StretchingOverscrollIndicator):
          // khi cuộn hết cỡ nó BÓP nội dung ở mép, lưới ô vuông thì méo rất
          // lộ — cùng bug + cách fix đã dùng ở match3_journey_page.dart.
          behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: WeekendBanner()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.accessoryInventoryOwned(
                                owned,
                                accessories.length,
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          // Gọn trong hàng tiêu đề (không thêm chiều cao: lưới
                          // bên dưới đã dài, nhiều test cuộn tới ô theo vị trí).
                          IconButton(
                            key: const Key('accessory-how-to-button'),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.help_outline),
                            tooltip: l10n.accessoryHowToButton,
                            onPressed: () => showAccessoryHowTo(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.accessoryEquipHint(equippedCount, maxEquipped),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        l10n.accessoryFlairHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          key: const Key('accessory-pack-button'),
                          onPressed: () => showAccessoryPacks(context),
                          icon: const Text('🎁'),
                          label: Text(l10n.accessoryPackButton),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: owned / accessories.length,
                          minHeight: 8,
                        ),
                      ),
                      const _MilestoneStrip(),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: accessories.length,
                  itemBuilder: (context, i) =>
                      _AccessoryCell(accessory: accessories[i], appearIndex: i),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    l10n.festivalSection,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              for (final f in festivals) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Text(
                      festivalName(l10n, f.id),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: f.items.length,
                    itemBuilder: (context, i) =>
                        _AccessoryCell(accessory: f.items[i], limited: true),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessoryCell extends ConsumerWidget {
  const _AccessoryCell({
    required this.accessory,
    this.limited = false,
    this.appearIndex = 0,
  });
  final Accessory accessory;

  /// Thứ tự trong lưới — lệch nhịp hiện ra giữa các ô (xem [_AppearIn]).
  final int appearIndex;

  /// Món độc quyền lễ hội: lưu riêng ([GameState.ownedLimited]), không làm huy
  /// hiệu BXH (nhấn giữ tắt) và không có bản dư.
  final bool limited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // select riêng cờ "đã có món này" (giống _AchievementRow ở
    // achievements_dialog.dart) — mỗi ô chỉ rebuild khi ĐÚNG món của nó đổi,
    // không phải toàn bộ lưới mỗi khi danh sách tăng thêm 1 món khác.
    final unlocked = ref.watch(
      gameControllerProvider.select(
        (s) =>
            s.ownedAccessories.contains(accessory.id) ||
            s.ownedLimited.contains(accessory.id),
      ),
    );
    final spares = ref.watch(
      gameControllerProvider.select(
        (s) => s.accessorySpares[accessory.id] ?? 0,
      ),
    );
    final equipped = ref.watch(
      gameControllerProvider.select(
        (s) => s.equippedAccessories.contains(accessory.id),
      ),
    );
    final color = rarityColor(accessory.rarity);

    void onTap() {
      if (!unlocked) return;
      final changed = ref
          .read(gameControllerProvider.notifier)
          .toggleEquippedAccessory(accessory.id);
      if (changed) {
        HapticFeedback.selectionClick();
      } else {
        // Đã đủ chỗ trưng bày: báo thay vì im lặng.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.accessoryEquipFull(
                maxEquippedFor(vip: ref.read(gameControllerProvider).vipActive),
              ),
            ),
          ),
        );
      }
    }

    Future<void> onLongPress() async {
      if (!unlocked) return;
      HapticFeedback.mediumImpact();
      final cache = ref.read(flairCacheProvider.notifier);
      final isCurrent = cache.isMine(accessory.emoji);
      final ok = await cache.setMine(isCurrent ? null : accessory.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !ok
                ? l10n.accessoryFlairFailed
                : isCurrent
                ? l10n.accessoryFlairCleared
                : l10n.accessoryFlairSet(accessoryName(l10n, accessory.id)),
          ),
        ),
      );
    }

    return GestureDetector(
      key: Key('accessory-cell-${accessory.id}'),
      onTap: onTap,
      onLongPress: limited ? null : onLongPress,
      // StackFit.expand: Stack mặc định nới lỏng ràng buộc nên ô co lại theo
      // nội dung (hẹp, lệch trái) thay vì lấp đầy ô lưới.
      child: _AppearIn(
        index: appearIndex,
        // Huyền thoại đã có: một nhịp sáng lúc hiện ra (hữu hạn).
        glow: unlocked && accessory.rarity == AccessoryRarity.legendary
            ? color
            : null,
        // Chạm để trưng bày → ô nảy lên một nhịp.
        child: PulseOnIncrease(
          value: equipped ? 1 : 0,
          peak: 1.1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: unlocked ? 1.0 : 0.45,
                child: Container(
                  // Viền màu theo độ hiếm — trước đây 4 độ hiếm nhìn giống hệt nhau,
                  // chỉ khác ở 1 dòng chữ nhỏ dưới cùng, không quét nhanh bằng mắt
                  // được kiểu game sưu tập thường có.
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: equipped ? theme.colorScheme.primary : color,
                      width: equipped ? 3.5 : 2,
                    ),
                  ),
                  child: ClayCard(
                    padding: const EdgeInsets.all(8),
                    color: Color.alphaBlend(
                      color.withValues(alpha: unlocked ? 0.14 : 0.06),
                      theme.colorScheme.surface,
                    ),
                    // Ô lưới rất hẹp (3 cột) — tên phụ kiện dịch ra vài ngôn ngữ dài
                    // hơn hẳn (VD "Unicórnio Pequeno") cùng cỡ chữ lớn (accessibility)
                    // làm Column tràn dọc. FittedBox co cả cụm vừa ô thay vì tràn —
                    // cùng cách đã sửa cột hạng ở leaderboard_page.dart.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            unlocked ? accessory.emoji : '❔',
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            unlocked
                                ? '${accessoryName(l10n, accessory.id)}'
                                      '${spares > 0 ? ' ×${spares + 1}' : ''}'
                                : '???',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RarityChip(
                            rarity: accessory.rarity,
                            label: accessoryRarityLabel(l10n, accessory.rarity),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Ghim 📌 trên món đang trưng bày (không chỉ dựa vào màu viền).
              if (equipped)
                const Positioned(
                  top: 6,
                  right: 10,
                  child: ExcludeSemantics(
                    child: Text('📌', style: TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô hiện ra: mờ → rõ + trượt lên nhẹ + phóng 0.94 → 1, lệch nhịp theo [index]
/// (cùng hàng lưới 3 cột nên `index % 3`/hàng cho cảm giác "rải"). Một lần,
/// hữu hạn — trang này đã nặng (lưới 160 ô) nên KHÔNG có animation vô hạn.
/// [glow] != null thì thêm vầng sáng màu độ hiếm sáng lên rồi tắt trong lúc hiện.
/// Tắt khi "giảm chuyển động".
class _AppearIn extends StatefulWidget {
  const _AppearIn({required this.index, required this.child, this.glow});

  final int index;
  final Widget child;
  final Color? glow;

  @override
  State<_AppearIn> createState() => _AppearInState();
}

class _AppearInState extends State<_AppearIn>
    with SingleTickerProviderStateMixin {
  static const _body = 320; // ms mỗi ô
  late final int _delay = (widget.index % 9) * 40; // tối đa 320ms trễ
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: _body + _delay + (widget.glow == null ? 0 : 500),
    ),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _delay / _c.duration!.inMilliseconds,
      (_delay + _body) / _c.duration!.inMilliseconds,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (!reduceMotion) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return widget.child;
    final glow = widget.glow;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _t.value;
        Widget w = Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
          ),
        );
        if (glow != null) {
          // Sáng dần tới giữa đoạn glow rồi tắt: sin(pi * x), x = tiến độ 0..1.
          final x = ((_c.value * _c.duration!.inMilliseconds - _delay) / 800)
              .clamp(0.0, 1.0);
          w = DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.7 * math.sin(math.pi * x)),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: w,
          );
        }
        return w;
      },
    );
  }
}

/// Hàng mốc sưu tập 10/25/40/50 + danh hiệu hiện tại. Nút nhận chỉ hiện khi
/// đã đạt mốc mà chưa nhận; server tự đếm và chặn nhận lặp.
class _MilestoneStrip extends ConsumerStatefulWidget {
  const _MilestoneStrip();

  @override
  ConsumerState<_MilestoneStrip> createState() => _MilestoneStripState();
}

class _MilestoneStripState extends ConsumerState<_MilestoneStrip> {
  bool _busy = false;

  /// Thẻ mốc rộng cố định, cuộn ngang: 9 mốc xếp một hàng thì chiếm ít chiều
  /// cao hơn lưới nhiều hàng và dải mốc dài thêm vẫn không phải đổi bố cục.
  static const double _cardWidth = 92;
  static const double _gap = 8;

  final _scroll = ScrollController();

  /// Mốc đang được cuộn tới (đầu tiên chưa nhận) — đổi thì cuộn lại.
  int? _focused;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Đưa mốc kế tiếp chưa nhận vào GIỮA dải (lần đầu nhảy thẳng, sau đó trượt).
  void _focus(int index, {required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final pos = _scroll.position;
      final target =
          (index * (_cardWidth + _gap) -
                  (pos.viewportDimension - _cardWidth) / 2)
              .clamp(0.0, pos.maxScrollExtent);
      if (animate) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  Future<void> _claim(CollectionMilestone m) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final r = await ref
        .read(gameControllerProvider.notifier)
        .claimCollectionMilestone(m.count);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.coins != null) {
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.collectionMilestoneDone(r.coins!))),
      );
    } else if (r.error == 'network') {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.collectionMilestoneErrNet)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // select theo CHUỖI để so sánh theo giá trị (snapshot tạo list mới mỗi tick).
    final key = ref.watch(
      gameControllerProvider.select(
        (s) =>
            '${s.ownedAccessories.length}|'
            '${s.collectionMilestonesClaimed.join(",")}',
      ),
    );
    final parts = key.split('|');
    final owned = int.parse(parts[0]);
    final claimed = parts[1].isEmpty
        ? <int>{}
        : parts[1].split(',').map(int.parse).toSet();
    final highest = collectionMilestones
        .where((m) => claimed.contains(m.count))
        .fold<CollectionMilestone?>(null, (_, m) => m);
    final next = collectionMilestones.indexWhere(
      (m) => !claimed.contains(m.count),
    );
    final focus = next < 0 ? collectionMilestones.length - 1 : next;
    if (_focused != focus) {
      _focus(focus, animate: _focused != null);
      _focused = focus;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highest != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.collectionTitleLabel(collectionTitle(l10n, highest.count)),
                key: const Key('collection-title'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < collectionMilestones.length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: _cardWidth,
                      child: _MilestoneCell(
                        milestone: collectionMilestones[i],
                        claimed: claimed.contains(
                          collectionMilestones[i].count,
                        ),
                        reached: owned >= collectionMilestones[i].count,
                        busy: _busy,
                        onClaim: () => _claim(collectionMilestones[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một mốc: số món ở trên, thưởng/trạng thái ở dưới. Đã nhận ✓ · đạt rồi thì
/// nổi bật và bấm được · chưa đạt thì mờ.
class _MilestoneCell extends StatelessWidget {
  const _MilestoneCell({
    required this.milestone,
    required this.claimed,
    required this.reached,
    required this.busy,
    required this.onClaim,
  });

  final CollectionMilestone milestone;
  final bool claimed;
  final bool reached;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final claimable = reached && !claimed;
    final scheme = theme.colorScheme;
    final Color bg = claimable
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final String sub = claimed ? '✓' : '${milestone.coins} 🪙';
    final cell = Container(
      key: Key(
        claimable
            ? 'milestone-claim-${milestone.count}'
            : 'milestone-${milestone.count}',
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: claimable ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${milestone.count}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: claimed || !reached
                    ? scheme.onSurface.withValues(alpha: claimed ? 0.8 : 0.5)
                    : scheme.onPrimaryContainer,
              ),
            ),
            Text(
              claimable ? '+$sub' : sub,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: claimable
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: reached ? 0.8 : 0.5),
              ),
            ),
          ],
        ),
      ),
    );
    final tip = claimable
        ? l10n.collectionMilestoneClaim(milestone.coins)
        : l10n.collectionMilestoneLocked(milestone.count, milestone.coins);
    return Tooltip(
      message: tip,
      child: claimable
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: busy ? null : onClaim,
              child: cell,
            )
          : cell,
    );
  }
}
