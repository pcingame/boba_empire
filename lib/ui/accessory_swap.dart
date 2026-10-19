/// Trao đổi vật phẩm ở Chợ (tab "Trao đổi" + mục "Đề nghị của tôi" + hộp tạo đề nghị). Cơ chế ở server:
/// supabase/accessory_swap_schema.sql — người đăng ký quỹ món X muốn món Y; người nhận đang có Y thì đổi.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessories.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../market/accessory_market_controller.dart';
import '../market/accessory_market_repository.dart';
import '../state/game_providers.dart';
import 'widgets/accessory_rarity.dart';
import 'widgets/clay.dart';
import 'widgets/app_dialog.dart';

/// Số đề nghị mở tối đa mỗi người (khớp `swap_max_open()` trong SQL; test so khớp).
const int swapMaxOpen = 5;

bool _known(String id) => accessories.any((a) => a.id == id);

String swapErrorText(AppLocalizations l10n, SwapError e) => switch (e) {
      SwapError.notOwned => l10n.swapErrNotOwned,
      SwapError.notOwnedWant => l10n.swapErrNotOwnedWant,
      SwapError.tooMany => l10n.swapErrTooMany(swapMaxOpen),
      SwapError.notOpen => l10n.swapErrNotOpen,
      SwapError.ownSwap => l10n.swapErrOwn,
      SwapError.invalid => l10n.swapErrInvalid,
      SwapError.network => l10n.swapErrNetwork,
    };

