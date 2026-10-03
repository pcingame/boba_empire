import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Khoảnh khắc nhận phụ kiện": nhận thưởng xong cả bộ nhiệm vụ ngày → hiện NỘI TUYẾN
/// trong hộp thoại món vừa rớt (không thêm popup mới).
void main() {
  testWidgets('nhận thưởng bộ nhiệm vụ ngày → hiện hàng "Nhận được phụ kiện mới"',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const day = 20000;
    const now = day * 24 * 60 * 60 * 1000;
    final kinds = dailyQuestsFor(day, 1e6).map((q) => q.kind.name).toList();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: now)
        ..dailyQuestDay = day
        ..dailyClaimed.addAll(kinds),
      nowMillis: now, // lưu đúng "bây giờ" → không có popup tiền offline
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ],
      child: const BobaEmpireApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('daily-quests-chip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accessory-reveal')), findsNothing); // chưa nhận

    await tester.tap(find.byKey(const Key('daily-quest-bonus')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accessory-reveal')), findsOneWidget);
    expect(find.textContaining('Nhận được phụ kiện mới'), findsOneWidget);
    // Nút thưởng đã chuyển sang "đã nhận", không nhận lại được.
    expect(
        tester.widget<FilledButton>(find.byKey(const Key('daily-quest-bonus'))).onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
