/// Đo tương phản (WCAG) các cặp màu chữ/nền THẬT của theme, cho cả 18 giai
/// đoạn × light/dark — mỗi giai đoạn có seed riêng nên pastel hoá có thể đạt ở
/// seed này mà trượt ở seed khác (vàng, lục nhạt...).
library;

import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Màu lấy từ ThemeData thật của [stage] ở độ sáng [brightness].
Future<ThemeData> _themeFor(
    WidgetTester tester, int stage, Brightness brightness) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  tester.platformDispatcher.localesTestValue = const [ui.Locale('vi')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs)
      .save(GameState.newGame(nowMillis: 0)..stage = stage, nowMillis: 0);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ],
    child: const BobaEmpireApp(),
  ));
  await tester.pump();
  final theme = Theme.of(tester.element(find.byType(HomePage)));
  await tester.pumpWidget(const SizedBox());
  return theme;
}

void main() {
  testWidgets('18 giai đoạn × light/dark: chữ ≥ 4.5:1, icon/nhấn ≥ 3:1',
      (tester) async {
    final failures = <String>[];
    final worst = <String, double>{};

    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (var stage = 1; stage <= 18; stage++) {
        final t = await _themeFor(tester, stage, brightness);
        final s = t.colorScheme;
        final bg = t.scaffoldBackgroundColor;
        final dialogBg = t.dialogTheme.backgroundColor ?? s.surfaceContainerHigh;
        final headerEnd = Color.alphaBlend(
            s.primaryContainer.withValues(alpha: 0.55), bg);
        final selSeg = brightness == Brightness.light
            ? Color.lerp(s.primaryContainer, s.primary, 0.3)!
            : s.primary;
        final selSegText = brightness == Brightness.light
            ? s.onPrimaryContainer
            : s.onPrimary;

        // (nhãn, chữ/icon, nền, ngưỡng)
        final checks = <(String, Color, Color, double)>[
          ('onSurface/nền màn', s.onSurface, bg, 4.5),
          ('onSurface/thẻ', s.onSurface, s.surface, 4.5),
          ('onSurfaceVariant/thẻ', s.onSurfaceVariant, s.surface, 4.5),
          ('onSurfaceVariant/ô ×1 chưa chọn', s.onSurfaceVariant,
              s.surfaceContainerHigh, 4.5),
          ('chữ trên nút filled & thanh tiền', s.onPrimaryContainer,
              s.primaryContainer, 4.5),
          ('chữ trên đầu gradient thanh tiền', s.onPrimaryContainer, headerEnd,
              4.5),
          ('chữ ô ×1 đang chọn', selSegText, selSeg, 4.5),
          ('chữ nhãn MỚI', s.onTertiary, s.tertiary, 4.5),
          ('chữ chip secondary', s.onSecondaryContainer, s.secondaryContainer,
              4.5),
          ('chữ lỗi/thẻ', s.error, s.surface, 4.5),
          ('TextButton (primary)/hộp thoại', s.primary, dialogBg, 4.5),
          ('onSurface/hộp thoại', s.onSurface, dialogBg, 4.5),
          ('icon primary/thẻ (thanh điều hướng)', s.primary, s.surface, 3.0),
        ];
        for (final (label, fg, back, min) in checks) {
          final r = _ratio(fg, back);
          final key = '${brightness.name}: $label';
          if (r < (worst[key] ?? 99)) worst[key] = r;
          if (r < min) {
            failures.add(
                'GĐ$stage ${brightness.name} — $label: ${r.toStringAsFixed(1)} < $min');
          }
        }
      }
    }
    // ignore: avoid_print
    print('--- tương phản THẤP NHẤT qua 18 giai đoạn ---');
    for (final e in worst.entries) {
      // ignore: avoid_print
      print('${e.value.toStringAsFixed(1).padLeft(5)}  ${e.key}');
    }
    // ignore: avoid_print
    if (failures.isNotEmpty) print('--- TRƯỢT ---\n${failures.join('\n')}');
    expect(failures, isEmpty);
  });
}
