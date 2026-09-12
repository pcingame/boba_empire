/// Màn hình "Bảng xếp hạng PK" — xếp hạng thắng/thua Đấu Trường gộp trên
/// toàn bộ người chơi. Mở từ compete_hub_dialog.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../arena/arena_leaderboard_controller.dart';
import '../l10n/app_localizations.dart';
import 'widgets/clay.dart';

Future<void> showArenaLeaderboardPage(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ArenaLeaderboardPage()),
  );
}

class ArenaLeaderboardPage extends ConsumerStatefulWidget {
  const ArenaLeaderboardPage({super.key});

  @override
  ConsumerState<ArenaLeaderboardPage> createState() => _ArenaLeaderboardPageState();
}

class _ArenaLeaderboardPageState extends ConsumerState<ArenaLeaderboardPage> {
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
    final notifier = ref.read(arenaLeaderboardControllerProvider.notifier);
    // Tải lần đầu khi mở màn — sau frame đầu để tránh gọi setState lúc build.
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final viewState = ref.watch(arenaLeaderboardControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.arenaLeaderboardTitle)),
      body: SafeArea(
        child: switch (viewState) {
          ArenaLeaderboardLoading() => const Center(child: CircularProgressIndicator()),
          ArenaLeaderboardNeedsNickname() => _NicknameForm(l10n: l10n, nameCtrl: _nameCtrl),
          ArenaLeaderboardLoaded() => _ArenaLeaderboardList(l10n: l10n, view: viewState),
          ArenaLeaderboardError(:final message) => _ErrorView(message: message),
        },
      ),
    );
  }
}

class _NicknameForm extends ConsumerWidget {
  const _NicknameForm({required this.l10n, required this.nameCtrl});
  final AppLocalizations l10n;
  final TextEditingController nameCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              controller: nameCtrl,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: l10n.leaderboardNicknameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  ref.read(arenaLeaderboardControllerProvider.notifier).submitNickname(name);
                }
              },
              child: Text(l10n.leaderboardSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArenaLeaderboardList extends ConsumerWidget {
  const _ArenaLeaderboardList({required this.l10n, required this.view});
  final AppLocalizations l10n;
  final ArenaLeaderboardLoaded view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (view.myRank != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Chip(label: Text(l10n.leaderboardYourRank(view.myRank!))),
          )
        else if (view.entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.arenaLeaderboardNotPlayedYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        TextButton(
          onPressed: () => ref.read(arenaLeaderboardControllerProvider.notifier).changeName(),
          child: Text(l10n.leaderboardChangeName),
        ),
        Expanded(
          child: view.entries.isEmpty
              ? Center(child: Text(l10n.leaderboardEmpty))
              : ListView.builder(
                  itemCount: view.entries.length,
                  itemBuilder: (context, i) {
                    final entry = view.entries[i];
                    final isMe = entry.userId == view.myUserId;
                    final tile = ClayTile(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text('#${entry.rank}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium),
                          ),
                          Expanded(
                            child: Text(entry.nickname,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          // Flexible + ellipsis: cùng lớp bug RenderFlex overflow
                          // đã gặp ở _ShopTile (xem shop-tile-overflow-pattern
                          // memory) — số trận của 1 hàng khác luôn có thể dài hơn.
                          Flexible(
                            child: Text(
                              l10n.arenaLeaderboardRecord(entry.wins, entry.losses),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                    // Viền nổi bật hàng của chính mình — giống leaderboard_page.dart.
                    if (!isMe) return tile;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.primary, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: tile,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.read(arenaLeaderboardControllerProvider.notifier).refresh(),
              child: Text(l10n.leaderboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
