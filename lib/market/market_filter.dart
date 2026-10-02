/// Lọc + sắp xếp danh sách listing ở tab Chợ — thuần, không đụng UI/mạng.
library;

import '../core/accessories.dart';
import 'accessory_market_repository.dart';

enum MarketSort { newest, priceAsc }

/// [rarity] chỉ giữ món độ hiếm đó; [missingOnly] chỉ giữ món CHƯA có trong
/// [owned]. Listing có id lạ (món của bản app mới hơn) bị loại.
List<MarketListing> filterMarketListings(
  List<MarketListing> listings, {
  AccessoryRarity? rarity,
  bool missingOnly = false,
  Set<String> owned = const {},
  MarketSort sort = MarketSort.newest,
}) {
  final rarityById = {for (final a in accessories) a.id: a.rarity};
  final out = listings.where((l) {
    final r = rarityById[l.accessoryId];
    if (r == null) return false;
    if (rarity != null && r != rarity) return false;
    if (missingOnly && owned.contains(l.accessoryId)) return false;
    return true;
  }).toList();
  out.sort((a, b) {
    if (sort == MarketSort.priceAsc && a.price != b.price) {
      return a.price.compareTo(b.price);
    }
    return b.createdAt.compareTo(a.createdAt);
  });
  return out;
}
