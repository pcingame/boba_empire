import 'dart:ui' as ui;

import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// flutter_test_config đặt locale mặc định = vi; test này ép sang en để chứng
/// minh bản dịch tiếng Anh hoạt động.
void main() {
  testWidgets('locale en hiển thị chuỗi tiếng Anh', (tester) async {
    tester.platformDispatcher.localesTestValue = const [ui.Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const BobaEmpireApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Tap to brew'), findsOneWidget);
    expect(find.text('Black Tea'), findsOneWidget); // generator đã dịch
    expect(find.text('0 Coins'), findsOneWidget); // tiền + hậu tố đã dịch
    // Không còn chuỗi tiếng Việt.
    expect(find.text('Chạm pha trà'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
