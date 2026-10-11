/// Hồ sơ xếp hạng công khai của một người chơi, tra theo tên bằng RPC `player_profile`
/// (supabase/player_profile_schema.sql) — cùng nguồn với thẻ hồ sơ trên web.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Các bảng cá nhân có trong hồ sơ, đúng thứ tự hiển thị. `id` khớp cột `board` của RPC.
enum ProfileBoard { income, pearls, collection, speed, vip }

class ProfileRank {
  const ProfileRank(this.board, this.rank, this.value);
  final ProfileBoard board;
  final int rank;
  final double value;
}

/// Chuyển hàng RPC thành danh sách theo thứ tự [ProfileBoard]; bỏ hàng có `board` lạ (bản server
/// mới hơn) hoặc dữ liệu hỏng.
List<ProfileRank> parseProfileRows(Object? rows) {
  final out = <ProfileRank>[];
  if (rows is! List) return out;
  for (final r in rows) {
    if (r is! Map) continue;
    final board = ProfileBoard.values.where((b) => b.name == r['board']).firstOrNull;
    final rank = r['rank'];
    final value = r['value'];
    if (board == null || rank is! num || value is! num) continue;
    out.add(ProfileRank(board, rank.toInt(), value.toDouble()));
  }
  out.sort((a, b) => a.board.index.compareTo(b.board.index));
  return out;
}

/// Tải hồ sơ của [nickname]. Lỗi mạng / server chưa có hàm → ném lỗi để UI báo.
final playerProfileProvider =
    FutureProvider.autoDispose.family<List<ProfileRank>, String>((ref, nickname) async {
  final rows = await Supabase.instance.client
      .rpc('player_profile', params: {'p_nickname': nickname});
  return parseProfileRows(rows);
}, retry: (_, _) => null);
