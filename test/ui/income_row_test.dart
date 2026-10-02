import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hàng "+x / giây" ở thanh tiền KHÔNG được cắt chữ thành "+3.06jj /…" khi thu
/// nhập cực lớn: đó là thông tin chính của game idle. Nguyên nhân gốc từng gặp:
/// chữ nằm trong Flexible NGANG HÀNG với Spacer rỗng (và chip 🌐) nên chỉ được
/// 1/2–1/3 chỗ trống dù cả hàng còn dư.
void main() {
  Future<void> pump(WidgetTester tester, {required double width}) async {
    tester.platformDispatcher.localesTestValue = const [ui.Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = Size(width * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..stage = 12
        ..levels['eternal_tea'] = 1000, // thu nhập cực lớn + mốc 🌐
      nowMillis: 0,
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
      child: const BobaEmpireApp(),
    ));
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 360.0, 400.0]) {
    testWidgets('thu nhập cực lớn ở màn ${width.toInt()}px: chữ "+x / giây" '
        'không bị cắt (không "…") và không tràn', (tester) async {
      await pump(tester, width: width);
      expect(tester.takeException(), isNull);

      final income = find.byKey(const Key('income-per-second'));
      expect(income, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(income);
      expect(paragraph.didExceedMaxLines, isFalse,
          reason: 'chữ thu nhập bị cắt bằng "…"');
      expect(find.byKey(const Key('instant-cash')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
