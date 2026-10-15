/// Bảng xếp hạng Thợ pha chế — xếp theo SỐ MÓN CÔNG THỨC ĐÃ TỪNG ĐẠT "THẠO". Cùng khuôn
/// `m3_leaderboard_page.dart` (dùng chung tên người chơi, top tuyệt đối).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/daily.dart';
import '../core/recipe_mastery.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/flair.dart';
import '../leaderboard/recipe_leaderboard_controller.dart';
import '../leaderboard/recipe_leaderboard_repository.dart' show RecipeBoard;
import '../state/game_providers.dart';
import 'player_profile_dialog.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showRecipeLeaderboard(BuildContext context, {RecipeBoard board = RecipeBoard.quiz}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RecipeLeaderboardPage(initialBoard: board)));

/// Hai tab: Trắc nghiệm (số món Thạo) và Pha theo đơn (số món pha hoàn hảo không công thức mẫu).
class RecipeLeaderboardPage extends StatelessWidget {
  const RecipeLeaderboardPage({super.key, this.initialBoard = RecipeBoard.quiz});
  final RecipeBoard initialBoard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PhoneWidth(
      child: DefaultTabController(
        length: RecipeBoard.values.length,
        initialIndex: initialBoard.index,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.rlbTitle),
            bottom: TabBar(tabs: [
              Tab(key: const Key('rlb-tab-quiz'), text: l10n.rlbTabQuiz),
              Tab(key: const Key('rlb-tab-orders'), text: l10n.recipeOrderOrders),
              Tab(key: const Key('rlb-tab-daily'), text: l10n.rlbTabDaily),
            ]),
          ),
          body: const TabBarView(children: [
            _BoardTab(board: RecipeBoard.quiz),
            _BoardTab(board: RecipeBoard.orders),
            _BoardTab(board: RecipeBoard.daily),
          ]),
        ),
      ),
    );
  }
}

extension on RecipeBoard {
  /// Tiền tố khoá widget: tab trắc nghiệm giữ `rlb-` như cũ, tab Pha theo đơn là `olb-`.
  String get prefix => switch (this) {
        RecipeBoard.quiz => 'rlb',
        RecipeBoard.orders => 'olb',
        RecipeBoard.daily => 'dlb',
      };

  NotifierProvider<RecipeLeaderboardController, RecipeLeaderboardViewState> get provider => switch (this) {
        RecipeBoard.quiz => recipeLeaderboardControllerProvider,
        RecipeBoard.orders => recipeOrderLeaderboardControllerProvider,
        RecipeBoard.daily => recipeDailyLeaderboardControllerProvider,
      };
}

class _BoardTab extends ConsumerStatefulWidget {
  const _BoardTab({required this.board});
  final RecipeBoard board;

  @override
  ConsumerState<_BoardTab> createState() => _BoardTabState();
}

class _BoardTabState extends ConsumerState<_BoardTab> {
  final _nameCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final notifier = ref.read(board.provider.notifier);

    // Số liệu của mình lấy thẳng từ bản lưu (chỉ tăng — khớp trigger không-hạ-cấp ở server).
    notifier.getMyMastered = () {
      final g = ref.read(gameControllerProvider);
      return switch (board) {
        RecipeBoard.quiz => recipeMasteredEver({for (final e in g.recipeProgress.entries) '${e.key}': e.value.toList()}),
        RecipeBoard.orders => g.recipeOrderPerfect.length,
        // Điểm hôm nay (0 nếu chưa làm hôm nay ⇒ chưa có tên trên bảng).
        RecipeBoard.daily => g.recipeDailyDay == dayIndex(ref.read(clockProvider)()) ? g.recipeDailyScore : 0,
      };
    };

    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => notifier.refresh());
    }

    final view = ref.watch(board.provider);
    return switch (view) {
      RecipeLeaderboardLoading() => const Center(child: CircularProgressIndicator()),
      RecipeLeaderboardNeedsNickname() => _NicknameForm(board: board, ctrl: _nameCtrl),
      RecipeLeaderboardLoaded() => _List(board: board, view: view),
      RecipeLeaderboardError() => _ErrorView(board: board),
    };
  }
}

class _NicknameForm extends ConsumerWidget {
  const _NicknameForm({required this.board, required this.ctrl});
  final RecipeBoard board;
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
              key: Key('${board.prefix}-nickname'),
              controller: ctrl,
              maxLength: 20,
              decoration: InputDecoration(labelText: l10n.leaderboardNicknameHint, border: const OutlineInputBorder()),
            ),
            FilledButton(
              key: Key('${board.prefix}-submit'),
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                ref.read(board.provider.notifier).submitNickname(name);
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
  const _List({required this.board, required this.view});
  final RecipeBoard board;
  final RecipeLeaderboardLoaded view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (view.entries.isEmpty) {
      return Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
                switch (board) {
                  RecipeBoard.quiz => l10n.rlbEmpty,
                  RecipeBoard.orders => l10n.rlbOrderEmpty,
                  RecipeBoard.daily => l10n.rlbDailyEmpty,
                },
                textAlign: TextAlign.center),
          ),
      );
    }

    return Column(
      children: [
        if (view.myMastered == 0)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
                switch (board) {
                  RecipeBoard.quiz => l10n.rlbNoMastered,
                  RecipeBoard.orders => l10n.rlbNoPerfect,
                  RecipeBoard.daily => l10n.rlbNoDaily,
                },
                key: Key('${board.prefix}-none'), textAlign: TextAlign.center),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(board.provider.notifier).refresh(silent: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: view.entries.length,
              itemBuilder: (context, i) {
                final e = view.entries[i];
                final isMe = e.userId == view.myUserId;
                const medals = ['🥇', '🥈', '🥉'];
                // Hàng của mình viền màu chủ đạo để nhìn ra ngay.
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: isMe
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.colorScheme.primary, width: 2),
                        )
                      : null,
                  child: ClayTile(
                  key: Key('${board.prefix}-row-$i'),
                  margin: EdgeInsets.zero,
                  onTap: () => showPlayerProfile(context, e.nickname),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: e.rank <= 3
                            ? Text(medals[e.rank - 1], style: const TextStyle(fontSize: 26))
                            : Text('${e.rank}',
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
                                  style: TextStyle(fontWeight: isMe || e.rank <= 3 ? FontWeight.w800 : FontWeight.normal)),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                            switch (board) {
                              RecipeBoard.quiz => l10n.rlbMastered(e.mastered),
                              RecipeBoard.orders => l10n.rlbPerfect(e.mastered),
                              RecipeBoard.daily => l10n.rlbDailyScore(e.mastered),
                            },
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
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
  const _ErrorView({required this.board});
  final RecipeBoard board;

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
              key: Key('${board.prefix}-retry'),
              onPressed: () => ref.read(board.provider.notifier).refresh(),
              child: Text(l10n.leaderboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
