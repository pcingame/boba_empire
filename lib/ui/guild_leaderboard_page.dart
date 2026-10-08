/// BXH Hội: top hội theo tổng điểm tuần này (hội ẩn/0 điểm không lên bảng).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guild/guild_controller.dart';
import '../guild/guild_repository.dart';
import '../l10n/app_localizations.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showGuildLeaderboard(BuildContext context) =>
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GuildLeaderboardPage()));

final guildLeaderboardProvider =
    FutureProvider.autoDispose<List<GuildSummary>>(
        (ref) => ref.read(guildRepositoryProvider).leaderboard(),
        // Riverpod 3 tự thử lại provider lỗi (backoff dài) → màn hình quay mãi
        // thay vì hiện nút "Thử lại". Tắt retry: lỗi hiện ngay, người dùng chủ động.
        retry: (_, _) => null);

class GuildLeaderboardPage extends ConsumerWidget {
  const GuildLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final res = ref.watch(guildLeaderboardProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.guildLbTitle)),
        body: res.when(
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
                    onPressed: () => ref.invalidate(guildLeaderboardProvider),
                    child: Text(l10n.leaderboardRetry),
                  ),
                ],
              ),
            ),
          ),
          data: (list) => list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child:
                        Text(l10n.guildLbEmpty, textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(guildLeaderboardProvider.future),
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
                            // Tên dài phải co lại, không đẩy cột điểm ra ngoài.
                            Expanded(
                              child: Text('[${g.tag}] ${g.name}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            // Điểm có thể rất lớn: co chữ, không đẩy hàng tràn.
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.guildPoints(g.weekTotal),
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
      ),
    );
  }
}
