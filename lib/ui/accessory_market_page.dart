/// Chợ Phụ kiện — xem PROPOSAL_ACCESSORY_MARKET.md. 2 tab: "Chợ" (duyệt + mua
/// đứt bán đoạn, không có mình trong danh sách) và "Của tôi" (ví Xu Chợ +
/// listing đang bán + đăng bán món đang sở hữu). Vào từ nút trên AppBar của
/// accessory_inventory_page.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessories.dart';
import '../core/balance.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../market/accessory_market_controller.dart';
import '../market/accessory_market_repository.dart';
import '../market/market_filter.dart';
import '../market/market_highlight.dart';
import '../state/game_providers.dart';
import 'widgets/accessory_rarity.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

/// Id có trong danh mục của bản app này. Listing/kho có thể chứa món do bản app
/// MỚI HƠN tạo ra — accessoryById ném StateError với id lạ, nên phải lọc trước.
bool _known(String id) => accessories.any((a) => a.id == id);

Future<void> showAccessoryMarket(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AccessoryMarketPage()));
}

class AccessoryMarketPage extends ConsumerStatefulWidget {
  const AccessoryMarketPage({super.key});

  @override
  ConsumerState<AccessoryMarketPage> createState() => _AccessoryMarketPageState();
}

class _AccessoryMarketPageState extends ConsumerState<AccessoryMarketPage> {
  bool _loaded = false;

  void _snack(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(accessoryMarketControllerProvider.notifier);

    notifier.getLocalOwnedAccessories = () =>
        ref.read(gameControllerProvider).ownedAccessories;
    notifier.getLocalSpares = () =>
        ref.read(gameControllerProvider).accessorySpares;
    notifier.onAccessoryRemovedLocally = (id) => ref
        .read(gameControllerProvider.notifier)
        .removeOwnedAccessoryLocally(id);
    notifier.onAccessoryAddedLocally = (id) =>
        ref.read(gameControllerProvider.notifier).addOwnedAccessoryLocally(id);

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Thoát trang trước khi frame đầu xong → ref đã dispose, dùng là crash.
        if (!mounted) return;
        // Mở Chợ = đã xem hết listing hiện có → tắt chấm đỏ/banner ở màn chính.
        ref
            .read(sharedPreferencesProvider)
            .setInt(marketSeenKey, DateTime.now().millisecondsSinceEpoch);
        ref.invalidate(marketHighlightProvider);
        notifier.refresh();
      });
    }

    final view = ref.watch(accessoryMarketControllerProvider);

    return PhoneWidth(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.marketTitle),
            bottom: TabBar(
              tabs: [
                Tab(text: l10n.marketTabBrowse),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.marketTabMine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (view is AccessoryMarketLoaded &&
                          view.myListings.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountDot(view.myListings.length),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: switch (view) {
            AccessoryMarketLoading() => const _SkeletonList(),
            AccessoryMarketError() => _ErrorView(
                onRetry: () => notifier.refresh(),
              ),
            AccessoryMarketLoaded() => TabBarView(
                children: [
                  _BrowseTab(view: view, onAction: _snack),
                  _MineTab(view: view, onAction: _snack),
                ],
              ),
          },
        ),
      ),
    );
  }
}

