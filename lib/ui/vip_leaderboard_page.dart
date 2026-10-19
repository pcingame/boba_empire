/// Bảng xếp hạng VIP — xếp theo VIP EXP, kèm chấm xanh cho VIP ≥ cấp 5 đang online.
/// Cùng khuôn accessory_leaderboard_page.dart (dùng chung biệt danh).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/topup.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../leaderboard/flair.dart';
import '../leaderboard/vip_leaderboard_controller.dart';
import 'web_links.dart';
import 'player_profile_dialog.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';
import 'widgets/stagger_in.dart';

Future<void> showVipLeaderboard(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const VipLeaderboardPage()));

class VipLeaderboardPage extends ConsumerStatefulWidget {
  const VipLeaderboardPage({super.key});

  @override
  ConsumerState<VipLeaderboardPage> createState() => _VipLeaderboardPageState();
}

class _VipLeaderboardPageState extends ConsumerState<VipLeaderboardPage> {
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
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(vipLeaderboardControllerProvider.notifier).refresh();
      });
    }
    final view = ref.watch(vipLeaderboardControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.vipLbTitle),
          actions: const [WebBoardActions(WebBoard.vip)],
        ),
        body: switch (view) {
          VipLeaderboardLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          VipLeaderboardNeedsNickname() => _NicknameForm(ctrl: _nameCtrl),
          VipLeaderboardLoaded() => _List(view: view),
          VipLeaderboardError() => const _ErrorView(),
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
                    .read(vipLeaderboardControllerProvider.notifier)
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
  final VipLeaderboardLoaded view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (view.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.vipLbEmpty, textAlign: TextAlign.center),
        ),
      );
    }
    return Column(
      children: [
        if (topupVipLevel(view.myVipExp) == 0)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l10n.vipLbNoVip,
                key: const Key('vip-lb-no-vip'), textAlign: TextAlign.center),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(vipLeaderboardControllerProvider.notifier)
                .refresh(silent: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: view.entries.length,
              itemBuilder: (context, i) => StaggerIn(index: i, child: Builder(builder: (context) {
                final e = view.entries[i];
                final isMe = e.userId == view.myUserId;
                return ClayTile(
                  key: Key('vip-lb-row-${e.userId}'),
                  onTap: () => showPlayerProfile(context, e.nickname),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '#${e.rank}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isMe ? theme.colorScheme.primary : null,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          key: vipFrameDecoration(e.level) == null
                              ? null
                              : const Key('vip-frame'),
                          padding: vipFrameDecoration(e.level) == null
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: vipFrameDecoration(e.level),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                if (e.online)
                                  Container(
                                    key: const Key('vip-lb-online'),
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2E7D32),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                VipTag(level: e.level),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    e.nickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isMe
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              vipName(l10n, e.level),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.vipLbExp(formatNumber(e.vipExp.toDouble())),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })),
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
            Text(l10n.accessoryLbError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  ref.read(vipLeaderboardControllerProvider.notifier).refresh(),
              child: Text(l10n.leaderboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
