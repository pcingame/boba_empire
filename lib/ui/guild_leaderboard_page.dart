/// BXH Hội, 3 tab: Tổng điểm tuần · Trung bình/người (hội ≥ 5 người) · Chuỗi tuần liên
/// tiếp đạt đủ 3 mốc. Hội ẩn/không có điểm không lên bảng.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/guild.dart';
import '../guild/guild_controller.dart';
import '../guild/guild_repository.dart';
import '../l10n/app_localizations.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showGuildLeaderboard(BuildContext context) =>
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GuildLeaderboardPage()));

// Riverpod 3 tự thử lại provider lỗi (backoff dài) → màn hình quay mãi thay vì hiện
// nút "Thử lại". Tắt retry: lỗi hiện ngay, người dùng chủ động.
final guildLeaderboardProvider = FutureProvider.autoDispose<List<GuildSummary>>(
    (ref) => ref.read(guildRepositoryProvider).leaderboard(),
    retry: (_, _) => null);
final guildLeaderboardAvgProvider =
    FutureProvider.autoDispose<List<GuildSummary>>(
        (ref) => ref.read(guildRepositoryProvider).leaderboardAvg(),
        retry: (_, _) => null);
final guildLeaderboardStreakProvider =
    FutureProvider.autoDispose<List<GuildSummary>>(
        (ref) => ref.read(guildRepositoryProvider).leaderboardStreak(),
        retry: (_, _) => null);

class GuildLeaderboardPage extends StatelessWidget {
  const GuildLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PhoneWidth(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.guildLbTitle),
            bottom: TabBar(
              tabs: [
                Tab(key: const Key('guild-lb-tab-total'), text: l10n.guildLbTabTotal),
                Tab(key: const Key('guild-lb-tab-avg'), text: l10n.guildLbTabAvg),
                Tab(key: const Key('guild-lb-tab-streak'), text: l10n.guildLbTabStreak),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _Board(
                provider: guildLeaderboardProvider,
                emptyText: l10n.guildLbEmpty,
                metric: (l, g) => l.guildPoints(g.weekTotal),
              ),
              _Board(
                provider: guildLeaderboardAvgProvider,
                emptyText: l10n.guildLbAvgEmpty,
                note: l10n.guildLbAvgNote(guildAvgMinMembers),
                metric: (l, g) => l.guildAvgPerMember(g.avgPoints ?? 0),
              ),
              _Board(
                provider: guildLeaderboardStreakProvider,
                emptyText: l10n.guildLbStreakEmpty,
                note: l10n.guildLbStreakNote,
                metric: (l, g) => l.guildStreakWeeks(g.streak ?? 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Board extends ConsumerWidget {
  const _Board({
    required this.provider,
    required this.emptyText,
    required this.metric,
    this.note,
  });

  final FutureProvider<List<GuildSummary>> provider;
  final String emptyText;
  final String? note;
  final String Function(AppLocalizations, GuildSummary) metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final res = ref.watch(provider);
    return res.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.guildErrNetwork, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(provider),
                child: Text(l10n.leaderboardRetry),
              ),
            ],
          ),
        ),
      ),
      data: (list) => Column(
        children: [
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(note!,
                  key: const Key('guild-lb-note'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall),
            ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(emptyText, textAlign: TextAlign.center),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.refresh(provider.future),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final g = list[i];
                        return ClayTile(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Text('${g.rank ?? i + 1}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              Text(g.emoji,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              // Tên dài phải co lại, không đẩy cột số ra ngoài.
                              Expanded(
                                child: Text('[${g.tag}] ${g.name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              // Số có thể rất lớn: co chữ, không đẩy hàng tràn.
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(metric(l10n, g),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
