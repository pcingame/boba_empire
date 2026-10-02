import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/market/market_filter.dart';
import 'package:flutter_test/flutter_test.dart';

MarketListing _l(String id, String accessory, int price, int minute) =>
    MarketListing(
      id: id,
      sellerId: 's',
      accessoryId: accessory,
      price: price,
      createdAt: DateTime.utc(2026, 10, 1, 0, minute),
    );

void main() {
  final listings = [
    _l('a', 'mint_leaf', 50, 1), // common, cũ nhất
    _l('b', 'dragon', 900, 2), // legendary
    _l('c', 'cupcake', 20, 3), // common, mới nhất
    _l('x', 'item_from_future', 1, 4), // id lạ
  ];
  List<String> ids(List<MarketListing> l) => l.map((e) => e.id).toList();

  test('mặc định: mới nhất trước, bỏ id lạ', () {
    expect(ids(filterMarketListings(listings)), ['c', 'b', 'a']);
  });

  test('sắp xếp giá thấp -> cao', () {
    expect(ids(filterMarketListings(listings, sort: MarketSort.priceAsc)),
        ['c', 'a', 'b']);
  });

  test('lọc theo độ hiếm', () {
    expect(
        ids(filterMarketListings(listings, rarity: AccessoryRarity.legendary)),
        ['b']);
    expect(ids(filterMarketListings(listings, rarity: AccessoryRarity.epic)),
        isEmpty);
  });

  test('chỉ món chưa có', () {
    expect(
        ids(filterMarketListings(listings,
            missingOnly: true, owned: {'mint_leaf', 'cupcake'})),
        ['b']);
  });

  test('kết hợp: chưa có + giá thấp + độ hiếm; danh sách rỗng không lỗi', () {
    expect(
        ids(filterMarketListings(listings,
            rarity: AccessoryRarity.common,
            missingOnly: true,
            owned: {'mint_leaf'},
            sort: MarketSort.priceAsc)),
        ['c']);
    expect(filterMarketListings(const []), isEmpty);
  });
}
