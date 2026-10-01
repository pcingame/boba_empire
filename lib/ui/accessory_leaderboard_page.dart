/// Bảng xếp hạng Sưu tập — xếp theo SỐ PHỤ KIỆN KHÁC NHAU đã có.
///
/// Cùng khuôn `m3_leaderboard_page.dart` (dùng chung tên người chơi, cùng
/// kiểu top tuyệt đối), chỉ khác con số đem đi xếp hạng.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../leaderboard/accessory_leaderboard_controller.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showAccessoryLeaderboard(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AccessoryLeaderboardPage()),
  );
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

    // Tiến độ lấy từ GameState, không tự tính lại: số phụ kiện khác nhau.
    notifier.getMyOwnedCount =
        () => ref.read(gameControllerProvider).ownedAccessories.length;

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final view = ref.watch(accessoryLeaderboardControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.accessoryLbTitle)),
        body: switch (view) {
          AccessoryLeaderboardLoading() =>
            const Center(child: CircularProgressIndicator()),
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

class _List extends ConsumerWidget {
  const _List({required this.view});
  final AccessoryLeaderboardLoaded view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
                      Expanded(
                        child: Text(
                          e.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isMe ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.accessoryLbCount(e.ownedCount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
