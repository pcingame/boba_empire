/// Màn hình "Bảng xếp hạng" — xem PROPOSAL_LEADERBOARD.md. Mở từ dialog
/// Nhượng quyền (đúng chỗ liên quan tới prestigeStars/lifetimeEarnings).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/leaderboard_controller.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';

Future<void> showLeaderboardPage(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LeaderboardPage()),
  );
}

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
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
    final notifier = ref.read(leaderboardControllerProvider.notifier);
    notifier.getLocalStats = () {
      final snap = ref.read(gameControllerProvider);
      return LocalStats(
        lifetimeEarnings: snap.lifetimeEarnings,
        prestigeStars: snap.prestigeStars,
        stage: snap.stage,
      );
    };
    // Tải lần đầu khi mở màn — sau frame đầu để tránh gọi setState lúc build.
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final viewState = ref.watch(leaderboardControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.leaderboardTitle)),
      body: SafeArea(
        child: switch (viewState) {
          LeaderboardLoading() => const Center(child: CircularProgressIndicator()),
          LeaderboardNeedsNickname() => _NicknameForm(l10n: l10n, nameCtrl: _nameCtrl),
          LeaderboardLoaded() => _LeaderboardList(l10n: l10n, view: viewState),
          LeaderboardError(:final message) => _ErrorView(message: message),
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
                  ref.read(leaderboardControllerProvider.notifier).submitNickname(name);
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

class _LeaderboardList extends ConsumerWidget {
  const _LeaderboardList({required this.l10n, required this.view});
  final AppLocalizations l10n;
  final LeaderboardLoaded view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (view.myRank != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Chip(label: Text(l10n.leaderboardYourRank(view.myRank!))),
          ),
        TextButton(
          onPressed: () => ref.read(leaderboardControllerProvider.notifier).changeName(),
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
                                style: theme.textTheme.titleMedium),
                          ),
                          Expanded(
                            child: Text(entry.nickname,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Text(l10n.leaderboardStars(entry.prestigeStars)),
                          const SizedBox(width: 8),
                          Text(formatNumber(entry.lifetimeEarnings)),
                        ],
                      ),
                    );
                    // Viền nổi bật hàng của chính mình — ClayTile không có
                    // tham số màu riêng, bọc thêm 1 lớp viền là đủ, không cần
                    // sửa widget dùng chung ở nhiều nơi khác.
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
              onPressed: () => ref.read(leaderboardControllerProvider.notifier).refresh(),
              child: Text(l10n.leaderboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
