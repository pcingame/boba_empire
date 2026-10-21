/// Đấu giá cuối tuần: mô hình + gọi RPC `auction_*` (supabase/auction_schema.sql).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

int _int(Object? o, int fallback) => o is num && o.isFinite ? o.toInt() : fallback;

class AuctionInfo {
  const AuctionInfo({
    required this.itemId,
    required this.endsAt,
    required this.open,
    required this.topBid,
    required this.bidCount,
    required this.topIsMe,
    required this.topNick,
    required this.nextMin,
    required this.maxBid,
  });

  factory AuctionInfo.fromJson(Map<String, dynamic> j) => AuctionInfo(
        itemId: j['item_id'] as String? ?? '',
        endsAt: DateTime.tryParse('${j['ends_at']}') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        open: j['open'] == true,
        topBid: _int(j['top_bid'], 0),
        bidCount: _int(j['bid_count'], 0),
        topIsMe: j['top_is_me'] == true,
        topNick: j['top_nick'] as String?,
        nextMin: _int(j['next_min'], 100),
        maxBid: _int(j['max_bid'], 20000),
      );

  final String itemId;
  final DateTime endsAt;
  final bool open;
  final int topBid;
  final int bidCount;
  final bool topIsMe;
  final String? topNick;
  final int nextMin;
  final int maxBid;
}

/// Khoản máy phải nhận: tổng 💎 hoàn + món thắng; [refundIds]/[wonWeeks] để báo lại cho server.
class AuctionPickups {
  const AuctionPickups({this.refundIds = const [], this.refundGems = 0, this.wonWeeks = const [], this.wonItems = const []});

  factory AuctionPickups.fromJson(Map<String, dynamic> j) {
    final r = [for (final e in (j['refunds'] as List? ?? const [])) e as Map<String, dynamic>];
    final w = [for (final e in (j['won'] as List? ?? const [])) e as Map<String, dynamic>];
    return AuctionPickups(
      refundIds: [for (final e in r) e['id'] as String],
      refundGems: r.fold(0, (a, e) => a + _int(e['gems'], 0)),
      wonWeeks: [for (final e in w) e['week'] as String],
      wonItems: [for (final e in w) e['item_id'] as String],
    );
  }

  final List<String> refundIds;
  final int refundGems;
  final List<String> wonWeeks;
  final List<String> wonItems;

  bool get isEmpty => refundIds.isEmpty && wonWeeks.isEmpty;
}

abstract class AuctionRepository {
  Future<AuctionInfo> current();

  /// Ném `bid_too_low` / `auction_closed` / `invalid_bid`.
  Future<void> bid(int gems);
  Future<AuctionPickups> collect();
  Future<void> ack(AuctionPickups p);
}

class SupabaseAuctionRepository implements AuctionRepository {
  SupabaseClient get _c => Supabase.instance.client;

  @override
  Future<AuctionInfo> current() async =>
      AuctionInfo.fromJson(Map<String, dynamic>.from(await _c.rpc('auction_current') as Map));

  @override
  Future<void> bid(int gems) => _c.rpc('auction_bid', params: {'p_gems': gems});

  @override
  Future<AuctionPickups> collect() async =>
      AuctionPickups.fromJson(Map<String, dynamic>.from(await _c.rpc('auction_collect') as Map));

  @override
  Future<void> ack(AuctionPickups p) =>
      _c.rpc('auction_ack', params: {'p_refunds': p.refundIds, 'p_weeks': p.wonWeeks});
}

final auctionRepositoryProvider = Provider<AuctionRepository>((_) => SupabaseAuctionRepository());
