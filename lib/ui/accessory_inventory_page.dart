/// "Kho phụ kiện" — sưu tập + bộ trang bị (món đang mang cho buff, xem accessory_loadout.dart). Rớt từ
/// nhiệm vụ ngày (xem GameController.claimDailyBonus). Mở từ nút ✨ ở màn chính
/// (home_page.dart `_CollectionChip`); từ đây vào Chợ (icon cửa hàng) và BXH Sưu tập (🏆).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../core/accessories.dart';
import '../core/accessory_loadout.dart';
import '../core/accessory_refine.dart';
import '../core/balance.dart';
import '../core/collection_milestones.dart';
import '../core/collection_sets.dart';
import '../core/guild_shop.dart' show guildAccessories;
import '../core/vip_shop.dart' show vipAccessories;
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../leaderboard/flair.dart';
import '../state/game_controller.dart' show EquipResult;
import '../state/game_providers.dart';
import 'accessory_how_to_dialog.dart';
import 'email_gate.dart';
import 'accessory_leaderboard_page.dart';
import 'accessory_pack_dialog.dart';
import 'collection_share_dialog.dart';
import '../market/market_highlight.dart';
import 'accessory_market_page.dart';
import 'widgets/accessory_rarity.dart';
import 'widgets/clay.dart';
import 'widgets/motion.dart';
import 'widgets/anim_assets.dart';
import 'widgets/one_shot_lottie.dart';
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
              onPressed: () async {
                if (!await ensureOnlineLinked(context) || !context.mounted) return;
                showAccessoryMarket(context);
              },
            ),
            IconButton(
              icon: const Text('🏆', style: TextStyle(fontSize: 20)),
              tooltip: l10n.accessoryLbTitle,
              onPressed: () async {
                if (!await ensureOnlineLinked(context) || !context.mounted) return;
                showAccessoryLeaderboard(context);
              },
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
                      const SizedBox(height: 8),
                      const _LoadoutCard(),
                      const SizedBox(height: 8),
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
                      const _SetStrip(),
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
                    // 4 món/dịp → 2 cột (2x2 cân đối); 3 cột cho 3+1 với ô cuối lẻ loi.
                    gridDelegate: _limitedGridDelegate,
                    itemCount: f.items.length,
                    itemBuilder: (context, i) =>
                        _AccessoryCell(accessory: f.items[i], limited: true),
                  ),
                ),
              ],
              // Phụ kiện độc quyền VIP: đổi bằng Xu VIP ở Cửa hàng VIP (màn Mốc nạp & VIP).
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Text(
                    l10n.vipItemsTitle,
                    key: const Key('inventory-vip-section'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                sliver: SliverGrid.builder(
                  gridDelegate: _limitedGridDelegate,
                  itemCount: vipAccessories.length,
                  itemBuilder: (context, i) =>
                      _AccessoryCell(accessory: vipAccessories[i], limited: true),
                ),
              ),
              // Phụ kiện độc quyền của hội: đổi bằng Xu Hội ở Cửa hàng hội.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Text(
                    l10n.guildItemsTitle,
                    key: const Key('inventory-guild-section'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                sliver: SliverGrid.builder(
                  gridDelegate: _limitedGridDelegate,
                  itemCount: guildAccessories.length,
                  itemBuilder: (context, i) => _AccessoryCell(
                      accessory: guildAccessories[i], limited: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lưới cho nhóm 4 món độc quyền (mỗi dịp lễ, cửa hàng hội): 2 cột × 2 hàng.
const _limitedGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 10,
  crossAxisSpacing: 10,
  childAspectRatio: 1.5,
);

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
    final level = ref.watch(
      gameControllerProvider.select((s) => refineLevel(s.refineLevels, accessory.id)),
    );
    final color = rarityColor(accessory.rarity);

    void onTap() {
      if (!unlocked) return;
      if (equipped) {
        // Tháo = khoá đổi 30 phút → hỏi lại cho khỏi lỡ tay (xem accessory_loadout.dart).
        unawaited(_confirmRemove(context, ref, accessory));
        return;
      }
      final result = ref
          .read(gameControllerProvider.notifier)
          .tryToggleEquippedAccessory(accessory.id);
      if (result == EquipResult.equipped) {
        HapticFeedback.selectionClick();
      } else if (result == EquipResult.full) {
        // Đã đủ chỗ: báo thay vì im lặng.
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
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
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
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
              // Họ của món (🔥✨🌿💎) — cho biết món này cho buff gì khi mang.
              if (unlocked && accessoryFamilyOf(accessory.id) != null)
                Positioned(
                  top: 6,
                  left: 10,
                  child: Semantics(
                    label: _familyLabel(l10n, accessoryFamilyOf(accessory.id)!),
                    child: Text(
                      accessoryFamilyOf(accessory.id)!.emoji,
                      key: Key('accessory-family-${accessory.id}'),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              // Cấp tinh luyện ✦ + nút mở hộp Tinh luyện (món độc quyền không có bản dư nên không tinh luyện).
              if (unlocked && !limited)
                Positioned(
                  bottom: 2,
                  right: 6,
                  child: GestureDetector(
                    key: Key('refine-open-${accessory.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => showRefineSheet(context, accessory),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        level > 0 ? '✦$level' : '✦',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: level > 0 ? theme.colorScheme.primary : theme.disabledColor,
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
  late final CurvedAnimation _t = CurvedAnimation(
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
    _t.dispose();
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
      messenger..clearSnackBars()..showSnackBar(
        SnackBar(content: Text(l10n.collectionMilestoneDone(r.coins!))),
      );
    } else if (r.error == 'network') {
      messenger..clearSnackBars()..showSnackBar(
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

/// Mốc theo BỘ: 4 độ hiếm + 4 họ buff, mỗi bộ một chip tiến độ; đủ bộ thì bấm nhận Xu Chợ.
class _SetStrip extends ConsumerStatefulWidget {
  const _SetStrip();

  @override
  ConsumerState<_SetStrip> createState() => _SetStripState();
}

class _SetStripState extends ConsumerState<_SetStrip> {
  bool _busy = false;

  Future<void> _claim(CollectionSet set) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final r = await ref.read(gameControllerProvider.notifier).claimCollectionSet(set.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.coins != null) {
      HapticFeedback.mediumImpact();
      playEffect(context, AnimAssets.confetti);
      messenger..clearSnackBars()..showSnackBar(SnackBar(content: Text(l10n.collectionSetDone(r.coins!))));
    } else if (r.error == 'network') {
      messenger..clearSnackBars()..showSnackBar(SnackBar(content: Text(l10n.collectionMilestoneErrNet)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // select theo CHUỖI để so sánh theo giá trị.
    ref.watch(gameControllerProvider.select(
        (s) => '${s.ownedAccessories.length}|${s.collectionSetsClaimed.join(",")}'));
    final game = ref.read(gameControllerProvider);
    final owned = game.ownedAccessories.toSet();
    final claimedIds = game.collectionSetsClaimed.toSet();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.collectionSetsTitle,
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final set in collectionSets)
              _setChip(context, l10n, set, owned, claimedIds.contains(set.id)),
          ]),
        ],
      ),
    );
  }

  Widget _setChip(BuildContext context, AppLocalizations l10n, CollectionSet set,
      Set<String> owned, bool claimed) {
    final scheme = Theme.of(context).colorScheme;
    final members = set.members;
    final have = members.where(owned.contains).length;
    final claimable = !claimed && have == members.length;
    final name = set.rarity != null
        ? accessoryRarityLabel(l10n, set.rarity!)
        : set.family!.emoji;
    final sub = claimed ? '✓' : (claimable ? '+${set.coins} 🪙' : '$have/${members.length}');
    return InkWell(
      key: Key(claimable ? 'set-claim-${set.id}' : 'set-${set.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: claimable && !_busy ? () => _claim(set) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: claimable
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: claimable ? scheme.primary : Colors.transparent, width: 2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          Text(sub, style: Theme.of(context).textTheme.labelMedium),
        ]),
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

/// "5.0" → "5", "12.5" → "12.5": phần trăm gọn cho dòng buff.
String _pct(double fraction) {
  final v = fraction * 100;
  final t = v.toStringAsFixed(1);
  return t.endsWith('.0') ? t.substring(0, t.length - 2) : t;
}

/// 1.25 → "1.25", 1.5 → "1.5", 1.1 → "1.1": hệ số combo bỏ số 0 thừa.
String _mult(double m) => m.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

String _familyLabel(AppLocalizations l10n, AccessoryFamily f) => switch (f) {
      AccessoryFamily.tap => l10n.loadoutFamilyTap,
      AccessoryFamily.income => l10n.loadoutFamilyIncome,
      AccessoryFamily.offline => l10n.loadoutFamilyOffline,
      AccessoryFamily.discount => l10n.loadoutFamilyDiscount,
    };

String _buffLine(AppLocalizations l10n, AccessoryFamily f, LoadoutBuffs b) {
  final pct = _pct(b.of(f));
  final line = switch (f) {
    AccessoryFamily.tap => l10n.loadoutBuffTap(pct),
    AccessoryFamily.income => l10n.loadoutBuffIncome(pct),
    AccessoryFamily.offline => l10n.loadoutBuffOffline(pct),
    AccessoryFamily.discount => l10n.loadoutBuffDiscount(pct),
  };
  final combo = b.combo[f];
  return combo == null ? line : '$line${l10n.loadoutComboSuffix(_mult(combo))}';
}

/// Thẻ "Bộ trang bị": các ô đang mang, buff tổng hợp theo họ (kèm combo), và đếm ngược khoá đổi.
class _LoadoutCard extends ConsumerWidget {
  const _LoadoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final equipped = ref.watch(
      gameControllerProvider.select((s) => s.equippedAccessories.join(',')),
    ).split(',').where((e) => e.isNotEmpty).toList();
    final lockUntil = ref.watch(
      gameControllerProvider.select((s) => s.equipLockUntilMillis),
    );
    final slots = maxEquippedFor(
      vip: ref.watch(gameControllerProvider.select((s) => s.vipActive)),
    );
    final refine = refineFromSignature(ref.watch(
      gameControllerProvider.select((s) => refineSignature(s.refineLevels)),
    ));
    final buffs = loadoutBuffs(equipped, refine: refine);
    final active = [for (final f in AccessoryFamily.values) if (buffs.of(f) > 0) f];

    return ClayCard(
      key: const Key('loadout-card'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎒 ${l10n.loadoutTitle}',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < slots; i++)
                _LoadoutSlot(id: i < equipped.length ? equipped[i] : null, index: i),
            ],
          ),
          const SizedBox(height: 8),
          if (active.isEmpty)
            Text(l10n.loadoutEmpty, style: theme.textTheme.bodySmall)
          else
            for (final f in active)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  _buffLine(l10n, f, buffs),
                  key: Key('loadout-buff-${f.name}'),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
          const SizedBox(height: 4),
          Text(l10n.loadoutHint, style: theme.textTheme.bodySmall),
          if (lockUntil > 0) _LockCountdown(untilMillis: lockUntil),
        ],
      ),
    );
  }
}

class _LoadoutSlot extends StatelessWidget {
  const _LoadoutSlot({required this.id, required this.index});

  final String? id;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = id == null ? null : accessoryOrNull(id!);
    final family = id == null ? null : accessoryFamilyOf(id!);
    return Container(
      key: Key('loadout-slot-$index'),
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: a == null
              ? theme.colorScheme.outlineVariant
              : rarityColor(a.rarity),
          width: a == null ? 1.5 : 2.5,
        ),
        color: a == null
            ? null
            : rarityColor(a.rarity).withValues(alpha: 0.14),
      ),
      child: a == null
          ? Text('＋', style: TextStyle(fontSize: 20, color: theme.colorScheme.outline))
          : Stack(
              alignment: Alignment.center,
              children: [
                Text(a.emoji, style: const TextStyle(fontSize: 26)),
                if (family != null)
                  Positioned(
                    right: 2,
                    bottom: 0,
                    child: Text(family.emoji, style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
    );
  }
}

/// Dòng "🔒 còn N phút" — tự tắt khi hết khoá. Chỉ được dựng khi đang có mốc khoá, nên bộ đếm
/// (mỗi 15 giây, đủ cho đơn vị phút) chỉ tồn tại lúc cần và huỷ ở dispose.
class _LockCountdown extends ConsumerStatefulWidget {
  const _LockCountdown({required this.untilMillis});

  final int untilMillis;

  @override
  ConsumerState<_LockCountdown> createState() => _LockCountdownState();
}

class _LockCountdownState extends ConsumerState<_LockCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingMs = widget.untilMillis - ref.read(clockProvider)();
    if (remainingMs <= 0) return const SizedBox.shrink();
    final minutes = (remainingMs / 60000).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        AppLocalizations.of(context)!.loadoutLockNote(minutes),
        key: const Key('loadout-lock-note'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Chạm món đang mang: nếu đang khoá thì mời mở khoá (QC), không thì xác nhận tháo.
Future<void> _confirmRemove(BuildContext context, WidgetRef ref, Accessory accessory) async {
  final l10n = AppLocalizations.of(context)!;
  final ctrl = ref.read(gameControllerProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final lockUntil = ref.read(gameControllerProvider).equipLockUntilMillis;
  final remainingMs = lockUntil - ref.read(clockProvider)();

  if (remainingMs > 0) {
    final adFree = ref.read(gameControllerProvider).adFree;
    final minutes = (remainingMs / 60000).ceil();
    final unlock = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.loadoutLockedTitle),
        content: Text(l10n.loadoutLockedBody(minutes)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.close)),
          FilledButton(
            key: const Key('loadout-unlock-button'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(adFree ? l10n.loadoutUnlockFree : l10n.loadoutUnlockAd),
          ),
        ],
      ),
    );
    if (unlock != true) return;
    // Cùng khuôn mọi chỗ dùng rewarded: gỡ QC/VIP thì cộng thẳng.
    final outcome = adFree ? RewardOutcome.earned : await ref.read(adServiceProvider).showRewardedAd();
    if (outcome != RewardOutcome.earned) {
      messenger..clearSnackBars()..showSnackBar(SnackBar(content: Text(l10n.adNotReadySnack)));
      return;
    }
    ctrl.unlockEquipSwap();
    messenger..clearSnackBars()..showSnackBar(SnackBar(content: Text(l10n.loadoutUnlockedToast)));
    return;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.loadoutRemoveTitle(accessoryName(l10n, accessory.id))),
      content: Text(l10n.loadoutRemoveBody(Balance.equipSwapLockMinutes)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('loadout-remove-confirm'),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.loadoutRemoveConfirm),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final result = ctrl.tryToggleEquippedAccessory(accessory.id);
  if (result == EquipResult.removed) HapticFeedback.selectionClick();
}

/// Hộp "Tinh luyện" của một phụ kiện: cấp hiện tại, điểm trước/sau, giá (bản dư + 🧪) và nút nâng.
Future<void> showRefineSheet(BuildContext context, Accessory accessory) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RefineSheet(accessory: accessory),
    );

class _RefineSheet extends ConsumerWidget {
  const _RefineSheet({required this.accessory});
  final Accessory accessory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final id = accessory.id;
    final level = ref.watch(gameControllerProvider.select((s) => refineLevel(s.refineLevels, id)));
    final spares = ref.watch(gameControllerProvider.select((s) => s.accessorySpares[id] ?? 0));
    final essence = ref.watch(gameControllerProvider.select((s) => s.essence));
    final cost = refineNextCost(level);
    final base = accessoryPoints(accessory.rarity);
    String pts(double mult) => (base * mult).toStringAsFixed(base * mult % 1 == 0 ? 0 : 2);
    final nowMult = 1 + level * Balance.refinePerLevel;
    final nextMult = 1 + (level + 1) * Balance.refinePerLevel;
    final canRefine = cost != null && spares >= cost.spares && essence >= cost.essence;
    final family = accessoryFamilyOf(id);

    void onRefine() {
      final r = ref.read(gameControllerProvider.notifier).refineAccessory(id);
      final msg = switch (r) {
        RefineResult.ok => l10n.refineDone(refineLevel(ref.read(gameControllerProvider).refineLevels, id)),
        RefineResult.notEnoughSpares => l10n.refineErrSpares,
        RefineResult.notEnoughEssence => l10n.refineErrEssence,
        _ => null,
      };
      if (r == RefineResult.ok) {
        HapticFeedback.mediumImpact();
        playEffect(context, AnimAssets.sparkle, heavy: false);
      }
      if (msg != null) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text(msg)));
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(accessory.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${family?.emoji ?? ''} ${accessoryName(l10n, id)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            PulseOnIncrease(
              value: level,
              peak: 1.12,
              child: Text(
                '${'✦' * level}${'✧' * (Balance.refineMaxLevel - level)}  ${l10n.refineLevelLabel(level, Balance.refineMaxLevel)}',
                key: const Key('refine-level'),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.refinePoints(pts(nowMult), cost == null ? pts(nowMult) : pts(nextMult)),
              key: const Key('refine-points'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (cost == null)
              Text(l10n.refineMaxed, key: const Key('refine-maxed'), style: theme.textTheme.bodyMedium)
            else ...[
              Text(l10n.refineCostSpares(spares, cost.spares),
                  key: const Key('refine-cost-spares'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: spares >= cost.spares ? null : theme.colorScheme.error)),
              Text(l10n.refineCostEssence(essence, cost.essence),
                  key: const Key('refine-cost-essence'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: essence >= cost.essence ? null : theme.colorScheme.error)),
            ],
            const SizedBox(height: 10),
            Text(l10n.refineNote, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('refine-button'),
                onPressed: canRefine ? onRefine : null,
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.refineButton)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
