/// Bảng xếp hạng Sưu tập — xếp theo SỐ PHỤ KIỆN KHÁC NHAU đã có.
///
/// Cùng khuôn `m3_leaderboard_page.dart` (dùng chung tên người chơi, cùng
/// kiểu top tuyệt đối), chỉ khác con số đem đi xếp hạng.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../leaderboard/flair.dart';
import '../leaderboard/accessory_leaderboard_controller.dart';
import '../market/accessory_market_controller.dart';
import '../market/accessory_market_repository.dart';
import '../state/game_providers.dart';
import 'collection_peek_dialog.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showAccessoryLeaderboard(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AccessoryLeaderboardPage()));
}

class AccessoryLeaderboardPage extends ConsumerStatefulWidget {
  const AccessoryLeaderboardPage({super.key});

  @override
  ConsumerState<AccessoryLeaderboardPage> createState() =>
      _AccessoryLeaderboardPageState();
}

class _AccessoryLeaderboardPageState
    extends ConsumerState<AccessoryLeaderboardPage> {
  final _nameCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(accessoryLeaderboardControllerProvider.notifier);

    // Số phụ kiện khác nhau = đang có cục bộ + đang đăng bán trên Chợ (xem
    // AccessoryLeaderboardController.getMyOwnedCount) — lỗi mạng khi đọc
    // listing thì rơi về đếm cục bộ, không để lỗi Chợ chặn luôn bảng xếp
    // hạng.
    notifier.getMyOwnedCount = () async {
      final ownedIds = ref.read(gameControllerProvider).ownedAccessories;
      final local = ownedIds.length;
      // Chưa từng có phiên Supabase nào (chưa đụng Chợ/Đấu Trường/cloud save)
      // thì chắc chắn chưa có listing nào — khỏi ép đăng nhập ẩn danh chỉ để
      // hỏi một câu luôn có sẵn câu trả lời.
      if (Supabase.instance.client.auth.currentUser == null) return local;
      try {
        final myListings = await AccessoryMarketRepository(
          Supabase.instance.client,
        ).fetchMyActiveListings();
        // Hợp (không cộng): đang bán 1 bản dư của món vẫn còn trong kho thì
        // không phải món khác nhau thứ hai.
        return {...ownedIds, ...myListings.map((l) => l.accessoryId)}.length;
      } catch (_) {
        return local;
      }
    };

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final view = ref.watch(accessoryLeaderboardControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.accessoryLbTitle)),
        body: switch (view) {
          AccessoryLeaderboardLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          AccessoryLeaderboardNeedsNickname() => _NicknameForm(ctrl: _nameCtrl),
          AccessoryLeaderboardLoaded() => _List(view: view),
          // Bỏ qua `message` của controller (tiếng Việt cứng, không dịch được
          // vì controller không có BuildContext) — hiện chuỗi đã dịch ở đây.
          AccessoryLeaderboardError() => const _ErrorView(),
        },
      ),
    );
  }
}

class _NicknameForm extends ConsumerWidget {
  const _NicknameForm({required this.ctrl});
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.leaderboardNicknameIntro, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: l10n.leaderboardNicknameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            FilledButton(
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                ref
                    .read(accessoryLeaderboardControllerProvider.notifier)
                    .submitNickname(name);
              },
              child: Text(l10n.leaderboardSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

/// Huy hiệu top 20 Sưu tập — 🥇🥈🥉 cho hạng 1-3, 🏅 chung cho hạng 4-20,
/// null từ hạng 21 trở đi (không có danh hiệu). Suy thẳng từ `rank` RPC đã
/// trả về (`accessory_leaderboard_top`, row_number() có sẵn) — không cần
/// cột/bảng mới.
String? _topMedal(int rank) => switch (rank) {
  1 => '🥇',
  2 => '🥈',
  3 => '🥉',
  <= 20 => '🏅',
  _ => null,
};

/// Danh hiệu Top 20 Sưu tập theo 3 bậc — hạng 1 nổi bật riêng ("Vua Phụ
/// Kiện"), hạng 2-3 chung 1 danh hiệu, hạng 4-20 danh hiệu thấp hơn. Trước
/// đây cả 20 hạng dùng chung đúng 1 nhãn "Top 20 Sưu Tập", chỉ khác mỗi huy
/// hiệu — không đủ phân biệt cảm giác đứng đầu.
String? _topTitle(int rank, AppLocalizations l10n) => switch (rank) {
  1 => l10n.accessoryLbTitleKing,
  <= 3 => l10n.accessoryLbTitleMaster,
  <= 20 => l10n.accessoryLbTopTitle,
  _ => null,
};

class _List extends ConsumerWidget {
  const _List({required this.view});
  final AccessoryLeaderboardLoaded view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final merchantId = ref.watch(marketMerchantIdProvider).value;

    if (view.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.accessoryLbEmpty, textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      children: [
        if (view.myOwnedCount == 0)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l10n.accessoryLbNoOwned, textAlign: TextAlign.center),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(accessoryLeaderboardControllerProvider.notifier)
                .refresh(silent: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: view.entries.length,
              itemBuilder: (context, i) {
                final e = view.entries[i];
                final isMe = e.userId == view.myUserId;
                final medal = _topMedal(e.rank);
                final title = _topTitle(e.rank, l10n);
                final merchant = e.userId == merchantId
                    ? '🛒 ${l10n.marketMerchantTitle}'
                    : null;
                final badge = [
                  if (medal != null && title != null) '$medal $title',
                  ?merchant,
                ].join(' · ');
                return GestureDetector(
                  key: Key('lb-row-${e.userId}'),
                  onTap: () => showCollectionPeek(
                    context,
                    userId: e.userId,
                    nickname: e.nickname,
                  ),
                  child: ClayTile(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${e.rank}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isMe ? theme.colorScheme.primary : null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  FlairBadge(userId: e.userId),
                                  Flexible(
                                    child: Text(
                                      e.nickname,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isMe
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Danh hiệu top 20 — cùng màu vàng/cam đã dùng cho
                              // độ hiếm "huyền thoại" ở Kho phụ kiện, nhất quán
                              // trực quan trong cùng tính năng sưu tập.
                              if (badge.isNotEmpty)
                                Text(
                                  badge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    // Light: cam đậm (cam sáng chỉ 1.7:1 trên thẻ pastel);
                                    // dark giữ cam sáng.
                                    color: theme.brightness == Brightness.light
                                        ? const Color(0xFF9A5B00)
                                        : const Color(0xFFFFA726),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.accessoryLbCount(e.ownedCount),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.accessoryLbError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref
                  .read(accessoryLeaderboardControllerProvider.notifier)
                  .refresh(),
              child: Text(l10n.leaderboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
