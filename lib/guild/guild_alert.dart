/// Chấm đỏ của Hội ở menu Thi đấu: có việc cần làm không (thưởng chưa nhận, đơn xin vào
/// chờ duyệt, tin chat chưa đọc). Chỉ suy từ trạng thái Hội đã tải — dữ liệu được làm
/// tươi bởi [GuildController.syncBuff] lúc mở app/quay lại.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/guild.dart';
import '../core/guild_shop.dart';
import 'guild_chat_unread.dart';
import 'guild_controller.dart';

/// Có thưởng nào (mốc tuần, Boss, nhiệm vụ cá nhân, quỹ) đang chờ nhận không. Cùng điều
/// kiện với nút "Nhận" trong màn Hội.
bool guildHasClaimable(GuildMine v) {
  final g = v.guild;
  final enough = v.myPoints >= guildMinPointsToClaim;
  for (var i = 0; i < guildMilestones.length; i++) {
    if (enough && g.total >= guildMilestones[i].threshold && !g.claimed.contains(i + 1)) {
      return true;
    }
  }
  if (enough && g.bossHp > 0 && g.total >= g.bossHp && !g.bossClaimed) return true;
  for (var i = 0; i < guildQuests.length; i++) {
    if (v.myPoints >= guildQuests[i].need && !g.questsClaimed.contains(i + 1)) return true;
  }
  return g.fund.reached && !g.fund.claimed && g.fund.mine >= guildFundMinDonation;
}

final guildAlertProvider = Provider<bool>((ref) {
  final view = ref.watch(guildControllerProvider);
  if (view is! GuildMine) return false;
  if (ref.watch(guildChatUnreadProvider)) return true;
  if (view.canModerate && view.guild.requests.isNotEmpty) return true;
  return guildHasClaimable(view);
});
