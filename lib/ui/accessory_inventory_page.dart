/// "Kho phụ kiện" — sưu tập cosmetic thuần (không ảnh hưởng số liệu). Rớt từ
/// nhiệm vụ ngày (xem GameController.claimDailyBonus). Mở từ compete_hub_dialog.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessories.dart';
import '../core/balance.dart';
import '../core/collection_milestones.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../leaderboard/flair.dart';
import '../state/game_providers.dart';
import 'accessory_leaderboard_page.dart';
import 'accessory_market_page.dart';
import 'widgets/accessory_rarity.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

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

    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.accessoryInventoryTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.storefront),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accessoryInventoryOwned(owned, accessories.length),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.accessoryEquipHint(
                          equippedCount,
                          Balance.maxEquippedAccessories,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        l10n.accessoryFlairHint,
                        style: Theme.of(context).textTheme.bodySmall,
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
                      _AccessoryCell(accessory: accessories[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessoryCell extends ConsumerWidget {
  const _AccessoryCell({required this.accessory});
  final Accessory accessory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // select riêng cờ "đã có món này" (giống _AchievementRow ở
    // achievements_dialog.dart) — mỗi ô chỉ rebuild khi ĐÚNG món của nó đổi,
    // không phải toàn bộ lưới mỗi khi danh sách tăng thêm 1 món khác.
    final unlocked = ref.watch(
      gameControllerProvider.select(
        (s) => s.ownedAccessories.contains(accessory.id),
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
              l10n.accessoryEquipFull(Balance.maxEquippedAccessories),
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
      onLongPress: onLongPress,
      // StackFit.expand: Stack mặc định nới lỏng ràng buộc nên ô co lại theo
      // nội dung (hẹp, lệch trái) thay vì lấp đầy ô lưới.
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
          Wrap(
            spacing: 6,
            runSpacing: 0,
            children: [
              for (final m in collectionMilestones)
                if (claimed.contains(m.count))
                  Chip(
                    key: Key('milestone-${m.count}'),
                    visualDensity: VisualDensity.compact,
                    label: Text('✓ ${m.count}'),
                  )
                else if (owned >= m.count)
                  ActionChip(
                    key: Key('milestone-${m.count}'),
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      '${m.count} · ${l10n.collectionMilestoneClaim(m.coins)}',
                    ),
                    onPressed: _busy ? null : () => _claim(m),
                  )
                else
                  Chip(
                    key: Key('milestone-${m.count}'),
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      l10n.collectionMilestoneLocked(m.count, m.coins),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
