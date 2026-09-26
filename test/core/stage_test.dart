import 'dart:math';

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mở khóa giai đoạn', () {
    test('không mua được nguồn thu của giai đoạn chưa mở', () {
      final s = GameState.newGame(nowMillis: 0)..money = 1e9; // stage 1
      // tran_chau thuộc giai đoạn 2.
      expect(buyUpgrade(s, 'tran_chau'), isFalse);
      expect(s.levels['tran_chau'], isNull);
      // tra_den (giai đoạn 1) thì mua được.
      expect(buyUpgrade(s, 'tra_den'), isTrue);
    });

    test('unlockNextStage: đủ tiền thì trừ và lên giai đoạn', () {
      final s = GameState.newGame(nowMillis: 0)..money = 2000;
      expect(unlockNextStage(s), isTrue);
      expect(s.stage, 2);
      expect(s.money, 0);
      // Giờ mua được nguồn thu giai đoạn 2.
      s.money = 100;
      expect(buyUpgrade(s, 'tran_chau'), isTrue);
    });

    test('unlockNextStage: thiếu tiền thì không đổi', () {
      final s = GameState.newGame(nowMillis: 0)..money = 1999;
      expect(unlockNextStage(s), isFalse);
      expect(s.stage, 1);
      expect(s.money, 1999);
    });

    test('unlockNextStage: ở giai đoạn cuối trả false', () {
      final s = GameState.newGame(nowMillis: 0)
        ..stage = 12
        ..money = 1e25;
      expect(unlockNextStage(s), isFalse);
      expect(s.stage, 12);
    });
  });

  group('cấu hình giai đoạn', () {
    test('có đúng 18 giai đoạn, giai đoạn 1 miễn phí', () {
      expect(Balance.stages.length, 18);
      expect(Balance.stageConfig(1).unlockCost, 0);
    });

    test('nextStageConfig trỏ đúng và null ở cuối', () {
      expect(Balance.nextStageConfig(1)!.stage, 2);
      expect(Balance.nextStageConfig(5)!.stage, 6);
      expect(Balance.nextStageConfig(11)!.stage, 12);
      expect(Balance.nextStageConfig(12)!.stage, 13);
      expect(Balance.nextStageConfig(17)!.stage, 18);
      expect(Balance.nextStageConfig(18), isNull);
    });

    test('mỗi generator gắn stage 1..18, mỗi giai đoạn 13-18 có đúng 2 nguồn', () {
      for (final g in Balance.generators) {
        expect(g.stage, inInclusiveRange(1, 18));
      }
      for (var st = 13; st <= 18; st++) {
        expect(Balance.generators.where((g) => g.stage == st).length, 2,
            reason: 'giai đoạn $st');
      }
    });

    test('id nguồn thu không trùng, mở khoá tăng chặt theo giai đoạn', () {
      final ids = Balance.generators.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
      for (var i = 1; i < Balance.stages.length; i++) {
        expect(Balance.stages[i].unlockCost,
            greaterThan(Balance.stages[i - 1].unlockCost));
      }
    });

    test('giá mở tức thì bằng 💎 có đủ bậc cho mọi lần mở giai đoạn', () {
      // Số bậc = số giai đoạn - 1 (mở GĐ2..GĐ18). Thiếu bậc thì clamp cuối
      // danh sách âm thầm dùng giá sai thay vì báo lỗi.
      expect(Balance.instantStageGemCost.length, Balance.stages.length - 1);
      for (var i = 1; i < Balance.instantStageGemCost.length; i++) {
        expect(Balance.instantStageGemCost[i],
            greaterThanOrEqualTo(Balance.instantStageGemCost[i - 1]));
      }
    });

    test('giá ở cấp trần của MỌI nguồn thu còn dưới trần chống tràn số', () {
      // Không tin ước lượng tay: giai đoạn 13-18 (~1e80 ở cấp trần) phải nằm
      // xa dưới economyOverflowGuardCap (1e100) — nếu không giá bị kẹp và
      // "mua thêm cấp" có thể thành miễn phí (bug Xu âm cũ).
      for (final g in Balance.generators) {
        final cost = g.baseCost * pow(g.costGrowth, Balance.maxGeneratorLevel);
        expect(cost, lessThan(Balance.economyOverflowGuardCap / 100),
            reason: '${g.id}: ${cost.toStringAsExponential(1)}');
      }
    });
  });
}
