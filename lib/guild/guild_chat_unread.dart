/// "Chưa đọc" của chat hội: so id tin mới nhất server báo ([MyGuild.chatLatestId]) với id
/// tin cuối người này đã xem (lưu máy, theo từng hội). Không đếm số — chỉ có/không.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_providers.dart';
import 'guild_controller.dart';

class GuildChatSeen extends Notifier<Map<String, int>> {
  static String _key(String guildId) => 'guild_chat_seen_$guildId';

  @override
  Map<String, int> build() => {};

  int seenOf(String guildId) =>
      state[guildId] ?? ref.read(sharedPreferencesProvider).getInt(_key(guildId)) ?? 0;

  /// Chỉ tăng (tải lại danh sách cũ hơn không làm tin mới hiện là chưa đọc).
  void markSeen(String guildId, int messageId) {
    if (messageId <= seenOf(guildId)) return;
    state = {...state, guildId: messageId};
    ref.read(sharedPreferencesProvider).setInt(_key(guildId), messageId);
  }
}

final guildChatSeenProvider =
    NotifierProvider<GuildChatSeen, Map<String, int>>(GuildChatSeen.new);

/// Có tin chat hội chưa đọc không (false khi chưa ở hội / chưa tải).
final guildChatUnreadProvider = Provider<bool>((ref) {
  final view = ref.watch(guildControllerProvider);
  if (view is! GuildMine) return false;
  ref.watch(guildChatSeenProvider);
  final g = view.guild;
  return g.chatLatestId > ref.read(guildChatSeenProvider.notifier).seenOf(g.id);
});
