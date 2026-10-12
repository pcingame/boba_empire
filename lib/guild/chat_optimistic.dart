/// Cập nhật "lạc quan" cho chat Hội: hiện kết quả của thao tác NGAY (gửi tin, bấm reaction) rồi mới đối
/// chiếu với server, nên người dùng không phải chờ vòng mạng. Hàm thuần để test.
library;

import 'guild_repository.dart';

/// Bản sao của [m] sau khi MÌNH bật/tắt reaction [emoji] (đúng quy tắc server `guild_chat_react`): đã bấm thì
/// bỏ (giảm 1, hết thì xoá chip), chưa bấm thì thêm (tăng 1 hoặc tạo chip mới).
GuildMessage toggleReaction(GuildMessage m, String emoji) {
  final rs = [...m.reactions];
  final i = rs.indexWhere((r) => r.emoji == emoji);
  if (i < 0) {
    rs.add(GuildReaction(emoji: emoji, count: 1, mine: true));
  } else if (rs[i].mine) {
    if (rs[i].count <= 1) {
      rs.removeAt(i);
    } else {
      rs[i] = GuildReaction(emoji: emoji, count: rs[i].count - 1, mine: false);
    }
  } else {
    rs[i] = GuildReaction(emoji: emoji, count: rs[i].count + 1, mine: true);
  }
  return GuildMessage(
      id: m.id, userId: m.userId, nickname: m.nickname, body: m.body, reactions: rs);
}

/// Áp các lần bật/tắt reaction đang chờ server ([pending] dạng "id|emoji") lên danh sách [messages].
List<GuildMessage> applyPendingToggles(List<GuildMessage> messages, Set<String> pending) {
  if (pending.isEmpty) return messages;
  return [
    for (final m in messages)
      pending.where((k) => k.startsWith('${m.id}|')).fold(m, (acc, k) => toggleReaction(acc, k.substring(k.indexOf('|') + 1))),
  ];
}
