/// Màn hình "Bảng xếp hạng tốc độ hoàn thành cốt truyện" — mở từ
/// compete_hub_dialog.dart. Xem story_speedrun_controller.dart cho luồng
/// nộp mốc + tải danh sách.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/story_speedrun_controller.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';

Future<void> showStorySpeedrunPage(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const StorySpeedrunPage()),
  );
}

class StorySpeedrunPage extends ConsumerStatefulWidget {
  const StorySpeedrunPage({super.key});

  @override
  ConsumerState<StorySpeedrunPage> createState() => _StorySpeedrunPageState();
}

class _StorySpeedrunPageState extends ConsumerState<StorySpeedrunPage> {
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
    final notifier = ref.read(storySpeedrunControllerProvider.notifier);
    notifier.getMyCompleteSeconds = () =>
        ref.read(gameControllerProvider).storyCompleteSeconds;

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final viewState = ref.watch(storySpeedrunControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storySpeedrunTitle)),
      body: SafeArea(
        child: switch (viewState) {
          StorySpeedrunLoading() =>
            const Center(child: CircularProgressIndicator()),
          StorySpeedrunNeedsNickname() =>
            _NicknameForm(l10n: l10n, nameCtrl: _nameCtrl),
          StorySpeedrunLoaded() => _SpeedrunList(l10n: l10n, view: viewState),
          StorySpeedrunError(:final message) => _ErrorView(message: message),
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
                  ref
                      .read(storySpeedrunControllerProvider.notifier)
                      .submitNickname(name);
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

class _SpeedrunList extends StatelessWidget {
  const _SpeedrunList({required this.l10n, required this.view});
  final AppLocalizations l10n;
  final StorySpeedrunLoaded view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (!view.hasCompleted)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.storySpeedrunNotCompletedYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        Expanded(
          child: view.entries.isEmpty
              ? Center(child: Text(l10n.storySpeedrunEmpty))
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
                          Flexible(
                            child: Text(
                              formatDuration(entry.completeSeconds),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (!isMe) return tile;
                    return Container(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: theme.colorScheme.primary, width: 2),
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
              onPressed: () =>
                  ref.read(storySpeedrunControllerProvider.notifier).refresh(),
              child: Text(l10n.leaderboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
