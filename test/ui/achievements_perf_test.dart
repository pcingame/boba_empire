import 'package:boba_empire/core/achievements.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/widgets/clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bảng Thành tựu từng rớt ~66% khung trên Android thật vì mỗi hàng chưa đạt bọc
/// Opacity(0.8) — một saveLayer (vùng đệm ngoài màn hình) mỗi hàng hiển thị. Khoá lại
/// bằng test: không còn Opacity trong danh sách, dựng lười, cuộn tới hàng cuối được.
void main() {
  testWidgets('dựng lười biếng, cuộn tới hàng cuối được, không Opacity trong danh sách',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
      child: const BobaEmpireApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('achievements-button')));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    final rows = find.descendant(of: dialog, matching: find.byType(ClayTile));
    expect(rows, findsWidgets);
    expect(rows.evaluate().length, lessThan(achievements.length),
        reason: 'phải dựng lười, không dựng cả ${achievements.length} hàng');

    // Không có saveLayer do Opacity trong danh sách.
    expect(
        find.descendant(
            of: find.descendant(of: dialog, matching: find.byType(ListView)),
            matching: find.byType(Opacity)),
        findsNothing);

    // Cuộn tới hàng cuối vẫn thấy được.
    await tester.drag(
        find.descendant(of: dialog, matching: find.byType(ListView)),
        const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(find.descendant(of: dialog, matching: find.text(achievements.last.emoji)),
        findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });
}
