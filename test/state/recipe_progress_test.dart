// Bậc thuộc công thức qua controller: thưởng chỉ lần đầu đạt bậc mới, chống cày, lưu bền, save hỏng.
import 'dart:convert';

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/daily.dart';
import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/weekly_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/recipe_orders.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

Future<(ProviderContainer, SharedPreferences, void Function(int) setDay)> _harness(GameState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  var now = 100 * _day;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return (c, prefs, (int d) => now = d * _day);
}

GameState _game(ProviderContainer c) => c.read(gameControllerProvider.notifier).debugGame;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lần đầu đúng: lên bậc 1, thưởng Xu (sàn 5 lần chạm), chưa có 💎', () async {
    final (c, _, _) = await _harness(GameState.newGame(nowMillis: 0));
    final ctrl = c.read(gameControllerProvider.notifier);
    final r = ctrl.answerRecipe(1, true);
    expect(r.after.box, 1);
    expect(r.outcome.newBest, isTrue);
    expect(r.cash, closeTo(recipeRewardFloorTaps[1] * 1.0, 1e-9)); // chưa có thu nhập → sàn
    expect(r.gems, 0);
    final snap = c.read(gameControllerProvider);
    expect(snap.money, closeTo(r.cash, 1e-9));
    expect(snap.recipeProgress[1]!.box, 1);
    expect(snap.recipeProgress[1]!.dueDay, 100 + recipeIntervalDays[1]);
  });

  test('thưởng theo giây sản xuất khi có thu nhập (lấy giá trị lớn hơn sàn)', () async {
    // tra_den cấp 2 = 1 Xu/s → 30s = 30 Xu > sàn 5.
    final (c, _, _) = await _harness(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2);
    final r = c.read(gameControllerProvider.notifier).answerRecipe(3, true);
    expect(r.cash, closeTo(recipeRewardSeconds[1] * 1.0, 1e-9));
  });

  test('CHỐNG CÀY: trả lời tiếp cùng món khi chưa tới hạn không đổi bậc, không thưởng thêm', () async {
    final (c, _, _) = await _harness(GameState.newGame(nowMillis: 0));
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.answerRecipe(1, true);
    final money = c.read(gameControllerProvider).money;
    for (var i = 0; i < 5; i++) {
      final r = ctrl.answerRecipe(1, true);
      expect(r.outcome.counted, isFalse);
      expect(r.cash, 0);
    }
    expect(c.read(gameControllerProvider).money, money);
    expect(c.read(gameControllerProvider).recipeProgress[1]!.box, 1);
  });

  test('đến Thạo: +💎 đúng một lần; sai rồi đúng lại không thưởng lần hai', () async {
    final (c, _, setDay) = await _harness(GameState.newGame(nowMillis: 0));
    final ctrl = c.read(gameControllerProvider.notifier);
    var day = 100;
    var gems = 0;
    for (var step = 0; step < 3; step++) {
      setDay(day);
      final r = ctrl.answerRecipe(7, true);
      gems += r.gems;
      day += recipeIntervalDays[r.after.box];
    }
    expect(c.read(gameControllerProvider).recipeProgress[7]!.box, recipeMaxBox);
    expect(gems, recipeMaxBoxGems);
    expect(c.read(gameControllerProvider).gems, recipeMaxBoxGems);

    // Sai (xuống Thuộc) rồi đúng lại (lên Thạo) khi đã tới hạn: không thưởng nữa.
    setDay(day);
    final wrong = ctrl.answerRecipe(7, false);
    expect(wrong.after.box, recipeMaxBox - 1);
    final money = c.read(gameControllerProvider).money;
    final again = ctrl.answerRecipe(7, true);
    expect(again.after.box, recipeMaxBox);
    expect((again.cash, again.gems), (0.0, 0));
    expect(c.read(gameControllerProvider).gems, recipeMaxBoxGems);
    expect(c.read(gameControllerProvider).money, money);
  });

  test('lưu bền: mở lại app (container mới, cùng prefs) vẫn giữ bậc', () async {
    final (c, prefs, _) = await _harness(GameState.newGame(nowMillis: 0));
    c.read(gameControllerProvider.notifier).answerRecipe(2, true);
    await Future<void>.delayed(const Duration(milliseconds: 50)); // saveNow chạy nền
    c.dispose();
    final c2 = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 100 * _day),
    ]);
    addTearDown(c2.dispose);
    expect(c2.read(gameControllerProvider).recipeProgress[2]!.box, 1);
  });

  group('JSON', () {
    test('vòng lưu/đọc giữ nguyên; save cũ không có trường → rỗng; mục hỏng bị bỏ, không ném', () {
      final g = GameState.newGame(nowMillis: 0)..recipeProgress['5'] = [2, 9, 3];
      final back = GameState.fromJson(jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>);
      expect(back.recipeProgress, {'5': [2, 9, 3]});

      final old = g.toJson()..remove('recipeProgress');
      expect(GameState.fromJson(jsonDecode(jsonEncode(old)) as Map<String, dynamic>).recipeProgress, isEmpty);

      final bad = g.toJson()..['recipeProgress'] = {'1': 'x', 'a': [1], '2': [1, 'q', null]};
      final loaded = GameState.fromJson(jsonDecode(jsonEncode(bad)) as Map<String, dynamic>);
      expect(loaded.recipeProgress.containsKey('1'), isFalse);
      expect(RecipeProgress.fromList(loaded.recipeProgress['2']!).toList(), [1, 0, 1]);
      // Snapshot bỏ khoá không phải số (id lạ từ cloud).
    });

    test('snapshot bỏ id không phải số và không chia sẻ Map với GameState', () async {
      final (c, _, _) = await _harness(GameState.newGame(nowMillis: 0)..recipeProgress['zzz'] = [1, 0, 1]..recipeProgress['4'] = [1, 0, 1]);
      final snap = c.read(gameControllerProvider);
      expect(snap.recipeProgress.keys, [4]);
      c.read(gameControllerProvider.notifier).answerRecipe(4, true);
      expect(snap.recipeProgress[4]!.box, 1); // bản chụp cũ không bị đổi theo
      expect(c.read(gameControllerProvider).recipeProgress[4]!.box, 2);
    });
  });

  test('dayIndex dùng đúng đồng hồ bơm (kiểm giả định của test)', () {
    expect(dayIndex(100 * _day), 100);
  });

  group('gợi ý, buổi luyện, nhân đôi', () {
    test('câu dùng gợi ý: không đổi bậc, không thưởng, không tính', () async {
      final (c, _, _) = await _harness(GameState.newGame(nowMillis: 0));
      final ctrl = c.read(gameControllerProvider.notifier);
      final r = ctrl.answerRecipe(1, true, hinted: true);
      expect((r.outcome.counted, r.cash, r.gems), (false, 0.0, 0));
      expect(r.after.box, 0);
      expect(c.read(gameControllerProvider).money, 0);
      expect(c.read(gameControllerProvider).recipeProgress, isEmpty);
      // Không có gợi ý thì cùng câu đó lên bậc bình thường (gợi ý không "ăn" lượt của món).
      expect(ctrl.answerRecipe(1, true).after.box, 1);
    });

    test('completeRecipeSession: chỉ tính khi có câu được tính bậc; cộng nhiệm vụ ngày + tuần', () async {
      final (c, _, _) = await _harness(GameState.newGame(nowMillis: 0));
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.completeRecipeSession(anyCounted: false); // toàn câu chỉ luyện/gợi ý
      var g = _game(c);
      expect(g.dailyProgress[DailyQuestKind.recipe.name], isNull);
      expect(g.weeklyProgress[WeeklyQuestKind.recipeSessions.name], isNull);
      ctrl.completeRecipeSession(anyCounted: true);
      g = _game(c);
      expect(g.dailyProgress[DailyQuestKind.recipe.name], 1.0);
      expect(g.weeklyProgress[WeeklyQuestKind.recipeSessions.name], 1.0);
    });

    test('lên bậc cộng tiến độ tuần "recipeLevels"; câu không lên bậc thì không', () async {
      final (c, _, _) = await _harness(GameState.newGame(nowMillis: 0));
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.answerRecipe(1, false);
      expect(_game(c).weeklyProgress[WeeklyQuestKind.recipeLevels.name], isNull);
      ctrl.answerRecipe(1, true); // 0 → 1
      ctrl.answerRecipe(2, true);
      expect(_game(c).weeklyProgress[WeeklyQuestKind.recipeLevels.name], 2.0);
      ctrl.answerRecipe(1, true); // chưa tới hạn: không đổi
      expect(_game(c).weeklyProgress[WeeklyQuestKind.recipeLevels.name], 2.0);
    });

    test('doubleRecipeReward: cộng đúng số Xu; số xấu (0, âm, vô cực, NaN) bị bỏ qua', () async {
      final (c, _, _) = await _harness(GameState.newGame(nowMillis: 0));
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.doubleRecipeReward(12.5);
      expect(c.read(gameControllerProvider).money, closeTo(12.5, 1e-9));
      for (final bad in [0.0, -5.0, double.infinity, double.nan]) {
        ctrl.doubleRecipeReward(bad);
      }
      expect(c.read(gameControllerProvider).money, closeTo(12.5, 1e-9));
    });
  });

  group('rương phụ kiện theo mốc số món Thạo', () {
    /// [mastered] món (id 1..mastered) đã từng Thạo; món [target] ở bậc Thuộc, đến hạn, best=2.
    GameState seed(int mastered, {int target = 20, List<int> claimed = const []}) {
      final g = GameState.newGame(nowMillis: 0);
      for (var id = 1; id <= mastered; id++) {
        g.recipeProgress['$id'] = [3, 9999, 3];
      }
      g.recipeProgress['$target'] = [2, 0, 2];
      g.recipeMilestonesClaimed.addAll(claimed);
      return g;
    }

    test('món Thạo thứ 5 → 1 phụ kiện Hiếm, đúng một lần; món thứ 6 không có thêm', () async {
      final (c, _, _) = await _harness(seed(4));
      final ctrl = c.read(gameControllerProvider.notifier);
      final r = ctrl.answerRecipe(20, true);
      expect(r.after.box, recipeMaxBox);
      expect(r.milestone, 5);
      expect(r.drop, isNotNull);
      expect(r.drop!.accessory.rarity.index, greaterThanOrEqualTo(AccessoryRarity.rare.index));
      expect(ctrl.debugGame.recipeMilestonesClaimed, [5]);
      expect(ctrl.debugGame.ownedAccessories.contains(r.drop!.accessory.id), isTrue);
      // Món 21 (id khác) lên Thạo tiếp: đã nhận mốc 5, chưa tới mốc 10.
      ctrl.debugGame.recipeProgress['21'] = [2, 0, 2];
      final r2 = ctrl.answerRecipe(21, true);
      expect((r2.milestone, r2.drop), (0, null));
    });

    test('đã nhận mốc 5 rồi thì không nhận lại dù đếm lại ≥ 5; mốc 10 và 20 có độ hiếm cao dần', () async {
      final (c, _, _) = await _harness(seed(5, claimed: [5]));
      final ctrl = c.read(gameControllerProvider.notifier);
      expect(ctrl.answerRecipe(20, true).milestone, 0); // 6 món, mốc 5 đã nhận
      final (c2, _, _) = await _harness(seed(9, claimed: [5]));
      final r10 = c2.read(gameControllerProvider.notifier).answerRecipe(20, true);
      expect(r10.milestone, 10);
      expect(r10.drop!.accessory.rarity.index, greaterThanOrEqualTo(AccessoryRarity.epic.index));
      final (c3, _, _) = await _harness(seed(19, claimed: [5, 10]));
      final r20 = c3.read(gameControllerProvider.notifier).answerRecipe(20, true);
      expect(r20.milestone, 20);
      expect(r20.drop!.accessory.rarity, AccessoryRarity.legendary);
    });

    test('sai rồi đúng lại (best đã 3) không tính lại mốc; câu dùng gợi ý không đụng tới mốc', () async {
      final (c, _, _) = await _harness(seed(4));
      final ctrl = c.read(gameControllerProvider.notifier);
      expect(ctrl.answerRecipe(20, true, hinted: true).milestone, 0);
      expect(ctrl.debugGame.recipeMilestonesClaimed, isEmpty);
      expect(ctrl.answerRecipe(20, true).milestone, 5);
      // Tụt bậc món 1 rồi đúng lại: best vẫn 3 ⇒ số món từng Thạo vẫn 5, không có mốc mới.
      ctrl.debugGame.recipeProgress['1'] = [2, 0, 3];
      final r = ctrl.answerRecipe(1, true);
      expect((r.milestone, r.outcome.newBest), (0, false));
    });

    test('lưu/đọc cờ mốc đã nhận; dữ liệu hỏng bị bỏ', () {
      final g = GameState.newGame(nowMillis: 0)..recipeMilestonesClaimed.addAll([5, 10]);
      final back = GameState.fromJson(jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>);
      expect(back.recipeMilestonesClaimed, [5, 10]);
      final bad = g.toJson()..['recipeMilestonesClaimed'] = [5, 'x', null, 10.0];
      expect(GameState.fromJson(jsonDecode(jsonEncode(bad)) as Map<String, dynamic>).recipeMilestonesClaimed, [5, 10]);
      final old = g.toJson()..remove('recipeMilestonesClaimed');
      expect(GameState.fromJson(jsonDecode(jsonEncode(old)) as Map<String, dynamic>).recipeMilestonesClaimed, isEmpty);
    });
  });

  group('chuỗi ngày ôn', () {
    test('câu tính bậc nối chuỗi; cùng ngày không tăng thêm; câu gợi ý/chỉ-luyện không nối', () async {
      final (c, _, setDay) = await _harness(GameState.newGame(nowMillis: 0));
      final ctrl = c.read(gameControllerProvider.notifier);
      setDay(100);
      final hinted = ctrl.answerRecipe(1, true, hinted: true);
      expect((hinted.streakDays, hinted.streakExtended), (0, false));
      expect(c.read(gameControllerProvider).recipeStreak.days, 0);
      final r = ctrl.answerRecipe(1, true);
      expect((r.streakDays, r.streakExtended), (1, true));
      final again = ctrl.answerRecipe(2, true); // cùng ngày, món khác
      expect((again.streakDays, again.streakExtended), (1, false));
      ctrl.answerRecipe(1, true); // chưa tới hạn: không tính
      expect(c.read(gameControllerProvider).recipeStreak.days, 1);
      setDay(101);
      expect(ctrl.answerRecipe(1, true).streakDays, 2);
      setDay(104); // lỡ 102, 103 → đứt, bắt đầu lại
      expect(ctrl.answerRecipe(3, true).streakDays, 1);
    });

    test('mốc 3 ngày +10 💎 đúng một lần; gây lại chuỗi không nhận lại', () async {
      final (c, _, setDay) = await _harness(GameState.newGame(nowMillis: 0));
      final ctrl = c.read(gameControllerProvider.notifier);
      var gems = 0;
      for (var d = 100; d <= 102; d++) {
        setDay(d);
        gems += ctrl.answerRecipe(d - 99, true).streakGems;
      }
      expect(gems, recipeStreakMilestoneGems[3]);
      expect(c.read(gameControllerProvider).gems, gems);
      for (var d = 110; d <= 112; d++) {
        setDay(d);
        gems += ctrl.answerRecipe(d - 100, true).streakGems;
      }
      expect(c.read(gameControllerProvider).recipeStreak.days, 3);
      expect(gems, recipeStreakMilestoneGems[3], reason: 'đã đạt 3 ngày trước đó nên không thưởng lại');
    });

    test('cứu bằng 💎: trừ đúng giá, chuỗi +1; thiếu 💎 hoặc không còn cứu được thì không đổi gì', () async {
      final (c, _, setDay) = await _harness(GameState.newGame(nowMillis: 0)
        ..gems = 100
        ..recipeStreak = 4
        ..recipeStreakBest = 4
        ..recipeStreakLastDay = 100);
      final ctrl = c.read(gameControllerProvider.notifier);
      setDay(101); // chưa lỡ ngày nào
      expect(ctrl.restoreRecipeStreakNow(payGems: true), isFalse);
      setDay(103); // lỡ hai ngày: quá muộn
      expect(ctrl.restoreRecipeStreakNow(payGems: true), isFalse);
      expect(c.read(gameControllerProvider).gems, 100);
      setDay(102); // đúng một ngày
      expect(ctrl.restoreRecipeStreakNow(payGems: true), isTrue);
      expect(c.read(gameControllerProvider).gems, 100 - recipeStreakRestoreGems);
      expect(c.read(gameControllerProvider).recipeStreak.days, 5);
      expect(ctrl.restoreRecipeStreakNow(payGems: true), isFalse, reason: 'cứu rồi không cứu lại');
      expect(c.read(gameControllerProvider).gems, 100 - recipeStreakRestoreGems);
      // Ôn hôm nay nối tiếp thành 6.
      expect(ctrl.answerRecipe(1, true).streakDays, 6);
    });

    test('thiếu 💎: không cứu, không trừ; cứu bằng quảng cáo (payGems=false) không tốn 💎', () async {
      final (c, _, setDay) = await _harness(GameState.newGame(nowMillis: 0)
        ..gems = recipeStreakRestoreGems - 1.0
        ..recipeStreak = 3
        ..recipeStreakBest = 3
        ..recipeStreakLastDay = 100);
      final ctrl = c.read(gameControllerProvider.notifier);
      setDay(102);
      expect(ctrl.restoreRecipeStreakNow(payGems: true), isFalse);
      expect(c.read(gameControllerProvider).gems, recipeStreakRestoreGems - 1);
      expect(c.read(gameControllerProvider).recipeStreak.days, 3);
      expect(ctrl.restoreRecipeStreakNow(payGems: false), isTrue);
      expect(c.read(gameControllerProvider).gems, recipeStreakRestoreGems - 1);
      expect(c.read(gameControllerProvider).recipeStreak.days, 4);
    });

    test('lưu/đọc: vòng JSON giữ nguyên; save cũ → 0; giá trị âm/hỏng bị kẹp', () {
      final g = GameState.newGame(nowMillis: 0)
        ..recipeStreak = 5
        ..recipeStreakLastDay = 200
        ..recipeStreakBest = 9;
      final back = GameState.fromJson(jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>);
      expect((back.recipeStreak, back.recipeStreakLastDay, back.recipeStreakBest), (5, 200, 9));
      final old = g.toJson()..remove('recipeStreak')..remove('recipeStreakLastDay')..remove('recipeStreakBest');
      final o = GameState.fromJson(jsonDecode(jsonEncode(old)) as Map<String, dynamic>);
      expect((o.recipeStreak, o.recipeStreakLastDay, o.recipeStreakBest), (0, 0, 0));
      final bad = g.toJson()..['recipeStreak'] = -3..['recipeStreakLastDay'] = -1..['recipeStreakBest'] = 1e12;
      final b = GameState.fromJson(jsonDecode(jsonEncode(bad)) as Map<String, dynamic>);
      expect((b.recipeStreak, b.recipeStreakLastDay), (0, 0));
      expect(b.recipeStreakBest, lessThanOrEqualTo(100000));
    });
  });

  test('recordOrderPerfect: không trùng, lưu bền, snapshot là bản sao bất biến, save hỏng không ném', () async {
    final (c, prefs, _) = await _harness(GameState.newGame(nowMillis: 0));
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.recordOrderPerfect(3);
    ctrl.recordOrderPerfect(3);
    ctrl.recordOrderPerfect(8);
    expect(_game(c).recipeOrderPerfect, [3, 8]);
    expect(c.read(gameControllerProvider).recipeOrderPerfect, [3, 8]);
    expect(() => c.read(gameControllerProvider).recipeOrderPerfect.add(1), throwsUnsupportedError);

    final reloaded = GameState.fromJson(jsonDecode(jsonEncode(_game(c).toJson())) as Map<String, dynamic>);
    expect(reloaded.recipeOrderPerfect, [3, 8]);
    final dirty = _game(c).toJson()..['recipeOrderPerfect'] = [5, 5, 'x', null, 6.0];
    expect(GameState.fromJson(dirty).recipeOrderPerfect, [5, 6]);
    expect(GameState.fromJson(_game(c).toJson()..remove('recipeOrderPerfect')).recipeOrderPerfect, isEmpty);
    expect(prefs, isNotNull);
  });

  test('grantOrderTip: combo < 2 không có; tăng theo combo, kẹp ở tối đa; cộng đúng Xu', () async {
    final (c, _, _) = await _harness(GameState.newGame(nowMillis: 0));
    final ctrl = c.read(gameControllerProvider.notifier);
    double money() => c.read(gameControllerProvider).money;
    final m0 = money();
    expect(ctrl.grantOrderTip(0), 0);
    expect(ctrl.grantOrderTip(1), 0);
    expect(money(), m0);
    final t2 = ctrl.grantOrderTip(2);
    expect(t2, greaterThan(0));
    expect(money(), closeTo(m0 + t2, 1e-6));
    expect(ctrl.grantOrderTip(3), closeTo(t2 * 2, 1e-6));
    expect(ctrl.grantOrderTip(5), closeTo(t2 * 4, 1e-6));
    expect(ctrl.grantOrderTip(50), closeTo(t2 * 4, 1e-6), reason: 'kẹp ở combo tối đa');
  });

  test('thử thách ngày: thưởng 💎 + Xu tỉ lệ điểm, MỘT lần mỗi ngày (không ghi đè), sang ngày mới làm lại được', () async {
    final (c, _, setDay) = await _harness(GameState.newGame(nowMillis: 0));
    final ctrl = c.read(gameControllerProvider.notifier);
    final g0 = c.read(gameControllerProvider).gems;
    final m0 = c.read(gameControllerProvider).money;
    final r = ctrl.completeDailyChallenge(250);
    expect((r.counted, r.gems), (true, dailyChallengeGems));
    expect(r.cash, greaterThan(0));
    expect(c.read(gameControllerProvider).gems, g0 + dailyChallengeGems);
    expect(c.read(gameControllerProvider).money, closeTo(m0 + r.cash, 1e-6));
    expect((c.read(gameControllerProvider).recipeDailyDay, c.read(gameControllerProvider).recipeDailyScore), (100, 250));

    final again = ctrl.completeDailyChallenge(300);
    expect((again.counted, again.gems, again.cash), (false, 0, 0));
    expect(c.read(gameControllerProvider).recipeDailyScore, 250, reason: 'không ghi đè điểm');
    expect(c.read(gameControllerProvider).gems, g0 + dailyChallengeGems, reason: 'không thưởng lại');

    setDay(101);
    final next = ctrl.completeDailyChallenge(9999); // điểm bị kẹp ở tối đa
    expect(next.counted, true);
    expect(c.read(gameControllerProvider).recipeDailyScore, dailyMaxScore);
    expect(next.cash, greaterThan(r.cash), reason: 'điểm cao hơn ⇒ Xu nhiều hơn');
  });

  test('thử thách ngày: điểm 0 vẫn tính là đã làm; lưu/đọc; save hỏng bị kẹp; trần models = dailyMaxScore', () async {
    final (c, _, _) = await _harness(GameState.newGame(nowMillis: 0));
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(ctrl.completeDailyChallenge(-5).counted, true);
    expect(_game(c).recipeDailyScore, 0);
    final j = jsonDecode(jsonEncode(_game(c).toJson())) as Map<String, dynamic>;
    expect(GameState.fromJson(j).recipeDailyDay, 100);
    expect(GameState.fromJson(j..['recipeDailyScore'] = 99999).recipeDailyScore, dailyMaxScore);
    expect(GameState.fromJson(j..['recipeDailyScore'] = -4).recipeDailyScore, 0);
    expect(GameState.fromJson(j..remove('recipeDailyDay')..remove('recipeDailyScore')).recipeDailyDay, -1);
  });
}
