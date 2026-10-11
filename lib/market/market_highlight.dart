/// Listing mới đáng chú ý ở Chợ kể từ lần người chơi mở Chợ gần nhất — cấp
/// dữ liệu cho chấm đỏ ở nút "Thi đấu" và banner ở màn chính. null = không có
/// gì mới (hoặc chưa nối được Supabase — lỗi nuốt im lặng, đây chỉ là điểm
/// nhấn, không được chặn màn chính).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/accessories.dart';
import '../state/game_providers.dart';
import 'accessory_market_repository.dart';

const marketSeenKey = 'market_last_seen_ms';
const marketIntroSeenKey = 'market_intro_seen';

/// Chọn listing nổi bật: món trong danh sách muốn mua [wishlist] luôn thắng, còn lại
/// theo độ hiếm. Bỏ listing của chính mình, listing cũ hơn mốc [seenMs] và id lạ.
MarketListing? pickHighlight(
  List<MarketListing> listings, {
  required String? me,
  required int seenMs,
  Set<String> wishlist = const {},
}) {
  final fresh = listings.where(
    (l) =>
        l.sellerId != me &&
        l.createdAt.millisecondsSinceEpoch > seenMs &&
        accessories.any((a) => a.id == l.accessoryId),
  );
  if (fresh.isEmpty) return null;
  int rank(MarketListing l) =>
      accessoryById(l.accessoryId).rarity.index +
      (wishlist.contains(l.accessoryId) ? 100 : 0);
  return fresh.reduce((a, b) => rank(b) > rank(a) ? b : a);
}

// ponytail: mốc "đã xem" là đồng hồ máy so với created_at của server — lệch
// giờ máy thì chấm đỏ sai nhẹ; đổi sang lưu max(created_at) nếu thành vấn đề.
final marketHighlightProvider = FutureProvider<MarketListing?>((ref) async {
  final seen = ref.watch(sharedPreferencesProvider).getInt(marketSeenKey) ?? 0;
  try {
    final client = Supabase.instance.client;
    final listings = await AccessoryMarketRepository(
      client,
    ).fetchActiveListings();
    return pickHighlight(
      listings,
      me: client.auth.currentUser?.id,
      seenMs: seen,
      wishlist: ref.read(gameControllerProvider).wishlist.toSet(),
    );
  } catch (_) {
    return null;
  }
});
