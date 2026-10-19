/// Bảng xếp hạng Chi nhánh: tổng cấp mọi chi nhánh, mở từ màn gom BXH. Dùng chung biệt danh với các BXH khác.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/branches.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/branch_leaderboard.dart';
import 'player_profile_dialog.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

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
    final theme = Theme.of(context);
    final ctrl = ref.read(branchLbControllerProvider.notifier);
    final view = ref.watch(branchLbControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.branchLbTitle)),
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
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final me = e.userId == myUserId;
                      return ClayTile(
                        key: Key('branch-lb-row-${e.userId}'),
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
                              child: Text(l10n.branchLbRow(e.totalLevels, e.opened, branchCities.length), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
        },
      ),
    );
  }
}
