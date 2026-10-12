/// Danh sách thành viên Hội: mỗi hàng là một thẻ gọn (ảnh đại diện, tên, vai trò, điểm tuần + thanh điểm); chạm
/// vào hàng mở bảng thao tác (Nhắc trong chat, Tặng 💎, Xem hồ sơ, và quyền quản lý theo vai trò) thay cho
/// ba nút nhỏ cố định trên mỗi hàng. Hội đông (>[guildMembersSearchMin]) có ô tìm theo tên.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/guild.dart';
import '../guild/guild_controller.dart';
import '../guild/guild_repository.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/flair.dart';
import 'player_profile_dialog.dart';
import 'widgets/clay.dart';

/// Hội có nhiều hơn chừng này thành viên thì hiện ô tìm.
const int guildMembersSearchMin = 8;

/// Thứ tự hiển thị: chủ hội → phó hội → thành viên; trong mỗi nhóm giữ nguyên thứ tự của server (điểm tuần
/// giảm dần, vào sớm xếp trên).
List<GuildMemberInfo> orderGuildMembers(List<GuildMemberInfo> members) => [
      ...members.where((m) => m.role == GuildRole.owner),
      ...members.where((m) => m.role == GuildRole.officer),
      ...members.where((m) => m.role == GuildRole.member),
    ];

/// Lọc theo tên (không phân biệt hoa thường); [query] rỗng trả nguyên danh sách.
List<GuildMemberInfo> filterGuildMembers(List<GuildMemberInfo> members, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return members;
  return [for (final m in members) if (m.nickname.toLowerCase().contains(q)) m];
}

/// Hạng huy chương (0..2) theo điểm tuần cho top 3 CÓ điểm; thành viên khác không có trong map.
Map<String, int> guildMedalRanks(List<GuildMemberInfo> members) {
  final byPoints = [...members]..sort((a, b) => b.points.compareTo(a.points));
  return {
    for (var i = 0; i < byPoints.length && i < 3; i++)
      if (byPoints[i].points > 0) byPoints[i].userId: i,
  };
}

/// Chữ cái/emoji đầu của tên làm ảnh đại diện.
String guildAvatarGlyph(String nickname) {
  final t = nickname.trim();
  return t.isEmpty ? '?' : t.characters.first.toUpperCase();
}

class GuildMembersSection extends ConsumerStatefulWidget {
  const GuildMembersSection({
    super.key,
    required this.view,
    required this.onGift,
    required this.onManage,
    required this.onKick,
    required this.onMention,
  });

  final GuildMine view;
  final void Function(GuildMemberInfo m) onGift;

  /// [action]: 'officer' (bổ nhiệm/bãi nhiệm) hoặc 'transfer' (nhường chủ hội) — cùng quy ước `_manage`.
  final void Function(GuildMemberInfo m, String action) onManage;
  final void Function(GuildMemberInfo m) onKick;
  final void Function(GuildMemberInfo m) onMention;

  @override
  ConsumerState<GuildMembersSection> createState() => _GuildMembersSectionState();
}

