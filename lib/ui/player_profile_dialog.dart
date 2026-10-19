/// Hồ sơ xếp hạng của một người chơi: hạng + điểm ở các bảng cá nhân. Mở bằng cách bấm một dòng
/// ở bảng xếp hạng (hoặc nút "Hồ sơ" ở hộp thoại xem bộ sưu tập). Tra theo tên (tên không duy nhất:
/// trùng tên thì lấy hạng cao nhất của tên đó).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/titles.dart';
import '../l10n/l10n_ext.dart';
import '../leaderboard/player_avatar.dart';
import '../leaderboard/player_gender.dart';
import '../leaderboard/player_title.dart';
import 'widgets/avatar_circle.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/player_profile.dart';
import '../state/game_providers.dart';
import '../friends/friends.dart';
import 'email_gate.dart';
import 'friends_page.dart';
import 'web_links.dart';

Future<void> showPlayerProfile(BuildContext context, String nickname) =>
    showDialog<void>(
      context: context,
      builder: (_) => PlayerProfileDialog(nickname: nickname),
    );

class PlayerProfileDialog extends ConsumerWidget {
  const PlayerProfileDialog({super.key, required this.nickname});
  final String nickname;

  String _label(AppLocalizations l10n, ProfileBoard b) => switch (b) {
        ProfileBoard.income => '💰 ${l10n.profileBoardIncome}',
        ProfileBoard.pearls => '⭐ ${l10n.profileBoardPearls}',
        ProfileBoard.collection => '🎀 ${l10n.profileBoardCollection}',
        ProfileBoard.speed => '⏱️ ${l10n.profileBoardSpeed}',
        ProfileBoard.vip => '👑 ${l10n.profileBoardVip}',
      };

  String _value(ProfileRank r) => switch (r.board) {
        ProfileBoard.speed => formatDuration(r.value.round()),
        ProfileBoard.pearls => '${r.value.round()} ⭐',
        ProfileBoard.collection => '${r.value.round()}',
        _ => formatNumber(r.value),
      };

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('avatar-report-confirm'),
        content: Text(l10n.avatarReportConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          FilledButton(
              key: const Key('avatar-report-send'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.avatarReport)),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    if (!await ensureOnlineLinked(context)) return;
    String msg;
    try {
      await ref.read(avatarRepositoryProvider).report(nickname);
      msg = l10n.avatarReportSent;
    } catch (_) {
      msg = l10n.avatarReportFail;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addFriend(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (!await ensureOnlineLinked(context)) return;
    String msg;
    try {
      final found = await ref.read(friendsRepositoryProvider).search(nickname);
      if (found.length > 1) {
        // Trùng tên: để người chơi chọn đúng người (kèm giai đoạn) ở tab Thêm bạn.
        if (!nav.mounted) return;
        nav.pop();
        await showFriends(nav.context, initialQuery: nickname);
        return;
      }
      if (found.isEmpty) {
        msg = l10n.friendsErrNotFound;
      } else {
        final r = await ref.read(friendsRepositoryProvider).request(found.first.userId);
        msg = r == 'already' ? l10n.friendsAlready : r == 'accepted' ? l10n.friendsAccepted(nickname) : l10n.friendsRequestSent;
      }
    } catch (e) {
      msg = friendErrorText(l10n, e);
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(playerProfileProvider(nickname));
    final avatarKey = ref.watch(playerAvatarProvider(nickname)).value ?? '';
    final title = playerTitleById(ref.watch(playerTitleProvider(nickname)).value ?? '');
    final gender = ref.watch(playerGenderProvider(nickname)).value;
    return AlertDialog(
      title: Text(l10n.profileTitle(nickname), maxLines: 2, overflow: TextOverflow.ellipsis),
      content: SingleChildScrollView(
        child: switch (async) {
          AsyncData(:final value) when value.isEmpty =>
            Text(l10n.profileNoRanks, key: const Key('profile-empty')),
          AsyncData(:final value) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (avatarKey.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(children: [
                      AvatarCircle(avatarKey: avatarKey, size: 72),
                      // Không báo cáo ảnh của chính mình.
                      if (nickname != (ref.read(sharedPreferencesProvider).getString('leaderboard_nickname') ?? ''))
                        TextButton(
                          key: const Key('avatar-report'),
                          onPressed: () => _report(context, ref),
                          child: Text(l10n.avatarReport),
                        ),
                    ]),
                  ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${title.emoji} ${playerTitleName(l10n, title.id)}',
                        key: const Key('profile-title'),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                if (gender != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                        '${gender.symbol} ${switch (gender) {
                          PlayerGender.male => l10n.profileGenderMale,
                          PlayerGender.female => l10n.profileGenderFemale,
                          PlayerGender.other => l10n.profileGenderOther,
                        }}',
                        key: const Key('profile-gender')),
                  ),
                for (final r in value)
                  Padding(
                    key: Key('profile-row-${r.board.name}'),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('#${r.rank}',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(child: Text(_label(l10n, r.board))),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_value(r)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          AsyncError() => Text(l10n.guildErrNetwork, key: const Key('profile-error')),
          _ => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
        },
      ),
      actions: [
        // Không kết bạn với chính mình.
        if (nickname != (ref.read(sharedPreferencesProvider).getString('leaderboard_nickname') ?? ''))
          TextButton(
            key: const Key('profile-add-friend'),
            onPressed: () => _addFriend(context, ref),
            child: Text(l10n.friendsAddButton),
          ),
        TextButton(
          key: const Key('profile-open-web'),
          onPressed: () => openWebLink(context, ref, webProfileUrl(nickname)),
          child: Text(l10n.profileOpenWeb),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
