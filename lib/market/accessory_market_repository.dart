/// Nói chuyện với Supabase cho "Chợ Phụ kiện" — xem
/// PROPOSAL_ACCESSORY_MARKET.md và `supabase/accessory_market_schema.sql`.
///
/// Mọi ghi (đăng bán/mua/huỷ/ghi nhận rớt) đi qua RPC security-definer, RLS
/// chặn insert/update thẳng từ client trên 4 bảng — xem ghi chú đầu file
/// SQL về lý do cần `registerDrop` (lỗ hổng thông đồng 2 tài khoản nếu
/// thiếu). Đọc (listing/ví/lịch sử) dùng select thẳng, được RLS cho phép.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class MarketListing {
  const MarketListing({
    required this.id,
    required this.sellerId,
    required this.accessoryId,
    required this.price,
    required this.createdAt,
  });

  factory MarketListing.fromRow(Map<String, dynamic> row) => MarketListing(
        id: row['id'] as String,
        sellerId: row['seller_id'] as String,
        accessoryId: row['accessory_id'] as String,
        price: (row['price'] as num).toInt(),
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  final String id;
  final String sellerId;
  final String accessoryId;
  final int price;
  final DateTime createdAt;
}

class MarketTrade {
  const MarketTrade({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.accessoryId,
    required this.price,
    required this.tradedAt,
  });

  factory MarketTrade.fromRow(Map<String, dynamic> row) => MarketTrade(
        id: (row['id'] as num).toInt(),
        buyerId: row['buyer_id'] as String,
        sellerId: row['seller_id'] as String,
        accessoryId: row['accessory_id'] as String,
        price: (row['price'] as num).toInt(),
        tradedAt: DateTime.parse(row['traded_at'] as String),
      );

  final int id;
  final String buyerId;
  final String sellerId;
  final String accessoryId;
  final int price;
  final DateTime tradedAt;
}

/// Giao dịch đã khớp, ẩn danh (không có id người mua/bán) — nguồn là RPC công
/// khai `recent_market_trades`.
class RecentSale {
  const RecentSale({required this.accessoryId, required this.price});
  final String accessoryId;
  final int price;
}

/// Giá tham khảo của một món (RPC `accessory_price_stats`); mọi trường có thể
/// null khi chưa có dữ liệu.
class PriceStats {
  const PriceStats({this.lastPrice, this.lowestActive, this.avg7d});
  final int? lastPrice;
  final int? lowestActive;
  final int? avg7d;

  bool get isEmpty => lastPrice == null && lowestActive == null;
}

class AccessoryMarketRepository {
  AccessoryMarketRepository(this._client);

  final SupabaseClient _client;

  static const _walletsTable = 'accessory_wallets';
  static const _listingsTable = 'accessory_listings';
  static const _tradesTable = 'accessory_market_trades';
  static const _ownershipTable = 'accessory_server_ownership';

  Future<String> ensureSignedIn() async {
    final existing = _client.auth.currentUser;
    if (existing != null) return existing.id;
    final res = await _client.auth.signInAnonymously();
    final user = res.user;
    if (user == null) {
      throw StateError('Đăng nhập ẩn danh Supabase thất bại (user null).');
    }
    return user.id;
  }

  /// Ghi nhận 1 món vừa rớt hợp lệ — gọi lúc rớt món MỚI (game_controller.dart)
  /// HOẶC lúc đối chiếu lần đầu mở Chợ (bù món có từ trước khi Chợ ra đời).
  /// An toàn gọi lại nhiều lần.
  Future<void> registerDrop(String accessoryId, {int copies = 1}) async {
    await ensureSignedIn();
    await _client.rpc(
      'register_accessory_copies',
      params: {'p_accessory_id': accessoryId, 'p_copies': copies},
    );
  }

  /// Id phụ kiện server đã xác nhận sở hữu (không gồm món đang đăng bán —
  /// xem list_accessory trong SQL, món rời accessory_server_ownership ngay
  /// lúc đăng). Dùng để đối chiếu với `GameState.ownedAccessories` local lúc
  /// mở Chợ lần đầu (xem AccessoryMarketController.reconcileOwnership).
  Future<Map<String, int>> fetchServerCopies() async {
    final uid = await ensureSignedIn();
    final rows = await _client
        .from(_ownershipTable)
        .select('accessory_id, copies')
        .eq('user_id', uid);
    return {
      for (final r in rows as List)
        (r as Map<String, dynamic>)['accessory_id'] as String:
            (r['copies'] as num).toInt(),
    };
  }

  Future<int> fetchWalletBalance() async {
    final uid = await ensureSignedIn();
    final row = await _client
        .from(_walletsTable)
        .select('balance')
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return 0;
    return (row['balance'] as num).toInt();
  }