/// Chấm số nhỏ cạnh nhãn tab.
class _CountDot extends StatelessWidget {
  const _CountDot(this.count);
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Khung xương lúc tải lần đầu — giữ bố cục danh sách thay vì vòng quay trơ trọi.
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07);
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({required this.balance, this.onConvert});
  final int balance;
  final VoidCallback? onConvert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ClayChip(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.marketWallet(balance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onConvert != null) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onConvert,
                icon: const Icon(Icons.add, size: 18),
                tooltip: l10n.marketConvertButton,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ConvertSource { gems, money }

/// Dialog đổi 💎/💰 lấy Xu Chợ (MỘT CHIỀU — xem GameController.
/// convertGemsToMarketCoins/convertMoneyToMarketCoins). Tự thực hiện việc đổi
/// (không trả giá trị về như _askPrice) vì cần gọi RPC + refresh ví ngay bên
/// trong dialog để hiện trạng thái đang xử lý/kết quả.
class _ConvertCoinsDialog extends ConsumerStatefulWidget {
  const _ConvertCoinsDialog({required this.onAction});
  final void Function(String?) onAction;

  @override
  ConsumerState<_ConvertCoinsDialog> createState() =>
      _ConvertCoinsDialogState();
}

class _ConvertCoinsDialogState extends ConsumerState<_ConvertCoinsDialog> {
  _ConvertSource _source = _ConvertSource.gems;
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    final money = ref.watch(gameControllerProvider.select((s) => s.money));
    final income =
        ref.watch(gameControllerProvider.select((s) => s.incomePerSecond));

    final wanted = int.tryParse(_ctrl.text.trim());
    final validAmount = wanted != null && wanted >= 1 && wanted <= 100000;

    double? cost;
    var enough = false;
    if (validAmount) {
      if (_source == _ConvertSource.gems) {
        cost = wanted / Balance.marketCoinsPerGem;
        enough = gems >= cost;
      } else {
        cost = wanted * Balance.marketCoinsIncomeSeconds * income;
        enough = income.isFinite && income > 0 && money >= cost;
      }
      if (!cost.isFinite) {
        cost = null;
        enough = false;
      }
    }
    final canConfirm = validAmount && enough && !_busy;

    return AlertDialog(
      title: Text(l10n.marketConvertTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<_ConvertSource>(
            segments: const [
              ButtonSegment(value: _ConvertSource.gems, label: Text('💎')),
              ButtonSegment(value: _ConvertSource.money, label: Text('💰')),
            ],
            selected: {_source},
            onSelectionChanged: _busy
                ? null
                : (s) => setState(() => _source = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            enabled: !_busy,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.marketConvertAmountLabel,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('🪙', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
          if (validAmount && cost != null) ...[
            const SizedBox(height: 8),
            Text(
              _source == _ConvertSource.gems
                  ? l10n.marketConvertCostGems(formatNumber(cost, decimals: 2))
                  : l10n.marketConvertCostMoney(formatNumber(cost)),
              style: TextStyle(
                color: enough
                    ? null
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: canConfirm
              ? () async {
                  setState(() => _busy = true);
                  final notifier = ref.read(gameControllerProvider.notifier);
                  final ok = _source == _ConvertSource.gems
                      ? await notifier.convertGemsToMarketCoins(wanted)
                      : await notifier.convertMoneyToMarketCoins(wanted);
                  if (ok) {
                    await ref
                        .read(accessoryMarketControllerProvider.notifier)
                        .refresh(silent: true);
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  widget.onAction(ok
                      ? l10n.marketConvertSuccessToast
                      : l10n.marketConvertFailToast);
                }
              : null,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.marketConvertButton),
        ),
      ],
    );
  }
}

void _showConvertDialog(BuildContext context, void Function(String?) onAction) {
  showDialog<void>(
    context: context,
    builder: (_) => _ConvertCoinsDialog(onAction: onAction),
  );
}

/// Trạng thái rỗng dùng chung (chợ chưa ai bán / chưa đăng gì / chưa có gì
/// để bán) — icon mờ + chữ, nhất quán thay vì mỗi chỗ 1 kiểu Text trần.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.emoji, required this.message});
  final String emoji;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.35,
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏬', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(l10n.marketError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(l10n.leaderboardRetry)),
          ],
        ),
      ),
    );
  }
}

