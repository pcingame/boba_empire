/// Bảng xếp hạng Sự kiện — top theo điểm sự kiện của dịp lễ đang diễn ra.
/// Cùng khuôn `m3_leaderboard_page.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessories.dart';
import '../core/event_quests.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/event_leaderboard_controller.dart';
import '../leaderboard/flair.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showEventLeaderboard(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const EventLeaderboardPage()));

class EventLeaderboardPage extends ConsumerStatefulWidget {
  const EventLeaderboardPage({super.key});

  @override
  ConsumerState<EventLeaderboardPage> createState() =>
      _EventLeaderboardPageState();
}

class _EventLeaderboardPageState extends ConsumerState<EventLeaderboardPage> {
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
    final notifier = ref.read(eventLeaderboardControllerProvider.notifier);
    final festival = activeFestival(DateTime.fromMillisecondsSinceEpoch(
        ref.read(clockProvider)(),
        isUtc: true));

    notifier.getMyProgress = () => (
          festival?.id ?? '',
          eventScoreOf(ref.read(gameControllerProvider).eventProgress),
        );
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final view = ref.watch(eventLeaderboardControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.eventLbTitle)),
        body: switch (view) {
          EventLeaderboardLoading() =>
            const Center(child: CircularProgressIndicator()),
          EventLeaderboardNeedsNickname() => _NicknameForm(ctrl: _nameCtrl),
          EventLeaderboardLoaded() => _List(view: view),
          EventLeaderboardError() => const _ErrorView(),
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
                    .read(eventLeaderboardControllerProvider.notifier)
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
  final EventLeaderboardLoaded view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (view.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.eventLbEmpty, textAlign: TextAlign.center),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            view.myScore == 0
                ? l10n.eventLbNoScore
                : l10n.eventLbMyScore(view.myScore),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(eventLeaderboardControllerProvider.notifier)
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
                      // Tên dài phải co lại, không đẩy cột điểm ra khỏi hàng.
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
                                        : FontWeight.normal),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.eventLbScore(e.score),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  ref.read(eventLeaderboardControllerProvider.notifier).refresh(),
              child: Text(l10n.leaderboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
