import 'dart:math';

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/rival.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _active({double pressure = 0, int stage = 3}) => GameState.newGame(
      nowMillis: 0,
    )
  ..storyChapter = 3
  ..stage = stage
  ..rivalPressureSeconds = pressure;

void main() {
  group('rivalPower', () {
    test('0 khi đối thủ chưa vào truyện', () {
      final s = GameState.newGame(nowMillis: 0)..rivalPressureSeconds = 9999;
      expect(rivalPower(s), 0);
    });

    test('= sqrt(pressure) · k, đơn điệu tăng', () {
      final a = _active(pressure: 400);
      final b = _active(pressure: 1600);
      expect(rivalPower(a), closeTo(20 * Balance.rivalPowerK, 1e-9));
      expect(rivalPower(b), greaterThan(rivalPower(a)));
    });

    test('0 sau khi bị hạ', () {
      final s = _active(pressure: 400)..rivalDefeated = true;
      expect(rivalPower(s), 0);
    });
  });

  group('rivalStanding', () {
    test('ahead khi sức ép thấp', () {
      expect(rivalStanding(_active(pressure: 0)), RivalStanding.ahead);
    });

    test('behind khi vượt ngưỡng', () {
      // stage 3 kỳ vọng 60; behind khi power > 72 → pressure > 72^2.
      final s = _active(pressure: pow(72 * 1.01, 2).toDouble());
      expect(rivalStanding(s), RivalStanding.behind);
    });

    test('even ở khoảng giữa', () {
      // power ~ 60 (= kỳ vọng) → ratio 1.0 → even.
      final s = _active(pressure: 3600);
      expect(rivalStanding(s), RivalStanding.even);
    });
  });

  group('rivalDefeatable', () {
    test('chỉ đúng ở giai đoạn 6 và đang dẫn trước', () {
      expect(rivalDefeatable(_active(stage: 5)), isFalse);
      expect(rivalDefeatable(_active(stage: 6)), isTrue);
      final behind = _active(stage: 6, pressure: pow(200, 2).toDouble());
      expect(rivalDefeatable(behind), isFalse);
    });

    test('false nếu đã bị hạ rồi', () {
      final s = _active(stage: 6)..rivalDefeated = true;
      expect(rivalDefeatable(s), isFalse);
    });
  });

  group('rivalOptions / outcome', () {
    test('option 0 trả % Xu, đẩy lùi; option 1 trả 💎 + buff', () {
      final s = _active()..money = 1000;
      final opts = rivalOptions(s, RivalEventType.priceWar);
      expect(opts[0].spendMoney, closeTo(100, 1e-9)); // 10% của 1000
      expect(opts[0].spendGems, 0);
      expect(opts[0].pressureDelta, lessThan(0));
      expect(opts[1].spendGems, greaterThan(0));
      expect(opts[1].modifierMult, greaterThan(1.0));
      expect(opts[1].modifierSeconds, greaterThan(0));
    });

    test('affordableFor kiểm tra cả Xu lẫn 💎', () {
      final poor = _active()..money = 10;
      final opts = rivalOptions(poor, RivalEventType.poachStaff);
      expect(opts[1].affordableFor(poor), isFalse); // thiếu 💎
      final rich = _active()
        ..money = 10000
        ..gems = 100;
      expect(rivalOptions(rich, RivalEventType.poachStaff)[1]
          .affordableFor(rich), isTrue);
    });

    test('phớt lờ: sức ép tăng + debuff', () {
      expect(rivalIgnoreOutcome.pressureDelta,
          Balance.rivalIgnorePressureSeconds);
      expect(rivalIgnoreOutcome.modifierMult, lessThan(1.0));
    });
  });
}
