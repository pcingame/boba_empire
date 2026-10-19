/// Bảng xếp hạng Thẻ Mùa: XP mùa hiện tại, mở từ trang Thẻ Mùa. Dùng chung biệt danh với các BXH khác.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../leaderboard/season_leaderboard.dart';
import 'player_profile_dialog.dart';
import 'widgets/clay.dart';
import 'web_links.dart';
import 'widgets/phone_width.dart';
import 'widgets/stagger_in.dart';

Future<void> showSeasonLeaderboard(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SeasonLeaderboardPage()));

class SeasonLeaderboardPage extends ConsumerStatefulWidget {
  const SeasonLeaderboardPage({super.key});
  @override
  ConsumerState<SeasonLeaderboardPage> createState() => _State();
}

class _State extends ConsumerState<SeasonLeaderboardPage> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(seasonLbControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ctrl = ref.read(seasonLbControllerProvider.notifier);
    final view = ref.watch(seasonLbControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.seasonLbTitle), actions: const [WebBoardActions(WebBoard.season)]),
        body: switch (view) {
          SeasonLbLoading() => const Center(child: CircularProgressIndicator()),
          SeasonLbNeedsNickname() => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l10n.leaderboardNicknameIntro, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('season-lb-name'),
                    controller: _name,
                    maxLength: 20,
                    decoration: InputDecoration(labelText: l10n.leaderboardNicknameHint, border: const OutlineInputBorder()),
                  ),
                  FilledButton(
                    key: const Key('season-lb-submit'),
                    onPressed: () {
                      final n = _name.text.trim();
                      if (n.isNotEmpty) ctrl.submitNickname(n);
                    },
                    child: Text(l10n.leaderboardSubmit),
                  ),
                ]),
              ),
            ),
          SeasonLbError() => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(l10n.accessoryLbError, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: ctrl.refresh, child: Text(l10n.leaderboardRetry)),
              ]),
            ),
          SeasonLbLoaded(:final entries, :final myUserId) => entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.seasonLbEmpty, key: const Key('season-lb-empty'), textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ctrl.refresh(silent: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => StaggerIn(index: i, child: Builder(builder: (context) {
                      final e = entries[i];
                      final me = e.userId == myUserId;
                      return ClayTile(
                        key: Key('season-lb-row-${e.userId}'),
                        onTap: () => showPlayerProfile(context, e.nickname),
                        child: Row(children: [
                          SizedBox(
                            width: 44,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('#${e.rank}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold, color: me ? theme.colorScheme.primary : null)),
                            ),
                          ),
                          Expanded(
                            child: Text(e.nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: me ? FontWeight.bold : FontWeight.normal)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('${e.xp} XP', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                      );
                    })),
                  ),
                ),
        },
      ),
    );
  }
}
