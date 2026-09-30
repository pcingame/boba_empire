/// Màn hình "Bảng xếp hạng tốc độ hoàn thành cốt truyện" — mở từ
/// compete_hub_dialog.dart. Xem story_speedrun_controller.dart cho luồng
/// nộp mốc + tải danh sách.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/story_speedrun_controller.dart';
import '../leaderboard/story_speedrun_repository.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';

Future<void> showStorySpeedrunPage(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const StorySpeedrunPage()));
}

typedef _SpeedrunProvider
    = NotifierProvider<StorySpeedrunController, StorySpeedrunViewState>;

_SpeedrunProvider _providerFor(SpeedrunBoard board) => switch (board) {
      SpeedrunBoard.main => storySpeedrunControllerProvider,
      SpeedrunBoard.ext => storySpeedrunExtControllerProvider,
      SpeedrunBoard.third => storySpeedrunThirdControllerProvider,
    };

/// 3 tab: "Hồi 1" (tới Chương 18), "Hồi 2" (tới Chương 28) và "Hồi 3" (tới
/// Chương 34) — mỗi tab có bảng, controller và mốc thời gian riêng.
class StorySpeedrunPage extends StatelessWidget {
  const StorySpeedrunPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.storySpeedrunTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.storySpeedrunTabMain),
              Tab(text: l10n.storySpeedrunTabExt),
              Tab(text: l10n.storySpeedrunTabExt2),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              _SpeedrunTab(board: SpeedrunBoard.main),
              _SpeedrunTab(board: SpeedrunBoard.ext),
              _SpeedrunTab(board: SpeedrunBoard.third),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedrunTab extends ConsumerStatefulWidget {
  const _SpeedrunTab({required this.board});
  final SpeedrunBoard board;

  @override
  ConsumerState<_SpeedrunTab> createState() => _SpeedrunTabState();
}

class _SpeedrunTabState extends ConsumerState<_SpeedrunTab>
    with AutomaticKeepAliveClientMixin {
  final _nameCtrl = TextEditingController();
  bool _loaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = _providerFor(widget.board);
    final notifier = ref.read(provider.notifier);
    notifier.getMyCompleteSeconds = () {
      final game = ref.read(gameControllerProvider);
      return switch (widget.board) {
        SpeedrunBoard.main => game.storyCompleteSeconds,
        SpeedrunBoard.ext => game.storyExtCompleteSeconds,
        SpeedrunBoard.third => game.storyThirdActCompleteSeconds,
      };
    };

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final viewState = ref.watch(provider);
    return switch (viewState) {
      StorySpeedrunLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      StorySpeedrunNeedsNickname() => _NicknameForm(
        l10n: l10n,
        nameCtrl: _nameCtrl,
        provider: provider,
      ),
      StorySpeedrunLoaded() => _SpeedrunList(
        l10n: l10n,
        view: viewState,
        provider: provider,
        board: widget.board,
      ),
      StorySpeedrunError(:final message) => _ErrorView(
        message: message,
        provider: provider,
      ),
    };
  }
}

class _NicknameForm extends ConsumerWidget {
  const _NicknameForm({
    required this.l10n,
    required this.nameCtrl,
    required this.provider,
  });
  final AppLocalizations l10n;
  final TextEditingController nameCtrl;
  final _SpeedrunProvider provider;

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
                  ref.read(provider.notifier).submitNickname(name);
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

class _SpeedrunList extends ConsumerWidget {
  const _SpeedrunList({
    required this.l10n,
    required this.view,
    required this.provider,
    required this.board,
  });
  final AppLocalizations l10n;
  final StorySpeedrunLoaded view;
  final _SpeedrunProvider provider;
  final SpeedrunBoard board;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (!view.hasCompleted)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              switch (board) {
                SpeedrunBoard.main => l10n.storySpeedrunNotCompletedYet,
                SpeedrunBoard.ext => l10n.storySpeedrunExtNotCompletedYet,
                SpeedrunBoard.third => l10n.storySpeedrunExt2NotCompletedYet,
              },
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(provider.notifier).refresh(silent: true),
            child: view.entries.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 200,
                        child: Center(child: Text(l10n.storySpeedrunEmpty)),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: view.entries.length,
                    itemBuilder: (context, i) {
                      final entry = view.entries[i];
                      final isMe = entry.userId == view.myUserId;
                      final tile = ClayTile(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 44,
                              child: Text(
                                '#${entry.rank}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                formatDuration(entry.completeSeconds),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (!isMe) return tile;
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: tile,
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
  const _ErrorView({required this.message, required this.provider});
  final String message;
  final _SpeedrunProvider provider;

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
              onPressed: () =>
                  ref.read(provider.notifier).refresh(),
              child: Text(l10n.leaderboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