  Future<List<MarketListing>> fetchActiveListings({int limit = 50}) async {
    final rows = await _client
        .from(_listingsTable)
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => MarketListing.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<MarketListing>> fetchMyActiveListings() async {
    final uid = await ensureSignedIn();
    final rows = await _client
        .from(_listingsTable)
        .select()
        .eq('seller_id', uid)
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => MarketListing.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<MarketTrade>> fetchMyTrades({int limit = 50}) async {
    final uid = await ensureSignedIn();
    final rows = await _client
        .from(_tradesTable)
        .select()
        .or('buyer_id.eq.$uid,seller_id.eq.$uid')
        .order('traded_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => MarketTrade.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Trả về id listing vừa tạo. Ném lỗi `not_owned` (PostgrestException) nếu
  /// server không thấy món này trong accessory_server_ownership của mình —
  /// UI nên gợi ý "Đối chiếu lại" (gọi lại registerDrop) thay vì chỉ báo lỗi
  /// chung chung.
  Future<String> listAccessory(String accessoryId, int price) async {
    await ensureSignedIn();
    final id =
        await _client.rpc(
              'list_accessory',
              params: {'p_accessory_id': accessoryId, 'p_price': price},
            )
            as String;
    return id;
  }

  Future<void> cancelListing(String listingId) async {
    await ensureSignedIn();
    await _client
        .rpc('cancel_listing', params: {'p_listing_id': listingId});
  }

  /// Ném `insufficient_balance`/`listing_not_active`/`cannot_buy_own_listing`
  /// (PostgrestException) — UI tự dịch sang thông báo phù hợp.
  Future<void> buyListing(String listingId) async {
    await ensureSignedIn();
    await _client.rpc('buy_listing', params: {'p_listing_id': listingId});
  }

  /// Gói Khởi Nghiệp (1 lần/tài khoản). Ném PostgrestException với message
  /// `already_claimed` / `not_eligible` / `daily_cap`.
  Future<void> claimStarterPack(String accessoryId, int stage) async {
    await ensureSignedIn();
    await _client.rpc('claim_starter_pack', params: {
      'p_accessory_id': accessoryId,
      'p_stage': stage,
      'p_quests': 1, // ponytail: cờ dailyQuestEverClaimed, không đếm thật
    });
  }

  /// Nhận thưởng mốc sưu tập; trả số Xu Chợ. Ném PostgrestException với message
  /// `invalid_milestone` / `not_reached` / `already_claimed`.
  Future<int> claimCollectionMilestone(int milestone) async {
    await ensureSignedIn();
    final coins = await _client
        .rpc('claim_collection_milestone', params: {'p_milestone': milestone});
    return (coins as num).toInt();
  }

  /// Nạp [amount] Xu Chợ — MỘT CHIỀU, không có hàm ngược (xem PROPOSAL §0).
  /// Gọi SAU KHI đã chắc chắn sẽ trừ Xu/💎 cục bộ (GameController tự trừ
  /// nếu lệnh này thành công, xem convertGemsToMarketCoins/
  /// convertMoneyToMarketCoins) — gọi trước rồi mới trừ cục bộ để tránh mất
  /// Xu/💎 oan nếu lỗi mạng giữa chừng.
  Future<void> creditMarketCoins(int amount) async {
    await ensureSignedIn();
    await _client.rpc('credit_market_coins', params: {'p_amount': amount});
  }

  Future<List<RecentSale>> fetchRecentSales({int limit = 10}) async {
    final rows = await _client.rpc(
      'recent_market_trades',
      params: {'p_limit': limit},
    );
    return (rows as List)
        .map(
          (r) => RecentSale(
            accessoryId: (r as Map<String, dynamic>)['accessory_id'] as String,
            price: (r['price'] as num).toInt(),
          ),
        )
        .toList();
  }

  Future<PriceStats> fetchPriceStats(String accessoryId) async {
    final rows = await _client
        .rpc('accessory_price_stats', params: {'p_accessory_id': accessoryId});
    final list = rows as List;
    if (list.isEmpty) return const PriceStats();
    final r = list.first as Map<String, dynamic>;
    int? n(String k) => (r[k] as num?)?.toInt();
    return PriceStats(
      lastPrice: n('last_price'),
      lowestActive: n('lowest_active'),
      avg7d: n('avg_7d'),
    );
  }

  /// user_id người bán nhiều nhất 7 ngày qua, null nếu tuần này chưa có giao dịch.
  Future<String?> fetchWeeklyTopSeller() async {
    final id = await _client.rpc('market_weekly_top_seller');
    return id as String?;
  }

  /// Đăng ký token FCM của máy này cho người dùng hiện tại (server dùng để đẩy
  /// thông báo khi món bán được).
  Future<void> registerPushToken(
      String token, String platform, String locale) async {
    await ensureSignedIn();
    await _client.rpc('register_push_token', params: {
      'p_token': token,
      'p_platform': platform,
      'p_locale': locale,
    });
  }
}
