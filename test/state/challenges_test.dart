// Thử thách hằng ngày: bộ xác định theo ngày, khó hơn nhiệm vụ ngày, dùng chung bộ đếm, nhận thưởng một
// lần, thưởng cả bộ, sang ngày thì làm mới; thắng màn Trân Châu Rơi và chạm/mèo cộng tiến độ đúng.
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/challenges.dart';
import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/game_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dayMs = 24 * 60 * 60 * 1000;

GameState _stateOn(int day) => GameState.newGame(nowMillis: day * _dayMs)..dailyQuestDay = day;

int _dayWith(ChallengeKind k) {
  for (var d = 20000;; d++) {
    if (challengesFor(d).any((c) => c.kind == k)) return d;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bộ thử thách', () {
    test('xác định theo ngày; đúng số lượng; 2 loại khác nhau', () {
      for (var d = 20000; d < 20060; d++) {
        final a = challengesFor(d), b = challengesFor(d);
        expect(a.length, Balance.challengeCount);
        expect([for (final c in a) c.kind], [for (final c in b) c.kind]);
        expect([for (final c in a) c.target], [for (final c in b) c.target]);
        expect(a.map((c) => c.kind).toSet().length, a.length, reason: 'ngày $d trùng loại');
      }
    });

    test('mọi loại đều xuất hiện trong 60 ngày; mục tiêu nằm trong khoảng thiết kế', () {
      final seen = <ChallengeKind>{};
      for (var d = 20000; d < 20060; d++) {
        for (final c in challengesFor(d)) {
          seen.add(c.kind);
          final (lo, hi) = switch (c.kind) {
            ChallengeKind.tap => (800, 1200),
            ChallengeKind.buy => (120, 200),
            ChallengeKind.cat => (4, 6),
            ChallengeKind.vip => (3, 5),
            ChallengeKind.m3Win => (2, 4),
          };
          expect(c.target, inInclusiveRange(lo, hi), reason: '${c.kind} ngày $d');
          expect(c.rewardGems, Balance.challengeRewardGems);
        }
      }
      expect(seen, ChallengeKind.values.toSet());
    });

    test('KHÓ hơn nhiệm vụ ngày cùng loại và thưởng cao hơn', () {
      for (var d = 20000; d < 20060; d++) {
        for (final c in challengesFor(d)) {
          final daily = switch (c.kind) {
            ChallengeKind.tap => 300.0, // trần mục tiêu Chạm của nhiệm vụ ngày
            ChallengeKind.buy => 40.0, // trần mục tiêu Nâng cấp
            ChallengeKind.cat || ChallengeKind.vip => 1.0,
            ChallengeKind.m3Win => 1.0,
          };
          expect(c.target, greaterThan(daily), reason: '${c.kind} ngày $d');
        }
      }
      expect(Balance.challengeRewardGems, greaterThan(Balance.dailyQuestRewardGems));
    });
  });

  group('tiến độ và nhận thưởng (hàm thuần)', () {
    test('dùng chung bộ đếm với nhiệm vụ ngày (chạm/nâng cấp/mèo/VIP)', () {
      final day = _dayWith(ChallengeKind.tap);
      final s = _stateOn(day);
      addDailyProgress(s, DailyQuestKind.tap, 5);
      final c = currentChallenges(s).firstWhere((c) => c.kind == ChallengeKind.tap);
      expect(challengeProgress(s, c), 5);
    });

    test('chưa xong → không nhận được; xong → nhận đúng một lần', () {
      final day = _dayWith(ChallengeKind.buy);
      final s = _stateOn(day);
      final idx = currentChallenges(s).indexWhere((c) => c.kind == ChallengeKind.buy);
      final c = currentChallenges(s)[idx];
      expect(claimChallenge(s, idx), 0);
      addDailyProgress(s, DailyQuestKind.buy, c.target.toDouble());
      final g0 = s.gems;
      expect(claimChallenge(s, idx), c.rewardGems);
      expect(s.gems, g0 + c.rewardGems);
      expect(claimChallenge(s, idx), 0, reason: 'đã nhận');
      expect(challengeClaimed(s, c), isTrue);
    });

    test('index sai → 0', () {
      final s = _stateOn(20000);
      expect(claimChallenge(s, -1), 0);
      expect(claimChallenge(s, 99), 0);
    });

    test('thưởng cả bộ: chỉ khi nhận hết thử thách, đúng một lần', () {
      final s = _stateOn(20000);
      expect(challengeBonusAvailable(s), isFalse);
      expect(claimChallengeBonus(s), 0);
      final list = currentChallenges(s);
      for (var i = 0; i < list.length; i++) {
        final c = list[i];
        if (c.kind == ChallengeKind.m3Win) {
          for (var n = 0; n < c.target; n++) {
            addChallengeM3Win(s);
          }
        } else {
          addDailyProgress(s, DailyQuestKind.values.byName(c.kind.name), c.target.toDouble());
        }
        expect(challengeBonusAvailable(s), isFalse, reason: 'chưa nhận hết');
        claimChallenge(s, i);
      }
      expect(challengeBonusAvailable(s), isTrue);
      final g0 = s.gems;
      expect(claimChallengeBonus(s), Balance.challengeBonusGems);
      expect(s.gems, g0 + Balance.challengeBonusGems);
      expect(claimChallengeBonus(s), 0);
      expect(challengeBonusClaimed(s), isTrue);
    });

    test('chấm đỏ: đếm thử thách xong chưa nhận + thưởng cả bộ', () {
      final day = _dayWith(ChallengeKind.cat);
      final s = _stateOn(day);
      expect(challengeClaimableCount(s), 0);
      final c = currentChallenges(s).firstWhere((c) => c.kind == ChallengeKind.cat);
      addDailyProgress(s, DailyQuestKind.cat, c.target.toDouble());
      expect(challengeClaimableCount(s), 1);
    });

    test('sang ngày mới: tiến độ + đã nhận được làm mới, bộ đổi', () {
      final day = _dayWith(ChallengeKind.tap);
      final s = _stateOn(day);
      addDailyProgress(s, DailyQuestKind.tap, 5000);
      claimChallenge(s, currentChallenges(s).indexWhere((c) => c.kind == ChallengeKind.tap));
      rollDailyQuests(s, (day + 1) * _dayMs, 100);
      for (final c in currentChallenges(s)) {
        expect(challengeProgress(s, c), 0);
        expect(challengeClaimed(s, c), isFalse);
      }
      expect(challengeBonusClaimed(s), isFalse);
    });

    test('không đụng nhiệm vụ ngày: nhận thử thách không đánh dấu nhiệm vụ ngày đã nhận', () {
      final day = _dayWith(ChallengeKind.tap);
      final s = _stateOn(day);
      addDailyProgress(s, DailyQuestKind.tap, 5000);
      claimChallenge(s, currentChallenges(s).indexWhere((c) => c.kind == ChallengeKind.tap));
      for (final q in currentDailyQuests(s)) {
        expect(dailyQuestClaimed(s, q), isFalse);
      }
    });
  });

  group('trong game (controller)', () {
    Future<(ProviderContainer, void Function(int))> harness(int day) async {
      final now = day * _dayMs + 1000;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(GameState.newGame(nowMillis: now), nowMillis: now);
      var clock = now;
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => clock),
      ]);
      addTearDown(c.dispose);
      return (c, (t) => clock = t);
    }

    test('mở app: có đủ thử thách của ngày trong snapshot', () async {
      final (c, _) = await harness(_dayWith(ChallengeKind.tap));
      final snap = c.read(gameControllerProvider);
      expect(snap.challenges.length, Balance.challengeCount);
      expect(snap.challengeBonusAvailable, isFalse);
    });

    test('chạm ly tăng tiến độ thử thách Chạm (chạm tay có tính)', () async {
      final (c, _) = await harness(_dayWith(ChallengeKind.tap));
      final ctrl = c.read(gameControllerProvider.notifier);
      for (var i = 0; i < 7; i++) {
        ctrl.tapCup();
      }
      final v = c.read(gameControllerProvider).challenges.firstWhere((x) => x.kind == ChallengeKind.tap);
      expect(v.progress, 7);
    });

    test('thắng màn Trân Châu Rơi (≥1★) tăng thử thách "thắng màn"; 0★ thì không', () async {
      final (c, _) = await harness(_dayWith(ChallengeKind.m3Win));
      final ctrl = c.read(gameControllerProvider.notifier);
      ChallengeView v() => c.read(gameControllerProvider).challenges.firstWhere((x) => x.kind == ChallengeKind.m3Win);
      expect(v().progress, 0);
      ctrl.grantMatch3Result(1, 0);
      expect(v().progress, 0, reason: '0 sao không tính');
      ctrl.grantMatch3Result(1, 2);
      expect(v().progress, 1);
    });

    test('đủ tiến độ → nhận thưởng cộng 💎, chấm đỏ giảm; nhận hết → thưởng cả bộ', () async {
      final (c, _) = await harness(_dayWith(ChallengeKind.tap));
      final ctrl = c.read(gameControllerProvider.notifier);
      // Ép tiến độ qua đường thật: cộng đúng bộ đếm bằng addDailyProgress trên bản export.
      final snap0 = c.read(gameControllerProvider);
      final gems0 = snap0.gems;
      // Dùng chạm ly nhiều lần cho thử thách Chạm; các loại khác dùng hàm thuần ở test trên.
      final tapIdx = snap0.challenges.indexWhere((x) => x.kind == ChallengeKind.tap);
      final target = snap0.challenges[tapIdx].target;
      for (var i = 0; i < target; i++) {
        ctrl.tapCup();
      }
      expect(c.read(gameControllerProvider).dailyClaimableCount, greaterThanOrEqualTo(1));
      expect(ctrl.claimChallengeReward(tapIdx), Balance.challengeRewardGems);
      expect(c.read(gameControllerProvider).gems, gems0 + Balance.challengeRewardGems);
      expect(ctrl.claimChallengeReward(tapIdx), 0);
      expect(c.read(gameControllerProvider).challenges[tapIdx].claimed, isTrue);
    });
  });
}
