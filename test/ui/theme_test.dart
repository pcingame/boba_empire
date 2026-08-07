import 'dart:ui' as ui;

import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Xác nhận app dùng theme theo hệ thống: đặt độ sáng nền tảng = dark thì
/// ThemeData hiệu lực phải là dark (đã wire darkTheme + themeMode.system).
Future<Brightness> _brightnessFor(WidgetTester tester, Brightness platform) async {
  tester.platformDispatcher.platformBrightnessTestValue = platform;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
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
  final brightness = Theme.of(tester.element(find.byType(HomePage))).brightness;
  await tester.pumpWidget(const SizedBox());
  return brightness;
}

void main() {
  testWidgets('nền tảng sáng → theme sáng', (tester) async {
    tester.platformDispatcher.localesTestValue = const [ui.Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    expect(await _brightnessFor(tester, Brightness.light), Brightness.light);
  });

  testWidgets('nền tảng tối → theme tối', (tester) async {
    tester.platformDispatcher.localesTestValue = const [ui.Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    expect(await _brightnessFor(tester, Brightness.dark), Brightness.dark);
  });
}
