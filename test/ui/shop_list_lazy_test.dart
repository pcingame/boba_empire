// Khoá tính "lười" của danh sách shop: ở giai đoạn cuối có 36 nguồn thu, nếu
// dựng eager (`ListView(children: [...])`) thì mỗi lần shop rebuild là dựng cả
// 36 tile dù chỉ thấy vài cái.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('danh sách nâng cấp dựng lazy (SliverChildBuilderDelegate)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..stage = 18,
      nowMillis: 0,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => 0),
        ],
        child: const BobaEmpireApp(),
      ),
    );

    final lists = tester.widgetList<ListView>(find.byType(ListView));
    expect(
      lists.any((l) => l.childrenDelegate is SliverChildBuilderDelegate),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox());
  });
}
