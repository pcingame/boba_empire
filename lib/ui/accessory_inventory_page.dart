/// "Kho phụ kiện" — sưu tập cosmetic thuần (không ảnh hưởng số liệu). Rớt từ
/// nhiệm vụ ngày (xem GameController.claimDailyBonus). Mở từ compete_hub_dialog.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessories.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'accessory_leaderboard_page.dart';
import 'accessory_market_page.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showAccessoryInventory(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AccessoryInventoryPage()),
  );
}

class AccessoryInventoryPage extends ConsumerWidget {
  const AccessoryInventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final owned =
        ref.watch(gameControllerProvider.select((s) => s.ownedAccessories.length));

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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accessoryInventoryOwned(owned, accessories.length),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: owned / accessories.length,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              // Tắt hiệu ứng kéo giãn của Android (StretchingOverscrollIndicator):
              // khi cuộn hết cỡ nó BÓP nội dung ở mép, lưới ô vuông thì méo rất
              // lộ — cùng bug + cách fix đã dùng ở match3_journey_page.dart.
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(overscroll: false),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Màu quy ước theo độ hiếm (xám/xanh/tím/vàng) — cố định, không lấy từ
/// theme, giống cách hầu hết game sưu tập dùng màu hiếm cố định xuyên suốt
/// light/dark mode để người chơi quét nhanh bằng mắt không cần đọc chữ.
Color _rarityColor(AccessoryRarity r) => switch (r) {
      AccessoryRarity.common => const Color(0xFF9E9E9E),
      AccessoryRarity.rare => const Color(0xFF42A5F5),
      AccessoryRarity.epic => const Color(0xFFAB47BC),
      AccessoryRarity.legendary => const Color(0xFFFFA726),
    };

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
    final unlocked = ref.watch(gameControllerProvider
        .select((s) => s.ownedAccessories.contains(accessory.id)));
    final rarityColor = _rarityColor(accessory.rarity);

    return Opacity(
      opacity: unlocked ? 1.0 : 0.45,
      child: Container(
        // Viền màu theo độ hiếm — trước đây 4 độ hiếm nhìn giống hệt nhau,
        // chỉ khác ở 1 dòng chữ nhỏ dưới cùng, không quét nhanh bằng mắt
        // được kiểu game sưu tập thường có.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: rarityColor, width: 2),
        ),
        child: ClayCard(
          padding: const EdgeInsets.all(8),
          color: Color.alphaBlend(
            rarityColor.withValues(alpha: unlocked ? 0.14 : 0.06),
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
                  unlocked ? accessoryName(l10n, accessory.id) : '???',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: rarityColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    accessoryRarityLabel(l10n, accessory.rarity),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
