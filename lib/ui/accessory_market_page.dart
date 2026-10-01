/// Chợ Phụ kiện — xem PROPOSAL_ACCESSORY_MARKET.md. 2 tab: "Chợ" (duyệt + mua
/// đứt bán đoạn, không có mình trong danh sách) và "Của tôi" (ví Xu Chợ +
/// listing đang bán + đăng bán món đang sở hữu). Vào từ nút trên AppBar của
/// accessory_inventory_page.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessories.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../market/accessory_market_controller.dart';
import '../market/accessory_market_repository.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showAccessoryMarket(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AccessoryMarketPage()),
  );
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(accessoryMarketControllerProvider.notifier);

    notifier.getLocalOwnedAccessories =
        () => ref.read(gameControllerProvider).ownedAccessories;
    notifier.onAccessoryRemovedLocally = (id) =>
        ref.read(gameControllerProvider.notifier).removeOwnedAccessoryLocally(id);
    notifier.onAccessoryAddedLocally = (id) =>
        ref.read(gameControllerProvider.notifier).addOwnedAccessoryLocally(id);

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final view = ref.watch(accessoryMarketControllerProvider);

    return PhoneWidth(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.marketTitle),
            bottom: TabBar(
              tabs: [Tab(text: l10n.marketTabBrowse), Tab(text: l10n.marketTabMine)],
            ),
          ),
          body: switch (view) {
            AccessoryMarketLoading() =>
              const Center(child: CircularProgressIndicator()),
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

class _WalletChip extends StatelessWidget {
  const _WalletChip({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClayChip(child: Text(l10n.marketWallet(balance))),
    );
  }
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
            Text(l10n.marketError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(l10n.leaderboardRetry)),
          ],
        ),
      ),
    );
  }
}

class _BrowseTab extends ConsumerWidget {
  const _BrowseTab({required this.view, required this.onAction});
  final AccessoryMarketLoaded view;
  final void Function(String?) onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Không hiện listing của chính mình ở tab Chợ — tự mua bị RPC chặn, xem
    // ở tab "Của tôi" để huỷ thay vì mua.
    final others =
        view.listings.where((l) => l.sellerId != view.myUserId).toList();

    return Column(
      children: [
        _WalletChip(balance: view.walletBalance),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(accessoryMarketControllerProvider.notifier)
                .refresh(silent: true),
            child: others.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 200,
                        child: Center(child: Text(l10n.marketEmptyBrowse)),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: others.length,
                    itemBuilder: (context, i) => _ListingTile(
                      listing: others[i],
                      trailing: FilledButton(
                        onPressed: () async {
                          final ok = await _confirmBuy(context, l10n, others[i]);
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

Future<bool?> _confirmBuy(
    BuildContext context, AppLocalizations l10n, MarketListing listing) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(accessoryName(l10n, listing.accessoryId)),
      content: Text(l10n.marketConfirmBuy(listing.price)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.marketBuyButton),
        ),
      ],
    ),
  );
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing, required this.trailing});
  final MarketListing listing;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accessory = accessoryById(listing.accessoryId);
    return ClayTile(
      child: Row(
        children: [
          Text(accessory.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  accessoryName(l10n, listing.accessoryId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n.marketPriceTag(listing.price),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _MineTab extends ConsumerWidget {
  const _MineTab({required this.view, required this.onAction});
  final AccessoryMarketLoaded view;
  final void Function(String?) onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final owned =
        ref.watch(gameControllerProvider.select((s) => s.ownedAccessories));

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(accessoryMarketControllerProvider.notifier).refresh(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          _WalletChip(balance: view.walletBalance),
          Text(l10n.marketMyListingsHeader,
              style: Theme.of(context).textTheme.titleSmall),
          if (view.myListings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.marketEmptyMine, textAlign: TextAlign.center),
            )
          else
            for (final listing in view.myListings)
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
          const SizedBox(height: 16),
          Text(l10n.marketSellableHeader,
              style: Theme.of(context).textTheme.titleSmall),
          if (owned.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.marketEmptySellable, textAlign: TextAlign.center),
            )
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
    final accessory = accessoryById(accessoryId);
    return ClayTile(
      child: Row(
        children: [
          Text(accessory.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              accessoryName(l10n, accessoryId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final price = await _askPrice(context, l10n);
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
    );
  }
}

Future<int?> _askPrice(BuildContext context, AppLocalizations l10n) {
  final ctrl = TextEditingController();
  return showDialog<int>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(l10n.marketListButton),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.marketPriceLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            final price = int.tryParse(ctrl.text.trim());
            if (price == null || price < 1 || price > 100000) return;
            Navigator.of(context).pop(price);
          },
          child: Text(l10n.marketListButton),
        ),
      ],
    ),
  );
}
