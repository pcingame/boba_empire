import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarketListing.fromRow', () {
    test('parse đúng từng trường từ 1 hàng Postgres', () {
      final listing = MarketListing.fromRow({
        'id': 'listing-1',
        'seller_id': 'user-a',
        'accessory_id': 'dragon',
        'price': 500,
        'created_at': '2026-10-01T12:00:00Z',
      });
      expect(listing.id, 'listing-1');
      expect(listing.sellerId, 'user-a');
      expect(listing.accessoryId, 'dragon');
      expect(listing.price, 500);
      expect(listing.createdAt, DateTime.utc(2026, 10, 1, 12));
    });

    test('price kiểu num (Postgres bigint) vẫn ép đúng int', () {
      final listing = MarketListing.fromRow({
        'id': 'listing-2',
        'seller_id': 'user-b',
        'accessory_id': 'cookie',
        'price': 1, // JSON số nguyên nhỏ nhất hợp lệ
        'created_at': '2026-10-01T00:00:00Z',
      });
      expect(listing.price, 1);
      expect(listing.price, isA<int>());
    });
  });

  group('MarketTrade.fromRow', () {
    test('parse đúng từng trường, id là num ép sang int', () {
      final trade = MarketTrade.fromRow({
        'id': 42,
        'buyer_id': 'user-a',
        'seller_id': 'user-b',
        'accessory_id': 'phoenix',
        'price': 999,
        'traded_at': '2026-10-01T08:30:00Z',
      });
      expect(trade.id, 42);
      expect(trade.buyerId, 'user-a');
      expect(trade.sellerId, 'user-b');
      expect(trade.accessoryId, 'phoenix');
      expect(trade.price, 999);
      expect(trade.tradedAt, DateTime.utc(2026, 10, 1, 8, 30));
    });
  });
}
