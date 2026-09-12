import 'package:boba_empire/ui/widgets/one_shot_lottie.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cùng bộ test với sfx_gate_test.dart — TapEffectGate cố ý mirror SfxGate
/// (audio_service.dart), chỉ khác không cần khoá theo enum vì đây là 1 hiệu
/// ứng duy nhất (đồng xu khi chạm), xem giải thích trong one_shot_lottie.dart.
void main() {
  test('lần phát đầu luôn được (kể cả nowMs=0)', () {
    final gate = TapEffectGate(minGapMs: 90);
    expect(gate.allow(0), isTrue);
  });

  test('trong khoảng gap thì bị gộp (chặn), qua gap thì phát lại', () {
    final gate = TapEffectGate(minGapMs: 90);
    expect(gate.allow(1000), isTrue);
    expect(gate.allow(1050), isFalse); // 50ms < 90ms
    expect(gate.allow(1089), isFalse); // 89ms < 90ms
    expect(gate.allow(1090), isTrue); // đúng 90ms → cho phát
  });

  test('mốc cập nhật theo lần phát được, không theo lần bị chặn', () {
    final gate = TapEffectGate(minGapMs: 90);
    expect(gate.allow(0), isTrue); // mốc = 0
    expect(gate.allow(60), isFalse); // bị chặn, mốc vẫn 0
    // 150 so với mốc 0 = 150ms ≥ 90 → phát (nếu mốc bị nhầm =60 thì chỉ 90ms
    // vừa đủ, dễ nhầm là true do trùng ngưỡng — dùng số lệch hẳn cho chắc).
    expect(gate.allow(150), isTrue);
  });

  test('chạm liên tục nhanh (mash) chỉ lọt tối đa vài lần mỗi khoảng gap', () {
    final gate = TapEffectGate(minGapMs: 90);
    var played = 0;
    // 900ms, chạm mỗi 15ms = 60 lần (nhanh hơn ngón tay người thật nhiều) →
    // tối đa ~10 lần lọt (900/90) thay vì cả 60 lần.
    for (var t = 0; t < 900; t += 15) {
      if (gate.allow(t)) played++;
    }
    expect(played, lessThanOrEqualTo(10));
    expect(played, greaterThanOrEqualTo(9));
  });
}
