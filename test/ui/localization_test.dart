import 'dart:ui' as ui;

import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// flutter_test_config đặt locale mặc định = vi; các test này ép sang locale
/// khác để chứng minh mỗi bản dịch nạp đúng (bắt typo/thiếu key trong ARB).
Future<void> _pumpIn(WidgetTester tester, String languageCode) async {
  tester.platformDispatcher.localesTestValue = [ui.Locale(languageCode)];
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
}

void main() {
  // Chuỗi "Chạm pha trà" (tapBrew) theo từng ngôn ngữ.
  const tapBrew = {
    'en': 'Tap to brew',
    'pt': 'Toque para preparar',
    'es': 'Toca para preparar',
    'id': 'Ketuk untuk menyeduh',
    'th': 'แตะเพื่อชงชา',
  };

  tapBrew.forEach((code, text) {
    testWidgets('locale $code nạp đúng bản dịch', (tester) async {
      await _pumpIn(tester, code);
      expect(find.text(text), findsOneWidget);
      expect(find.text('Chạm pha trà'), findsNothing); // không còn tiếng Việt
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('locale en dịch cả tên món và tiền tệ', (tester) async {
    await _pumpIn(tester, 'en');
    expect(find.text('Black Tea'), findsOneWidget);
    expect(find.text('0 Coins'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
