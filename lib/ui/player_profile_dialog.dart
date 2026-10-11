/// Hồ sơ xếp hạng của một người chơi: hạng + điểm ở các bảng cá nhân. Mở bằng cách bấm một dòng
/// ở bảng xếp hạng (hoặc nút "Hồ sơ" ở hộp thoại xem bộ sưu tập). Tra theo tên (tên không duy nhất:
/// trùng tên thì lấy hạng cao nhất của tên đó).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/player_profile.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(playerProfileProvider(nickname));
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
