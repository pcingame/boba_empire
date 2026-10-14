// Bậc thuộc công thức qua controller: thưởng chỉ lần đầu đạt bậc mới, chống cày, lưu bền, save hỏng.
import 'dart:convert';

import 'package:boba_empire/core/daily.dart';
import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/weekly_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
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
}
