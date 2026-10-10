import 'dart:io';

import 'package:boba_empire/referral/referral_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hằng số SQL ↔ Dart của "Mời bạn" phải khớp, và đóng đúng các cửa bảo mật.
/// (Hành vi thật của SQL chạy bằng scripts/test_referral_sql.sh trên Postgres.)
void main() {
  final sql = File('supabase/referral_schema.sql').readAsStringSync();

  int constant(String fn) => int.parse(RegExp(
          'function $fn\\(\\) returns integer\\s*'
          r'language sql immutable as \$\$ select (\d+) \$\$')
      .firstMatch(sql)!
      .group(1)!);

  test('hằng số khớp', () {
    expect(constant('referral_invitee_reward'), referralInviteeReward);
    expect(constant('referral_inviter_reward'), referralInviterReward);
    expect(constant('referral_max_invites'), referralMaxInvites);
    expect(constant('referral_stage_needed'), referralStageNeeded);
  });

  test('bảng bật RLS không policy; mọi RPC khoá anon, cấp cho authenticated', () {
    expect(sql, contains('alter table referral_codes enable row level security'));
    expect(sql, contains('alter table referrals enable row level security'));
    expect(sql.contains('create policy'), isFalse);
    for (final f in [
      'referral_my_code()',
      'referral_redeem(text)',
      'referral_report_stage(integer)',
      'referral_status()',
      'referral_claim()',
    ]) {
      expect(sql, contains("'$f'"), reason: f);
    }
    expect(sql, contains("revoke all on function %s from public, anon"));
    expect(sql, contains('to authenticated'));
  });

  test('chặn tài khoản ẩn danh ở mọi RPC cần định danh', () {
    // my_code, redeem, status, claim đều gọi referral_is_real_user().
    expect('referral_is_real_user()'.allMatches(sql).length, greaterThanOrEqualTo(5));
    expect(sql, contains("raise exception 'email required'"));
  });

  test('thông điệp lỗi của SQL đều có ánh xạ ở Dart', () {
    for (final entry in {
      'email required': ReferralFailure.emailRequired,
      'not found': ReferralFailure.notFound,
      'invalid code': ReferralFailure.invalidCode,
      'already redeemed': ReferralFailure.alreadyRedeemed,
      'inviter full': ReferralFailure.inviterFull,
      'nothing to claim': ReferralFailure.nothingToClaim,
    }.entries) {
      expect(sql, contains("raise exception '${entry.key}'"), reason: entry.key);
      expect(referralFailureFromMessage('ERROR: ${entry.key}'), entry.value);
    }
    expect(referralFailureFromMessage('lỗi lạ'), ReferralFailure.network);
  });
}