/// Dải "Vừa bán": món + giá khớp gần nhất, cho người mua biết giá thị trường.
class _RecentSalesStrip extends StatelessWidget {
  const _RecentSalesStrip({required this.sales});
  final List<RecentSale> sales;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final known = sales.where(
      (s) => accessories.any((a) => a.id == s.accessoryId),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 ${l10n.marketRecentSalesHeader}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in known) ...[
                  ClayChip(
                    color: rarityColor(accessoryById(s.accessoryId).rarity)
                        .withValues(alpha: 0.7),
                    child: Text(
                      '${accessoryById(s.accessoryId).emoji} ${s.price} 🪙',
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseTab extends ConsumerStatefulWidget {
  const _BrowseTab({required this.view, required this.onAction});
  final AccessoryMarketLoaded view;
  final void Function(String?) onAction;

  @override
  ConsumerState<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<_BrowseTab> {
  AccessoryRarity? _rarity;
  bool _missingOnly = false;
  MarketSort _sort = MarketSort.newest;

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final onAction = widget.onAction;
    final l10n = AppLocalizations.of(context)!;
    // select theo CHUỖI (so sánh theo giá trị) — snapshot tạo list mới mỗi
    // tick nên select thẳng list sẽ rebuild cả tab mỗi giây.
    final ownedKey = ref.watch(gameControllerProvider
        .select((s) => s.ownedAccessories.join(',')));
    final owned = ownedKey.isEmpty ? <String>{} : ownedKey.split(',').toSet();
    // Không hiện listing của chính mình ở tab Chợ — tự mua bị RPC chặn, xem
    // ở tab "Của tôi" để huỷ thay vì mua.
    final all = view.listings
        .where((l) => l.sellerId != view.myUserId && _known(l.accessoryId))
        .toList();
    final others = filterMarketListings(
      all,
      rarity: _rarity,
      missingOnly: _missingOnly,
      owned: owned,
      sort: _sort,
    );

    return Column(
      children: [
        _WalletChip(
          balance: view.walletBalance,
          onConvert: () => _showConvertDialog(context, onAction),
        ),
        if (view.recentSales.isNotEmpty)
          _RecentSalesStrip(sales: view.recentSales),
        if (all.isNotEmpty)
          _FilterBar(
            rarity: _rarity,
            missingOnly: _missingOnly,
            priceSort: _sort == MarketSort.priceAsc,
            onAll: () => setState(() {
              _rarity = null;
              _missingOnly = false;
            }),
            onMissing: (v) => setState(() => _missingOnly = v),
            onRarity: (r) => setState(() => _rarity = r),
            onPriceSort: (v) => setState(
                () => _sort = v ? MarketSort.priceAsc : MarketSort.newest),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(accessoryMarketControllerProvider.notifier)
                .refresh(silent: true),
            child: others.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _EmptyState(
                        emoji: all.isEmpty ? '🏬' : '🔍',
                        message: all.isEmpty
                            ? l10n.marketEmptyBrowse
                            : l10n.marketNoFilterResults,
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: others.length,
                    itemBuilder: (context, i) => _ListingTile(
                      listing: others[i],
                      isNew: !owned.contains(others[i].accessoryId),
                      trailing: FilledButton(
                        onPressed: () async {
                          final ok = await _confirmBuy(
                            context,
                            l10n,
                            others[i],
                            balance: view.walletBalance,
                            onTopUp: () => _showConvertDialog(context, onAction),
                          );
                          if (ok != true) return;
                          HapticFeedback.mediumImpact();
                          final msg = await ref
                              .read(accessoryMarketControllerProvider.notifier)
                              .buyItem(others[i]);
                          onAction(msg ?? l10n.marketBoughtToast);
                        },
                        child: Text(l10n.marketBuyButton),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Hàng chip lọc/sắp xếp cuộn ngang: Tất cả · Chưa có · 4 độ hiếm · Giá thấp.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.rarity,
    required this.missingOnly,
    required this.priceSort,
    required this.onAll,
    required this.onMissing,
    required this.onRarity,
    required this.onPriceSort,
  });
  final AccessoryRarity? rarity;
  final bool missingOnly;
  final bool priceSort;
  final VoidCallback onAll;
  final ValueChanged<bool> onMissing;
  final ValueChanged<AccessoryRarity?> onRarity;
  final ValueChanged<bool> onPriceSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget gap() => const SizedBox(width: 6);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          ChoiceChip(
            label: Text(l10n.marketFilterAll),
            selected: rarity == null && !missingOnly,
            onSelected: (_) => onAll(),
          ),
          gap(),
          ChoiceChip(
            label: Text('🆕 ${l10n.marketFilterMissing}'),
            selected: missingOnly,
            onSelected: onMissing,
          ),
          for (final r in AccessoryRarity.values) ...[
            gap(),
            ChoiceChip(
              label: Text(accessoryRarityLabel(l10n, r)),
              selected: rarity == r,
              selectedColor: rarityColor(r).withValues(alpha: 0.9),
              onSelected: (v) => onRarity(v ? r : null),
            ),
          ],
          gap(),
          ChoiceChip(
            label: Text('↑ ${l10n.marketSortPriceAsc}'),
            selected: priceSort,
            onSelected: onPriceSort,
          ),
        ],
      ),
    );
  }
}

/// [balance] < giá → hộp báo thiếu bao nhiêu và nút chính thành "Đổi" (mở dialog
/// nạp [onTopUp]) thay vì để người chơi bấm Mua rồi mới nhận lỗi.
Future<bool?> _confirmBuy(
  BuildContext context,
  AppLocalizations l10n,
  MarketListing listing, {
  required int balance,
  required VoidCallback onTopUp,
}) {
  final accessory = accessoryById(listing.accessoryId);
  final short = listing.price - balance;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(accessory.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Flexible(child: Text(accessoryName(l10n, listing.accessoryId))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RarityChip(
            rarity: accessory.rarity,
            label: accessoryRarityLabel(l10n, accessory.rarity),
          ),
          const SizedBox(height: 12),
          Text(l10n.marketConfirmBuy(listing.price)),
          if (short > 0) ...[
            const SizedBox(height: 8),
            Text(
              l10n.marketNeedMore(short),
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(short <= 0);
            if (short > 0) onTopUp();
          },
          child: Text(short > 0 ? l10n.marketConvertButton : l10n.marketBuyButton),
        ),
      ],
    ),
  );
}

class _ListingTile extends StatelessWidget {
  const _ListingTile(
      {required this.listing, required this.trailing, this.isNew = false});
  final MarketListing listing;
  final Widget trailing;

  /// Món người chơi CHƯA có trong bộ sưu tập — gắn nhãn "MỚI" để dễ nhận ra.
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accessory = accessoryById(listing.accessoryId);
    final color = rarityColor(accessory.rarity);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          ClayTile(
            margin: const EdgeInsets.symmetric(vertical: 4),
            // Chừa chỗ cho dải màu độ hiếm bên trái (xem Container dưới) —
            // cùng hệ màu đã dùng ở Kho phụ kiện, giúp quét nhanh bằng mắt
            // mà không cần đọc tên độ hiếm.
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              children: [
                Text(accessory.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              accessoryName(l10n, listing.accessoryId),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (isNew) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.marketBadgeNew,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onTertiary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🪙', style: theme.textTheme.bodySmall),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              l10n.marketPriceTag(listing.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                trailing,
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 4,
            bottom: 4,
            child: Container(width: 4, color: color),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.emoji, required this.text});
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _MineTab extends ConsumerWidget {
  const _MineTab({required this.view, required this.onAction});
  final AccessoryMarketLoaded view;
  final void Function(String?) onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final owned = ref
        .watch(gameControllerProvider.select((s) => s.ownedAccessories))
        .where(_known)
        .toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(accessoryMarketControllerProvider.notifier).refresh(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          _WalletChip(
            balance: view.walletBalance,
            onConvert: () => _showConvertDialog(context, onAction),
          ),
          if (view.myUserId != null &&
              ref.watch(marketMerchantIdProvider).value == view.myUserId)
            Center(
              child: ClayChip(child: Text('🛒 ${l10n.marketMerchantTitle}')),
            ),
          const SizedBox(height: 8),
          _SectionHeader(emoji: '📋', text: l10n.marketMyListingsHeader),
          if (view.myListings.isEmpty)
            _EmptyState(emoji: '📋', message: l10n.marketEmptyMine)
          else
            for (final listing in view.myListings.where((l) => _known(l.accessoryId)))
              _ListingTile(
                listing: listing,
                trailing: OutlinedButton(
                  onPressed: () async {
                    final msg = await ref
                        .read(accessoryMarketControllerProvider.notifier)
                        .cancelItem(listing);
                    onAction(msg ?? l10n.marketCancelledToast);
                  },
                  child: Text(l10n.marketCancelButton),
                ),
              ),
          const SizedBox(height: 20),
          _SectionHeader(emoji: '🎒', text: l10n.marketSellableHeader),
          if (owned.isEmpty)
            _EmptyState(emoji: '🎒', message: l10n.marketEmptySellable)
          else
            for (final id in owned)
              _SellableTile(accessoryId: id, onAction: onAction),
        ],
      ),
    );
  }
}

class _SellableTile extends ConsumerWidget {
  const _SellableTile({required this.accessoryId, required this.onAction});
  final String accessoryId;
  final void Function(String?) onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accessory = accessoryById(accessoryId);
    final color = rarityColor(accessory.rarity);
    final spares = ref.watch(
      gameControllerProvider.select((s) => s.accessorySpares[accessoryId] ?? 0),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          ClayTile(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              children: [
                Text(accessory.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${accessoryName(l10n, accessoryId)}'
                    '${spares > 0 ? ' ×${spares + 1}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final price = await _askPrice(context, l10n, accessory);
                    if (price == null) return;
                    final msg = await ref
                        .read(accessoryMarketControllerProvider.notifier)
                        .listItem(accessoryId, price);
                    onAction(msg ?? l10n.marketListedToast);
                  },
                  child: Text(l10n.marketListButton),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 4,
            bottom: 4,
            child: Container(width: 4, color: color),
          ),
        ],
      ),
    );
  }
}

Future<int?> _askPrice(
    BuildContext context, AppLocalizations l10n, Accessory accessory) {
  final ctrl = TextEditingController();
  return showDialog<int>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        final price = int.tryParse(ctrl.text.trim());
        final valid = price != null && price >= 1 && price <= 100000;
        // Phí sàn 1%, làm tròn lên, tối thiểu 1 — khớp buy_listing() trong
        // accessory_market_schema.sql.
        final fee = valid ? (price * 0.01).ceil().clamp(1, price) : 0;
        return AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(accessory.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(l10n.marketListButton),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.marketPriceLabel,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('🪙', style: TextStyle(fontSize: 18)),
                  ),
                  errorText:
                      ctrl.text.isNotEmpty && !valid ? '1 – 100,000' : null,
                ),
              ),
              if (valid) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.marketListFeeNote(price - fee, fee),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: valid ? () => Navigator.of(context).pop(price) : null,
              child: Text(l10n.marketListButton),
            ),
          ],
        );
      },
    ),
  );
}
