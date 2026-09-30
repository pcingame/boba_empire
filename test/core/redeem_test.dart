import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/redeem.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _fresh() => GameState.newGame(nowMillis: 0);

void main() {
  test('mã hợp lệ: cộng gems + đánh dấu đã nhận', () {
    final s = _fresh();
    final r = applyRedeemCode(s, 'xinloi2026', 0); // thường/hoa lẫn lộn vẫn khớp
    expect(r.status, RedeemStatus.success);
    expect(r.gems, redeemCodes['XINLOI2026']!.gems);
    expect(s.gems, redeemCodes['XINLOI2026']!.gems);
    expect(s.redeemedCodes, contains('XINLOI2026'));
  });

  test('mã reviewer: gems + gỡ QC + VIP cùng lúc', () {
    final s = _fresh();
    final r = applyRedeemCode(s, 'REVIEWER2026', 0);
    expect(r.status, RedeemStatus.success);
    expect(s.gems, redeemCodes['REVIEWER2026']!.gems);
    expect(s.adsRemoved, isTrue);
    expect(s.vipUntilMillis, greaterThan(0));
  });

  test('nhận lại cùng mã: báo đã nhận, không cộng thêm', () {
    final s = _fresh();
    applyRedeemCode(s, 'XINLOI2026', 0);
    final gemsAfterFirst = s.gems;
    final r = applyRedeemCode(s, 'XINLOI2026', 0);
    expect(r.status, RedeemStatus.alreadyClaimed);
    expect(s.gems, gemsAfterFirst);
  });

  test('mã không tồn tại: báo không hợp lệ, không cộng gì', () {
    final s = _fresh();
    final r = applyRedeemCode(s, 'KHONGCOMA', 0);
    expect(r.status, RedeemStatus.invalid);
    expect(s.gems, 0);
  });
}
