/// Bảng xếp hạng Trân Châu Rơi — xếp theo TỔNG SAO của Hành trình.
///
/// Cùng khuôn `story_speedrun_page.dart` (dùng chung tên người chơi, cùng kiểu
/// top tuyệt đối), chỉ khác con số đem đi xếp hạng.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/match3_levels.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/flair.dart';
import '../leaderboard/m3_leaderboard_controller.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showM3Leaderboard(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const M3LeaderboardPage()));
}

class M3LeaderboardPage extends ConsumerStatefulWidget {
  const M3LeaderboardPage({super.key});

  @override
  ConsumerState<M3LeaderboardPage> createState() => _M3LeaderboardPageState();
}

class _M3LeaderboardPageState extends ConsumerState<M3LeaderboardPage> {
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
    final notifier = ref.read(m3LeaderboardControllerProvider.notifier);

    // Tiến độ lấy từ GameState, không tự tính lại: tổng sao và số màn đã qua.
    notifier.getMyProgress = () {
      final stars = ref.read(gameControllerProvider).m3Stars;
      return (m3TotalStars(stars), m3LevelsCleared(stars));
    };

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final view = ref.watch(m3LeaderboardControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.m3LbTitle)),
        body: switch (view) {
          M3LeaderboardLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          M3LeaderboardNeedsNickname() => _NicknameForm(ctrl: _nameCtrl),
          M3LeaderboardLoaded() => _List(view: view),
          // Bỏ qua `message` của controller (tiếng Việt cứng, không dịch được vì
          // controller không có BuildContext) — hiện chuỗi đã dịch ở đây.
          M3LeaderboardError() => const _ErrorView(),
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
                    .read(m3LeaderboardControllerProvider.notifier)
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

class _List extends ConsumerWidget {
  const _List({required this.view});
  final M3LeaderboardLoaded view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (view.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.m3LbEmpty, textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      children: [
        if (view.myStars == 0)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l10n.m3LbNoStars, textAlign: TextAlign.center),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(m3LeaderboardControllerProvider.notifier)
                .refresh(silent: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: view.entries.length,
              itemBuilder: (context, i) {
                final e = view.entries[i];
                final isMe = e.userId == view.myUserId;
                return ClayTile(
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
                      // Tên có thể rất dài: phải co lại, không được đẩy cột số
                      // sao ra khỏi hàng (lớp lỗi tràn đã gặp nhiều lần).
                      Expanded(
                        child: Row(
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
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.m3LbStars(e.stars),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            l10n.m3LbLevels(e.levelsCleared),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
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
            Text(l10n.m3LbError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  ref.read(m3LeaderboardControllerProvider.notifier).refresh(),
              child: Text(l10n.leaderboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
