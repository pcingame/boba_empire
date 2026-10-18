/// Trang hồ sơ của chính mình: avatar (ảnh tự tải lên, công khai), biệt danh, danh hiệu, thống kê tiến độ,
/// xem hạng và chia sẻ. Mở bằng nút avatar trên màn chính.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessories.dart';
import '../core/achievements.dart';
import '../core/format.dart';
import '../core/titles.dart';
import '../core/topup.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../leaderboard/player_avatar.dart';
import '../leaderboard/player_title.dart';
import '../state/game_providers.dart';
import 'email_gate.dart';
import 'invite_dialog.dart' show shareTextProvider;
import 'player_profile_dialog.dart';
import 'title_picker_dialog.dart';
import 'web_links.dart';
import 'widgets/avatar_circle.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showMyProfile(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfilePage()));

class MyProfilePage extends ConsumerStatefulWidget {
  const MyProfilePage({super.key});
  @override
  ConsumerState<MyProfilePage> createState() => _State();
}

class _State extends ConsumerState<MyProfilePage> {
  bool _busy = false;

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await ensureOnlineLinked(context) || !mounted) return;
    setState(() => _busy = true);
    try {
      await action();
    } on AvatarTooBig {
      if (mounted) _snack(l10n.myProfileAvatarTooBig);
    } catch (_) {
      if (mounted) _snack(l10n.myProfileAvatarFail);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final g = ref.watch(gameControllerProvider);
    final avatar = ref.watch(myAvatarProvider);
    final titleId = ref.watch(selectedTitleProvider);
    final title = playerTitleById(titleId);
    final nickname = ref.read(sharedPreferencesProvider).getString('leaderboard_nickname') ?? '';
    final stats = <(String, String)>[
      (l10n.myProfileStatStage, stageName(l10n, g.stage)),
      (l10n.myProfileStatEarned, formatNumber(g.lifetimeEarnings)),
      (l10n.myProfileStatStars, formatNumber(g.prestigeStars)),
      (l10n.myProfileStatAscend, '${g.ascensionCount}'),
      (l10n.myProfileStatVip, vipName(l10n, topupVipLevel(g.vipExp))),
      (l10n.myProfileStatCollection, '${g.ownedAccessories.length}/${accessories.length}'),
      (l10n.myProfileStatAchievements, '${g.achievementsClaimed.length}/${achievements.length}'),
    ];
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.myProfileTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            ClayCard(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                AvatarCircle(avatarKey: avatar, size: 96),
                const SizedBox(height: 10),
                Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
                  OutlinedButton(
                    key: const Key('my-avatar-change'),
                    onPressed: _busy ? null : () => _run(() => ref.read(myAvatarProvider.notifier).change()),
                    child: Text(l10n.myProfileChangeAvatar),
                  ),
                  if (avatar.isNotEmpty)
                    TextButton(
                      key: const Key('my-avatar-remove'),
                      onPressed: _busy ? null : () => _run(() => ref.read(myAvatarProvider.notifier).remove()),
                      child: Text(l10n.myProfileRemoveAvatar),
                    ),
                ]),
                const SizedBox(height: 8),
                Text(nickname.isEmpty ? l10n.myProfileNoNickname : nickname,
                    key: const Key('my-nickname'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                InkWell(
                  key: const Key('my-title'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showTitlePicker(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                        child: Text(
                          title == null ? l10n.titlePickerTitle : '${title.emoji} ${playerTitleName(l10n, title.id)}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const Icon(Icons.edit_outlined, size: 16),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            for (final (label, value) in stats)
              ClayTile(
                child: Row(children: [
                  Expanded(child: Text(label)),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            if (nickname.isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton.tonal(
                key: const Key('my-ranks'),
                onPressed: () => showPlayerProfile(context, nickname),
                child: Text(l10n.myProfileRanks),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (btnContext) => OutlinedButton(
                  key: const Key('my-share'),
                  onPressed: () {
                    final box = btnContext.findRenderObject() as RenderBox?;
                    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
                    ref.read(shareTextProvider)(l10n.profileShareText(nickname, webProfileUrl(nickname)), origin);
                  },
                  child: Text(l10n.myProfileShare),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
