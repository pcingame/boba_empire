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
        ..stage = 6
        ..money = 1e15;
      expect(unlockNextStage(s), isFalse);
      expect(s.stage, 6);
    });
  });

  group('cấu hình giai đoạn', () {
    test('có đúng 6 giai đoạn, giai đoạn 1 miễn phí', () {
      expect(Balance.stages.length, 6);
      expect(Balance.stageConfig(1).unlockCost, 0);
    });

    test('nextStageConfig trỏ đúng và null ở cuối', () {
      expect(Balance.nextStageConfig(1)!.stage, 2);
      expect(Balance.nextStageConfig(5)!.stage, 6);
      expect(Balance.nextStageConfig(6), isNull);
    });

    test('mỗi generator gắn stage 1..6', () {
      for (final g in Balance.generators) {
        expect(g.stage, inInclusiveRange(1, 6));
      }
    });
  });
}
