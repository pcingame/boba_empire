/// Bảng xếp hạng Thợ pha chế — xếp theo SỐ MÓN CÔNG THỨC ĐÃ TỪNG ĐẠT "THẠO". Cùng khuôn
/// `m3_leaderboard_page.dart` (dùng chung tên người chơi, top tuyệt đối).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/recipe_mastery.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/flair.dart';
import '../leaderboard/recipe_leaderboard_controller.dart';
import '../state/game_providers.dart';
import 'player_profile_dialog.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showRecipeLeaderboard(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecipeLeaderboardPage()));

class RecipeLeaderboardPage extends ConsumerStatefulWidget {
  const RecipeLeaderboardPage({super.key});

  @override
  ConsumerState<RecipeLeaderboardPage> createState() => _RecipeLeaderboardPageState();
}

class _RecipeLeaderboardPageState extends ConsumerState<RecipeLeaderboardPage> {
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
    final notifier = ref.read(recipeLeaderboardControllerProvider.notifier);

    // Số món đã từng Thạo lấy thẳng từ bản lưu (chỉ tăng — khớp trigger không-hạ-cấp ở server).
    notifier.getMyMastered = () => recipeMasteredEver({
          for (final e in ref.read(gameControllerProvider).recipeProgress.entries) '${e.key}': e.value.toList(),
        });

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final view = ref.watch(recipeLeaderboardControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.rlbTitle)),
        body: switch (view) {
          RecipeLeaderboardLoading() => const Center(child: CircularProgressIndicator()),
          RecipeLeaderboardNeedsNickname() => _NicknameForm(ctrl: _nameCtrl),
          RecipeLeaderboardLoaded() => _List(view: view),
          RecipeLeaderboardError() => const _ErrorView(),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.leaderboardNicknameIntro, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              key: const Key('rlb-nickname'),
              controller: ctrl,
              maxLength: 20,
              decoration: InputDecoration(labelText: l10n.leaderboardNicknameHint, border: const OutlineInputBorder()),
            ),
            FilledButton(
              key: const Key('rlb-submit'),
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                ref.read(recipeLeaderboardControllerProvider.notifier).submitNickname(name);
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
  final RecipeLeaderboardLoaded view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (view.entries.isEmpty) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.rlbEmpty, textAlign: TextAlign.center)),
      );
    }

    return Column(
      children: [
        if (view.myMastered == 0)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l10n.rlbNoMastered, key: const Key('rlb-none'), textAlign: TextAlign.center),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(recipeLeaderboardControllerProvider.notifier).refresh(silent: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: view.entries.length,
              itemBuilder: (context, i) {
                final e = view.entries[i];
                final isMe = e.userId == view.myUserId;
                return ClayTile(
                  key: Key('rlb-row-$i'),
                  onTap: () => showPlayerProfile(context, e.nickname),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text('${e.rank}',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold, color: isMe ? theme.colorScheme.primary : null)),
                      ),
                      // Tên có thể rất dài: co lại, không đẩy cột số món ra khỏi hàng.
                      Expanded(
                        child: VipNameBlock(
                          userId: e.userId,
                          child: Row(children: [
                            FlairBadge(userId: e.userId),
                            Flexible(
                              child: Text(e.nickname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(l10n.rlbMastered(e.mastered),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
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
            Text(l10n.rlbError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('rlb-retry'),
              onPressed: () => ref.read(recipeLeaderboardControllerProvider.notifier).refresh(),
              child: Text(l10n.leaderboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