class _GuildMembersSectionState extends ConsumerState<GuildMembersSection> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openSheet(GuildMemberInfo m) async {
    final l10n = AppLocalizations.of(context)!;
    final view = widget.view;
    final isMe = m.userId == view.myUserId;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      // Tới 7 dòng thao tác: cho cao theo nội dung (tối đa cả màn) để màn nhỏ không phải cuộn mới thấy "Kick".
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              key: Key('guild-member-sheet-${m.userId}'),
              leading: _Avatar(member: m, isMe: isMe, size: 44),
              title: Text(m.nickname, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${_roleLabel(l10n, m.role)} · ${l10n.guildPoints(m.points)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Divider(height: 1),
            if (!isMe)
              ListTile(
                key: Key('guild-mention-${m.userId}'),
                leading: const Icon(Icons.alternate_email),
                title: Text(l10n.guildMemberMention),
                onTap: () => Navigator.pop(ctx, 'mention'),
              ),
            if (!isMe)
              ListTile(
                key: Key('guild-gift-${m.userId}'),
                leading: const Icon(Icons.card_giftcard),
                title: Text(l10n.guildGiftTooltip),
                onTap: () => Navigator.pop(ctx, 'gift'),
              ),
            ListTile(
              key: Key('guild-profile-${m.userId}'),
              leading: const Icon(Icons.badge_outlined),
              title: Text(l10n.guildMemberProfile),
              onTap: () => Navigator.pop(ctx, 'profile'),
            ),
            if (view.isOwner && !isMe && m.role != GuildRole.owner)
              ListTile(
                key: Key('guild-toggle-officer-${m.userId}'),
                leading: const Icon(Icons.star_outline),
                title: Text(m.role == GuildRole.officer ? l10n.guildDemote : l10n.guildPromote),
                onTap: () => Navigator.pop(ctx, 'officer'),
              ),
            if (view.isOwner && !isMe)
              ListTile(
                key: Key('guild-transfer-${m.userId}'),
                leading: const Icon(Icons.swap_horiz),
                title: Text(l10n.guildTransfer),
                onTap: () => Navigator.pop(ctx, 'transfer'),
              ),
            if (view.canKick(m))
              ListTile(
                key: Key('guild-kick-${m.userId}'),
                leading: const Icon(Icons.person_remove),
                title: Text(l10n.guildKick),
                onTap: () => Navigator.pop(ctx, 'kick'),
              ),
          ]),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'mention':
        widget.onMention(m);
      case 'gift':
        widget.onGift(m);
      case 'profile':
        showPlayerProfile(context, m.nickname);
      case 'officer' || 'transfer':
        widget.onManage(m, choice);
      case 'kick':
        widget.onKick(m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final view = widget.view;
    final all = view.guild.members;
    final medals = guildMedalRanks(all);
    final maxPoints = all.isEmpty ? 0 : all.map((m) => m.points).reduce((a, b) => a > b ? a : b);
    final shown = filterGuildMembers(orderGuildMembers(all), _search.text);
    const medalGlyph = ['🥇', '🥈', '🥉'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          child: Text('👥 ${l10n.guildMembersHeader} (${all.length}/$guildMaxMembers)',
              key: const Key('guild-members-header'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ),
        if (all.length > guildMembersSearchMin)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TextField(
              key: const Key('guild-member-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.guildMemberSearchHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l10n.guildMemberNoMatch, key: const Key('guild-member-no-match')),
          ),
        for (final m in shown)
          ClayTile(
            key: Key('guild-member-${m.userId}'),
            onTap: () => _openSheet(m),
            child: Row(
              children: [
                _Avatar(member: m, isMe: m.userId == view.myUserId),
                const SizedBox(width: 10),
                Expanded(
                  child: VipNameBlock(
                    userId: m.userId,
                    // Hai dòng: trên là huy chương/vai trò/huy hiệu (co nhỏ vừa khung bằng FittedBox), dưới là
                    // tên (cắt "…") + thanh điểm — không tràn dù tên và nhãn VIP 10 rất dài ở màn 320px.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (medals.containsKey(m.userId)) Text('${medalGlyph[medals[m.userId]!]} '),
                              if (m.role == GuildRole.owner) const Text('👑 '),
                              if (m.role == GuildRole.officer) const Text('⭐ '),
                              FlairBadge(userId: m.userId),
                            ],
                          ),
                        ),
                        Text(m.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: m.userId == view.myUserId ? FontWeight.bold : FontWeight.normal)),
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: maxPoints <= 0 ? 0 : (m.points / maxPoints).clamp(0.0, 1.0).toDouble(),
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  key: Key('guild-member-points-${m.userId}'),
                  width: 84,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(l10n.guildPoints(m.points), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
      ],
    );
  }
}

String _roleLabel(AppLocalizations l10n, GuildRole r) => switch (r) {
      GuildRole.owner => l10n.guildRoleOwner,
      GuildRole.officer => l10n.guildRoleOfficer,
      GuildRole.member => l10n.guildRoleMember,
    };

/// Ảnh đại diện tròn: chữ/emoji đầu của tên, màu theo vai trò; viền đậm cho chính mình.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.member, required this.isMe, this.size = 38});
  final GuildMemberInfo member;
  final bool isMe;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = switch (member.role) {
      GuildRole.owner => cs.tertiaryContainer,
      GuildRole.officer => cs.secondaryContainer,
      GuildRole.member => cs.surfaceContainerHighest,
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: isMe ? Border.all(color: cs.primary, width: 2) : null,
      ),
      child: Text(guildAvatarGlyph(member.nickname),
          style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w700)),
    );
  }
}
