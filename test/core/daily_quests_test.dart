import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/daily.dart';
import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

const _day = 24 * 60 * 60 * 1000;

GameState _s() => GameState.newGame(nowMillis: 0);

void main() {
  group('dailyQuestsFor', () {
    test('cùng ngày luôn ra cùng bộ (kill/mở lại app không đổi)', () {
      for (final d in [1, 20000, 20456]) {
        final a = dailyQuestsFor(d, 1e6);
        final b = dailyQuestsFor(d, 1e6);
        expect(a.map((q) => q.kind).toList(), b.map((q) => q.kind).toList());
        expect(a.map((q) => q.target).toList(), b.map((q) => q.target).toList());
      }
    });

    test('luôn đủ 3 nhiệm vụ, 3 loại phân biệt', () {
      for (var d = 20000; d < 20200; d++) {
        final list = dailyQuestsFor(d, 1e6);
        expect(list.length, Balance.dailyQuestCount);
        expect(list.map((q) => q.kind).toSet().length, 3, reason: 'ngày $d');
      }
    });

    test('bộ thay đổi giữa các ngày (không kẹt một bộ mãi)', () {
      final sets = {
        for (var d = 20000; d < 20060; d++)
          dailyQuestsFor(d, 1e6).map((q) => q.kind.name).join(','),
      };
      expect(sets.length, greaterThan(5));
    });

    test('ngưỡng Kiếm Xu không ảnh hưởng việc chọn loại; có sàn tối thiểu', () {
      for (var d = 20000; d < 20100; d++) {
        final a = dailyQuestsFor(d, 0);
        final b = dailyQuestsFor(d, 1e40);
        expect(a.map((q) => q.kind).toList(), b.map((q) => q.kind).toList());
        for (final q in a.where((q) => q.kind == DailyQuestKind.earn)) {
          expect(q.target, Balance.dailyEarnMinTarget);
        }
        for (final q in b.where((q) => q.kind == DailyQuestKind.earn)) {
          expect(q.target, 1e40);
        }
      }
    });

    test('ngưỡng chạm/nâng cấp nằm trong khoảng thiết kế', () {
      for (var d = 20000; d < 20200; d++) {
        for (final q in dailyQuestsFor(d, 1e6)) {
          switch (q.kind) {
            case DailyQuestKind.tap:
              expect(q.target, inInclusiveRange(100, 300));
            case DailyQuestKind.buy:
              expect(q.target, inInclusiveRange(10, 40));
            case DailyQuestKind.cat:
            case DailyQuestKind.vip:
            case DailyQuestKind.spin:
              expect(q.target, 1);
            case DailyQuestKind.earn:
              break;
          }
        }
      }
    });
  });

  group('sang ngày', () {
    test('lần đầu sang ngày: đổi bộ, chốt ngưỡng ~30 phút thu nhập', () {
      final s = _s();
      expect(rollDailyQuests(s, 5 * _day, 1000), isTrue);
      expect(s.dailyQuestDay, 5);
      expect(s.dailyEarnTarget, 1000 * Balance.dailyEarnIncomeSeconds);
    });

    test('cùng ngày gọi lại: không reset, không đổi ngưỡng', () {
      final s = _s();
      rollDailyQuests(s, 5 * _day, 1000);
      addDailyProgress(s, DailyQuestKind.tap, 50);
      expect(rollDailyQuests(s, 5 * _day + 1000, 999999), isFalse);
      expect(dailyQuestProgress(s, DailyQuestKind.tap), 50);
      expect(s.dailyEarnTarget, 1000 * Balance.dailyEarnIncomeSeconds);
    });

    test('sang ngày khác: xoá tiến độ + cờ nhận + bonus', () {
      final s = _s();
      rollDailyQuests(s, 5 * _day, 10);
      addDailyProgress(s, DailyQuestKind.tap, 500);
      s
        ..dailyClaimed.add('tap')
        ..dailyBonusClaimed = true;
      expect(rollDailyQuests(s, 6 * _day, 10), isTrue);
      expect(s.dailyProgress, isEmpty);
      expect(s.dailyClaimed, isEmpty);
      expect(s.dailyBonusClaimed, isFalse);
    });

    test('thu nhập 0 hoặc không hữu hạn -> ngưỡng 0 (rồi bị sàn nâng lên)', () {
      final s = _s();
      rollDailyQuests(s, 5 * _day, double.infinity);
      expect(s.dailyEarnTarget, 0);
      final q = currentDailyQuests(s);
      for (final e in q.where((q) => q.kind == DailyQuestKind.earn)) {
        expect(e.target, Balance.dailyEarnMinTarget);
      }
    });
  });

  group('tiến độ & nhận thưởng', () {
    GameState today() {
      final s = _s();
      rollDailyQuests(s, 20000 * _day, 100);
      return s;
    }

    void finish(GameState s, DailyQuest q) =>
        addDailyProgress(s, q.kind, q.target);

    test('chưa xong -> không nhận được', () {
      final s = today();
      expect(claimDailyQuest(s, 0), 0);
      expect(s.gems, 0);
    });

    test('xong thì nhận đúng thưởng, và chỉ một lần', () {
      final s = today();
      final q = currentDailyQuests(s)[0];
      finish(s, q);
      expect(claimDailyQuest(s, 0), q.rewardGems);
      expect(s.gems, q.rewardGems);
      expect(claimDailyQuest(s, 0), 0); // đã nhận
      expect(s.gems, q.rewardGems);
    });

    test('index sai -> 0, không crash', () {
      final s = today();
      expect(claimDailyQuest(s, -1), 0);
      expect(claimDailyQuest(s, 3), 0);
    });

    test('bonus chỉ khi đã nhận đủ cả 3, và chỉ một lần', () {
      final s = today();
      final list = currentDailyQuests(s);
      expect(claimDailyQuestBonus(s), 0);
      for (var i = 0; i < 3; i++) {
        finish(s, list[i]);
        expect(dailyBonusAvailable(s), isFalse);
        claimDailyQuest(s, i);
      }
      expect(dailyBonusAvailable(s), isTrue);
      final before = s.gems;
      expect(claimDailyQuestBonus(s), Balance.dailyQuestBonusGems);
      expect(s.gems, before + Balance.dailyQuestBonusGems);
      expect(claimDailyQuestBonus(s), 0);
    });

    test('dailyClaimableCount đếm nhiệm vụ xong chưa nhận + bonus', () {
      final s = today();
      final list = currentDailyQuests(s);
      expect(dailyClaimableCount(s), 0);
      finish(s, list[0]);
      finish(s, list[1]);
      expect(dailyClaimableCount(s), 2);
      claimDailyQuest(s, 0);
      expect(dailyClaimableCount(s), 1);
      finish(s, list[2]);
      claimDailyQuest(s, 1);
      claimDailyQuest(s, 2);
      expect(dailyClaimableCount(s), 1); // chỉ còn bonus
      claimDailyQuestBonus(s);
      expect(dailyClaimableCount(s), 0);
    });

    test('tổng thưởng tối đa/ngày trong khoảng thiết kế', () {
      // 3 nhiệm vụ (8 hoặc 10) + bonus 15.
      var lo = 1 << 30, hi = 0;
      for (var d = 20000; d < 20200; d++) {
        final t = dailyQuestsFor(d, 1e6).fold<int>(0, (a, q) => a + q.rewardGems) +
            Balance.dailyQuestBonusGems;
        if (t < lo) lo = t;
        if (t > hi) hi = t;
      }
      expect(lo, greaterThanOrEqualTo(39));
      expect(hi, lessThanOrEqualTo(41));
    });
  });

  group('Kiếm Xu đếm qua _credit', () {
    test('chạm, thu nhập, thưởng đều cộng vào tiến độ Kiếm Xu', () {
      final s = _s();
      rollDailyQuests(s, 20000 * _day, 0);
      grantBonus(s, 100);
      tap(s);
      tick(s, 1);
      expect(dailyQuestProgress(s, DailyQuestKind.earn), greaterThanOrEqualTo(101));
    });

    test('offline earnings cũng đếm', () {
      final s = _s()..levels['tra_den'] = 10;
      rollDailyQuests(s, 20000 * _day, 0);
      applyOfflineEarnings(s, 3600 * 1000);
      expect(dailyQuestProgress(s, DailyQuestKind.earn), greaterThan(0));
    });

    test('không bị độ chính xác double nuốt khi lifetime đã ~1e37', () {
      // Bài học Kỷ Nguyên: tiến độ ngày là bộ đếm riêng, reset mỗi ngày.
      final s = _s()..lifetimeEarnings = 1e37;
      rollDailyQuests(s, 20000 * _day, 0);
      for (var i = 0; i < 100; i++) {
        grantBonus(s, 10);
      }
      expect(dailyQuestProgress(s, DailyQuestKind.earn), closeTo(1000, 1e-9));
    });
  });

  group('không bị reset bởi prestige/Kỷ Nguyên', () {
    test('prestige() và ascend() giữ nguyên tiến độ ngày', () {
      final s = _s()
        ..lifetimeEarnings = Balance.ascensionMinLifetime * 4
        ..prestigeStars = 0;
      rollDailyQuests(s, 20000 * _day, 10);
      addDailyProgress(s, DailyQuestKind.tap, 77);
      s.dailyClaimed.add('buy');
      prestige(s);
      ascend(s);
      expect(dailyQuestProgress(s, DailyQuestKind.tap), 77);
      expect(s.dailyClaimed, contains('buy'));
      expect(s.dailyQuestDay, 20000);
    });
  });

  group('save', () {
    test('round-trip JSON giữ nguyên', () {
      final s = _s();
      rollDailyQuests(s, 20000 * _day, 123);
      addDailyProgress(s, DailyQuestKind.tap, 42.5);
      s
        ..dailyClaimed.add('tap')
        ..dailyBonusClaimed = true;
      final b = GameState.fromJson(s.toJson());
      expect(b.dailyQuestDay, 20000);
      expect(b.dailyEarnTarget, s.dailyEarnTarget);
      expect(b.dailyProgress['tap'], 42.5);
      expect(b.dailyClaimed, ['tap']);
      expect(b.dailyBonusClaimed, isTrue);
    });

    test('save cũ thiếu field -> mặc định rỗng, không crash', () {
      final json = _s().toJson()
        ..removeWhere((k, _) => k.startsWith('daily') && k != 'dailyStreak');
      final s = GameState.fromJson(json);
      expect(s.dailyQuestDay, 0);
      expect(s.dailyProgress, isEmpty);
      expect(s.dailyClaimed, isEmpty);
      expect(s.dailyBonusClaimed, isFalse);
      // dailyStreak/lastDailyDay của điểm danh KHÔNG bị nhầm với field mới.
      expect(s.dailyStreak, 0);
    });

    test('không nhầm với điểm danh: dayIndex/dailyAvailable độc lập', () {
      final s = _s();
      rollDailyQuests(s, 20000 * _day, 0);
      expect(dailyAvailable(s, 20000 * _day), isTrue); // chưa nhận điểm danh
    });
  });
}
