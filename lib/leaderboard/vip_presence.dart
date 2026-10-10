/// Hiện diện online của VIP ≥ cấp [vipTitleMinLevel]: ping định kỳ lên server và nhận
/// thông báo realtime khi VIP khác vào game (xem `vip_ping` / `vip_announcements` trong
/// supabase/accessory_market_schema.sql). Mọi lỗi nuốt im lặng — đây chỉ là hiệu ứng
/// khoe, không được làm hỏng game khi mất mạng hoặc Supabase chưa khởi tạo.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/topup.dart';
import '../state/game_providers.dart';

/// Một thông báo "VIP vừa online".
class VipAnnouncement {
  const VipAnnouncement({
    required this.userId,
    required this.nickname,
    required this.level,
  });

  factory VipAnnouncement.fromRecord(Map<String, dynamic> r) => VipAnnouncement(
        userId: '${r['user_id']}',
        nickname: '${r['nickname']}',
        level: (r['level'] as num?)?.toInt() ?? vipTitleMinLevel,
      );

  final String userId;
  final String nickname;
  final int level;
}

final vipPresenceProvider = Provider<VipPresence>((ref) {
  final presence = VipPresence(ref);
  ref.onDispose(presence.dispose);
  return presence;
});

class VipPresence {
  VipPresence(this._ref);

  final Ref _ref;
  RealtimeChannel? _channel;
  DateTime? _lastShown;

  /// Giãn cách tối thiểu giữa hai banner để một loạt VIP vào cùng lúc không tràn màn.
  static const minBannerGap = Duration(seconds: 20);

  /// Báo mình đang online (chỉ khi đã đủ cấp và có biệt danh). Server tự giới hạn
  /// phát thông báo tối đa 1 lần/giờ/người.
  Future<void> ping() async {
    try {
      final exp = _ref.read(gameControllerProvider).vipExp;
      if (topupVipLevel(exp) < vipTitleMinLevel) return;
      final nickname = _ref
          .read(sharedPreferencesProvider)
          .getString('leaderboard_nickname');
      if (nickname == null || nickname.isEmpty) return;
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) return; // chưa có phiên thì chờ lần reportVip
      await client.rpc('vip_ping', params: {'p_nickname': nickname});
    } catch (_) {}
  }

  /// Nghe thông báo VIP vào game; [onAnnounce] chỉ được gọi cho người KHÁC mình và
  /// không quá dày ([minBannerGap]).
  void listen(void Function(VipAnnouncement) onAnnounce) {
    if (_channel != null) return;
    try {
      final client = Supabase.instance.client;
      _channel = client
          .channel('vip-announcements')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'vip_announcements',
            callback: (payload) {
              final a = VipAnnouncement.fromRecord(payload.newRecord);
              if (a.userId == client.auth.currentUser?.id) return;
              final now = DateTime.now();
              final last = _lastShown;
              if (last != null && now.difference(last) < minBannerGap) return;
              _lastShown = now;
              onAnnounce(a);
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void dispose() {
    final channel = _channel;
    _channel = null;
    if (channel == null) return;
    try {
      Supabase.instance.client.removeChannel(channel);
    } catch (_) {}
  }
}