/// Tab "Trao đổi": đề nghị của người khác; nút Đổi chỉ bật khi mình đang có món họ cần.
class SwapTab extends ConsumerWidget {
  const SwapTab({super.key, required this.view, required this.onAction});
  final AccessoryMarketLoaded view;
  final void Function(String?) onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ownedKey = ref.watch(gameControllerProvider.select((s) => s.ownedAccessories.join(',')));
    final owned = ownedKey.isEmpty ? <String>{} : ownedKey.split(',').toSet();
    final others = [
      for (final s in view.swaps)
        if (s.sellerId != view.myUserId && _known(s.giveId) && _known(s.wantId)) s,
    ];
    return RefreshIndicator(
      onRefresh: () => ref.read(accessoryMarketControllerProvider.notifier).refresh(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        children: [
          Text(l10n.swapIntro(marketDaysForSwap), key: const Key('swap-intro'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('swap-create'),
            onPressed: () => showCreateSwapDialog(context, ref, onAction),
            icon: const Icon(Icons.add),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.swapCreate)),
          ),
          const SizedBox(height: 8),
          if (others.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  const Opacity(opacity: 0.35, child: Text('🔁', style: TextStyle(fontSize: 40))),
                  const SizedBox(height: 8),
                  Text(l10n.swapEmpty, key: const Key('swap-empty'), textAlign: TextAlign.center),
                ],
              ),
            )
          else
            for (final s in others)
              SwapTile(
                key: Key('swap-${s.id}'),
                swap: s,
                trailing: Flexible(
                  child: FilledButton(
                    key: Key('swap-accept-${s.id}'),
                    onPressed: owned.contains(s.wantId) ? () => _accept(context, ref, s) : null,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(owned.contains(s.wantId) ? l10n.swapAccept : l10n.swapNeedItem),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref, AccessorySwap s) async {
    final l10n = AppLocalizations.of(context)!;
    final market = ref.read(accessoryMarketControllerProvider.notifier);
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('swap-confirm'),
        title: Text(l10n.swapConfirmTitle),
        content: Text(l10n.swapConfirmBody(
            accessoryName(l10n, s.giveId), accessoryName(l10n, s.wantId))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            key: const Key('swap-confirm-ok'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.swapAccept),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await market.acceptSwap(s);
    onAction(err == null ? l10n.swapDoneToast(accessoryName(l10n, s.giveId)) : swapErrorText(l10n, err));
  }
}

/// Số ngày sống của đề nghị (cùng thời hạn tin đăng) — để chuỗi giải thích không lệch với server.
const int marketDaysForSwap = marketListingDays;

/// Một hàng đề nghị: "Đưa 🧁 A" / "Cần 🍪 B" + [trailing] (nút Đổi hoặc Huỷ).
class SwapTile extends StatelessWidget {
  const SwapTile({super.key, required this.swap, required this.trailing, this.showExpiry = false});
  final AccessorySwap swap;
  final Widget trailing;
  final bool showExpiry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    Widget line(String label, String id) {
      final a = accessoryById(id);
      return Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
          ),
          Text(a.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              accessoryName(l10n, id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return ClayTile(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                line(l10n.swapGive, swap.giveId),
                const SizedBox(height: 2),
                line(l10n.swapWant, swap.wantId),
                if (showExpiry)
                  Text(
                    l10n.marketExpiresIn(formatDuration(swap.remaining(DateTime.now()).inSeconds)),
                    key: Key('swap-expiry-${swap.id}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

/// Mục "Đề nghị trao đổi của tôi" trong tab "Của tôi": còn hạn bao lâu + nút huỷ.
class MySwapsSection extends ConsumerWidget {
  const MySwapsSection({super.key, required this.view, required this.onAction});
  final AccessoryMarketLoaded view;
  final void Function(String?) onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mine = [for (final s in view.mySwaps) if (_known(s.giveId) && _known(s.wantId)) s];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              const Text('🔁', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l10n.swapMine,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        if (mine.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(l10n.swapMineEmpty, key: const Key('swap-mine-empty'), style: Theme.of(context).textTheme.bodySmall),
          )
        else
          for (final s in mine)
            SwapTile(
              key: Key('swap-mine-${s.id}'),
              swap: s,
              showExpiry: true,
              trailing: Flexible(
                child: OutlinedButton(
                  key: Key('swap-cancel-${s.id}'),
                  onPressed: () async {
                    final market = ref.read(accessoryMarketControllerProvider.notifier);
                    final err = await market.cancelSwap(s);
                    onAction(err == null ? l10n.swapCancelledToast : swapErrorText(l10n, err));
                  },
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.swapCancel)),
                ),
              ),
            ),
      ],
    );
  }
}

/// Hộp "Tạo đề nghị": chọn món đưa (trong kho) và món muốn (cả danh mục), rồi đăng.
Future<void> showCreateSwapDialog(
    BuildContext context, WidgetRef ref, void Function(String?) onAction) async {
  final l10n = AppLocalizations.of(context)!;
  // Chụp trước khi chờ hộp thoại (xem ghi chú ở _SellableTile: ref có thể dispose trong lúc chờ).
  final market = ref.read(accessoryMarketControllerProvider.notifier);
  final owned = [for (final id in ref.read(gameControllerProvider).ownedAccessories) if (_known(id)) id];
  final picked = await showAppDialog<(String, String)>(
    context: context,
    builder: (_) => _CreateSwapDialog(owned: owned),
  );
  if (picked == null) return;
  final err = await market.createSwap(picked.$1, picked.$2);
  onAction(err == null ? l10n.swapCreatedToast : swapErrorText(l10n, err));
}

class _CreateSwapDialog extends StatefulWidget {
  const _CreateSwapDialog({required this.owned});
  final List<String> owned;

  @override
  State<_CreateSwapDialog> createState() => _CreateSwapDialogState();
}

class _CreateSwapDialogState extends State<_CreateSwapDialog> {
  String? _give;
  String? _want;

  Future<void> _pick({required bool give}) async {
    final l10n = AppLocalizations.of(context)!;
    final candidates = give
        ? [for (final a in accessories) if (widget.owned.contains(a.id)) a]
        : [for (final a in accessories) if (a.id != _give) a];
    final id = await showAppDialog<String>(
      context: context,
      builder: (_) => _PickDialog(
        title: give ? l10n.swapPickGive : l10n.swapPickWant,
        candidates: candidates,
      ),
    );
    if (id == null || !mounted) return;
    setState(() {
      if (give) {
        _give = id;
        if (_want == id) _want = null;
      } else {
        _want = id;
      }
    });
  }

  Widget _slot(AppLocalizations l10n, String label, String? id, bool give) {
    return OutlinedButton(
      key: Key(give ? 'swap-pick-give' : 'swap-pick-want'),
      onPressed: () => _pick(give: give),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              id == null ? '…' : '${accessoryById(id).emoji} ${accessoryName(l10n, id)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.swapCreate),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.owned.isEmpty)
            Text(l10n.marketEmptySellable, key: const Key('swap-no-items'))
          else ...[
            _slot(l10n, l10n.swapGive, _give, true),
            const SizedBox(height: 8),
            _slot(l10n, l10n.swapWant, _want, false),
            const SizedBox(height: 8),
            Text(l10n.swapMaxNote(swapMaxOpen), style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('swap-create-ok'),
          onPressed: (_give != null && _want != null) ? () => Navigator.pop(context, (_give!, _want!)) : null,
          child: Text(l10n.swapCreateOk),
        ),
      ],
    );
  }
}

/// Hộp chọn món có ô tìm theo tên (danh mục hơn 160 món).
class _PickDialog extends StatefulWidget {
  const _PickDialog({required this.title, required this.candidates});
  final String title;
  final List<Accessory> candidates;

  @override
  State<_PickDialog> createState() => _PickDialogState();
}

class _PickDialogState extends State<_PickDialog> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final q = _search.text.trim().toLowerCase();
    final list = [
      for (final a in widget.candidates)
        if (q.isEmpty || accessoryName(l10n, a.id).toLowerCase().contains(q)) a,
    ];
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: Column(
          children: [
            TextField(
              key: const Key('swap-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.swapPickSearch,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text(l10n.swapPickNone))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final a = list[i];
                        return ListTile(
                          key: Key('swap-item-${a.id}'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Text(a.emoji, style: const TextStyle(fontSize: 22)),
                          title: Text(accessoryName(l10n, a.id), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Icon(Icons.circle, size: 10, color: rarityColor(a.rarity)),
                          onTap: () => Navigator.pop(context, a.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel))],
    );
  }
}
