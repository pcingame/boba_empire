/// "Mời bạn" (referral) — nói chuyện với Supabase qua các RPC trong supabase/referral_schema.sql.
/// Hằng số dưới đây PHẢI khớp SQL (test/referral/referral_sql_test.dart so khớp).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// 💎 người nhập mã nhận ngay; 💎 người mời nhận cho MỖI bạn đã đạt [referralStageNeeded].
const int referralInviteeReward = 100;
const int referralInviterReward = 100;

/// Số lời mời tối đa mỗi người (chặn cày bằng tài khoản ảo).
const int referralMaxInvites = 20;
const int referralStageNeeded = 3;

enum ReferralFailure {
  /// Phải liên kết email (đồng bộ đám mây) trước.
  emailRequired,
  notFound,
  invalidCode,
  alreadyRedeemed,
  inviterFull,
  nothingToClaim,
  network,
}

class ReferralException implements Exception {
  const ReferralException(this.failure);
  final ReferralFailure failure;
  @override
  String toString() => 'ReferralException($failure)';
}

/// Dịch thông điệp RAISE EXCEPTION của RPC sang [ReferralFailure]; lạ/mạng → network.
ReferralFailure referralFailureFromMessage(String message) {
  final m = message.toLowerCase();
  if (m.contains('email required')) return ReferralFailure.emailRequired;
  if (m.contains('not found')) return ReferralFailure.notFound;
  if (m.contains('invalid code')) return ReferralFailure.invalidCode;
  if (m.contains('already redeemed')) return ReferralFailure.alreadyRedeemed;
  if (m.contains('inviter full')) return ReferralFailure.inviterFull;
  if (m.contains('nothing to claim')) return ReferralFailure.nothingToClaim;
  return ReferralFailure.network;
}

class ReferralStatus {
  const ReferralStatus({
    required this.code,
    this.invited = 0,
    this.reached = 0,
    this.claimable = 0,
    this.redeemed = false,
  });

  factory ReferralStatus.fromJson(Map<String, dynamic> j) => ReferralStatus(
        code: j['code'] as String? ?? '',
        invited: (j['invited'] as num?)?.toInt() ?? 0,
        reached: (j['reached'] as num?)?.toInt() ?? 0,
        claimable: (j['claimable'] as num?)?.toInt() ?? 0,
        redeemed: j['redeemed'] == true,
      );

  final String code;

  /// Số bạn đã nhập mã của mình / số bạn đã đạt giai đoạn / số lượt thưởng chưa nhận.
  final int invited;
  final int reached;
  final int claimable;

  /// Chính mình đã nhập mã của ai đó chưa.
  final bool redeemed;
}

abstract interface class ReferralRepository {
  /// Tải trạng thái; tạo mã của mình nếu chưa có.
  Future<ReferralStatus> status();

  /// Nhập mã của người mời; trả số 💎 mình nhận.
  Future<int> redeem(String code);

  /// Nhận thưởng cho mọi bạn đã đạt giai đoạn; trả tổng 💎.
  Future<int> claim();

  /// Báo giai đoạn hiện tại (server chỉ ghi nhận khi đủ [referralStageNeeded]).
  Future<void> reportStage(int stage);
}

class SupabaseReferralRepository implements ReferralRepository {
  const SupabaseReferralRepository(this._client);

  final SupabaseClient _client;

  Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) async {
    // Cần tài khoản đã liên kết email: chưa có phiên thì chưa thể dùng (KHÔNG đăng nhập ẩn danh).
    if (_client.auth.currentUser == null) {
      throw const ReferralException(ReferralFailure.emailRequired);
    }
    try {
      return await _client.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      throw ReferralException(referralFailureFromMessage(e.message));
    } catch (_) {
      throw const ReferralException(ReferralFailure.network);
    }
  }

  @override
  Future<ReferralStatus> status() async {
    await _rpc('referral_my_code'); // tạo mã nếu chưa có
    return ReferralStatus.fromJson(
        await _rpc('referral_status') as Map<String, dynamic>);
  }

  @override
  Future<int> redeem(String code) async =>
      ((await _rpc('referral_redeem', {'p_code': code})) as num).toInt();

  @override
  Future<int> claim() async => ((await _rpc('referral_claim')) as num).toInt();

  @override
  Future<void> reportStage(int stage) =>
      _rpc('referral_report_stage', {'p_stage': stage});
}
