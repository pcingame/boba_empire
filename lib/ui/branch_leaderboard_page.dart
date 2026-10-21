/// Bảng xếp hạng Chi nhánh: tổng cấp mọi chi nhánh, mở từ màn gom BXH. Dùng chung biệt danh với các BXH khác.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/branches.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/branch_leaderboard.dart';
import 'player_profile_dialog.dart';
import 'web_links.dart' show WebBoard, WebBoardActions;
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';
import 'widgets/stagger_in.dart';

Future<void> showBranchLeaderboard(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BranchLeaderboardPage()));

class BranchLeaderboardPage extends ConsumerStatefulWidget {
  const BranchLeaderboardPage({super.key});
  @override
  ConsumerState<BranchLeaderboardPage> createState() => _State();
}

class _State extends ConsumerState<BranchLeaderboardPage> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(branchLbControllerProvider.notifier).refresh();
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
    final ctrl = ref.read(branchLbControllerProvider.notifier);
    final view = ref.watch(branchLbControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.branchLbTitle), actions: const [WebBoardActions(WebBoard.branches)]),
        body: switch (view) {
          BranchLbLoading() => const Center(child: CircularProgressIndicator()),
          BranchLbNeedsNickname() => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l10n.leaderboardNicknameIntro, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('branch-lb-name'),
                    controller: _name,
                    maxLength: 20,
                    decoration: InputDecoration(labelText: l10n.leaderboardNicknameHint, border: const OutlineInputBorder()),
                  ),
                  FilledButton(
                    key: const Key('branch-lb-submit'),
                    onPressed: () {
                      final n = _name.text.trim();
                      if (n.isNotEmpty) ctrl.submitNickname(n);
                    },
                    child: Text(l10n.leaderboardSubmit),
                  ),
                ]),
              ),
            ),
          BranchLbError() => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(l10n.accessoryLbError, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: ctrl.refresh, child: Text(l10n.leaderboardRetry)),
              ]),
            ),
          BranchLbLoaded(:final entries, :final myUserId) => entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.branchLbEmpty, key: const Key('branch-lb-empty'), textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ctrl.refresh(silent: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    children: [
                      for (final e in entries)
                        StaggerIn(index: e.rank - 1, child: _Row(e: e, me: e.userId == myUserId)),
                    ],
                  ),
                ),
        },
      ),
    );
  }
}

const _maxTotal = 17 * 10;

/// Một dòng: huy hiệu hạng (🥇🥈🥉 cho top 3), tên, thanh tiến độ tới mức tối đa; dòng của mình viền màu chủ đạo.
class _Row extends StatelessWidget {
  const _Row({required this.e, required this.me});
  final BranchLbEntry e;
  final bool me;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      margin: me ? const EdgeInsets.symmetric(vertical: 2) : EdgeInsets.zero,
      decoration: me
          ? BoxDecoration(border: Border.all(color: primary, width: 2), borderRadius: BorderRadius.circular(18))
          : null,
      child: ClayTile(
        key: Key('branch-lb-row-${e.userId}'),
        onTap: () => showPlayerProfile(context, e.nickname),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (me ? primary : theme.colorScheme.outline).withValues(alpha: 0.15),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: e.rank <= 3
                    ? Text(const ['🥇', '🥈', '🥉'][e.rank - 1], style: const TextStyle(fontSize: 22))
                    : Text('${e.rank}',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: me ? primary : null)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: me ? FontWeight.w900 : FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: (e.totalLevels / _maxTotal).clamp(0.0, 1.0), minHeight: 6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(l10n.branchLbRow(e.totalLevels, e.opened, branchCities.length),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
