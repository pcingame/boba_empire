import 'package:boba_empire/audio/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lần phát đầu luôn được (kể cả nowMs=0)', () {
    final gate = SfxGate(minGapMs: 60);
    expect(gate.allow(Sfx.tap, 0), isTrue);
  });

  test('trong khoảng gap thì bị gộp (chặn), qua gap thì phát lại', () {
    final gate = SfxGate(minGapMs: 60);
    expect(gate.allow(Sfx.buy, 1000), isTrue);
    expect(gate.allow(Sfx.buy, 1030), isFalse); // 30ms < 60ms
    expect(gate.allow(Sfx.buy, 1059), isFalse); // 59ms < 60ms
    expect(gate.allow(Sfx.buy, 1060), isTrue); // đúng 60ms → cho phát
  });

  test('mốc cập nhật theo lần phát được, không theo lần bị chặn', () {
    final gate = SfxGate(minGapMs: 60);
    expect(gate.allow(Sfx.tap, 0), isTrue); // mốc = 0
    expect(gate.allow(Sfx.tap, 50), isFalse); // bị chặn, mốc vẫn 0
    // 100 so với mốc 0 = 100ms ≥ 60 → phát (nếu mốc bị nhầm =50 thì chỉ 50ms<60).
    expect(gate.allow(Sfx.tap, 100), isTrue);
  });

  test('mỗi SFX có mốc riêng, không chặn lẫn nhau', () {
    final gate = SfxGate(minGapMs: 60);
    expect(gate.allow(Sfx.tap, 1000), isTrue);
    expect(gate.allow(Sfx.buy, 1000), isTrue); // khác loại → không bị gộp
    expect(gate.allow(Sfx.tap, 1010), isFalse); // cùng tap, trong gap
  });

  test('spam dày đặc chỉ lọt tối đa 1 lần mỗi khoảng gap', () {
    final gate = SfxGate(minGapMs: 60);
    var played = 0;
    // 600ms, click mỗi 10ms = 60 lần → tối đa ~10 lần lọt (600/60).
    for (var t = 0; t < 600; t += 10) {
      if (gate.allow(Sfx.buy, t)) played++;
    }
    expect(played, lessThanOrEqualTo(10));
    expect(played, greaterThanOrEqualTo(9));
  });
}
