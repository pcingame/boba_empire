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

/// Đo khung tên giai đoạn: (chiều rộng được cấp, chiều rộng tự nhiên của chữ).
Future<(double, double)> _measure(WidgetTester tester, String locale, int stage,
    {bool rival = true}) async {
  tester.platformDispatcher.localesTestValue = [ui.Locale(locale)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  // Chương 3 trở đi có chip đối thủ ⚔️ chen vào hàng — trường hợp chật nhất.
  final seed = GameState.newGame(nowMillis: 0)
    ..stage = stage
    ..storyChapter = rival ? 3 : 0
    ..money = 1e60;
  await GameStorage(prefs).save(seed, nowMillis: 0);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ],
    child: const BobaEmpireApp(),
  ));
  await tester.pumpAndSettle();
  final box = tester
      .renderObject<RenderFittedBox>(find.byKey(const Key('stage-header-name')));
  final r = (box.size.width, box.child!.size.width);
  await tester.pumpWidget(const SizedBox());
  return r;
}

// Hàng tiêu đề rộng 400 - 2×16 padding = 368px.
const _rowWidth = 368.0;

void main() {
  // Thanh tiến độ dưới nút mở khoá = tiền / giá (kẹp 0..1); đủ tiền → đầy.
  for (final (money, expected) in [(0.0, 0.0), (1e60, 1.0)]) {
    testWidgets('thanh tiến độ mở khoá: money=$money → $expected', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..stage = 1..money = money, nowMillis: 0);
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => 0),
        ],
        child: const BobaEmpireApp(),
      ));
      await tester.pumpAndSettle();
      final bar = tester.widget<LinearProgressIndicator>(find.byKey(const Key('unlock-progress')));
      expect(bar.value, expected);
      await tester.pumpWidget(const SizedBox());
    });
  }

  // Bố cục hiện tại: hàng 1 = tên + chip đối thủ + chip chế độ mua; nút mở khoá ở hàng 2 (rộng hết hàng) nên
  // tên chỉ nhường chỗ cho hai chip, KHÔNG còn nhường cho nút. (Ghi chú lịch sử bên dưới.)
  // Tên giai đoạn từng bị cắt "…" (vd "Quỹ đầu tư toàn…") vì Flexible ngang hàng
  // với Expanded của nút mở khoá chia đều chỗ trống → tên chỉ được ~một nửa chỗ
  // trống dù nút cần ít hơn. Giờ tên lấy chiều rộng tự nhiên, chỉ chặn ở 50% hàng
  // (từ khi chip chế độ mua ×1/×10/MAX nằm cùng hàng; trước là 62%).
  //
  // Test chạy bằng font Ahem (mỗi ký tự rộng 1em, rộng gấp ~2 lần font thật) nên
  // KHÔNG so tỉ lệ thu nhỏ với ngưỡng tuyệt đối; kiểm tra thứ thật sự cần đảm bảo:
  // tên được cấp ĐỦ chỗ = min(nhu cầu, 50% hàng), không bị nút giành mất.
  for (final locale in ['vi', 'en']) {
    testWidgets('[$locale] tên giai đoạn 1-17 được cấp đủ min(nhu cầu, hàng trừ hai chip)',
        (tester) async {
      for (var stage = 1; stage <= 17; stage++) {
        final (given, natural) = await _measure(tester, locale, stage);
        const cap = _rowWidth - 78 - 40; // có chip đối thủ (chương 3+)
        final wanted = natural < cap ? natural : cap;
        expect(given, greaterThanOrEqualTo(wanted - 1),
            reason: '[$locale] GĐ$stage: cấp $given, cần $wanted');
      }
    });
  }

  testWidgets(
      'giai đoạn cuối (không có nút mở khoá): tên dùng hết chỗ trừ chip chế độ mua '
      '(+ chip đối thủ)', (tester) async {
    final (given, natural) = await _measure(tester, 'vi', 18);
    const cap = _rowWidth - 78 - 40; // có chip đối thủ (chương 3+)
    final wanted = natural < cap ? natural : cap;
    expect(given, greaterThanOrEqualTo(wanted - 1));
    // Không có đối thủ: nhường thêm 40px cho tên.
    final (given2, natural2) = await _measure(tester, 'vi', 18, rival: false);
    final wanted2 = natural2 < _rowWidth - 78 ? natural2 : _rowWidth - 78;
    expect(given2, greaterThanOrEqualTo(wanted2 - 1));
  });

  // Lỗi thật: giai đoạn 18 (không có nút mở khoá) + chip đối thủ + chip chế độ mua tràn 4.7px ở 320px, chữ 1.5×
  // (en/es/id/pt) vì chỗ chừa cho hai chip là hằng số, không nở theo cỡ chữ.
  for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('GĐ18 + đối thủ: header giai đoạn và hàng Xu/💎/⚙ không tràn ở 320px, chữ ${scale}x, $loc', (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        SharedPreferences.setMockInitialValues({'app_locale': loc});
        final prefs = await SharedPreferences.getInstance();
        final seed = GameState.newGame(nowMillis: 0)
          ..stage = 18
          ..storyChapter = 3
          ..tutorialSeen = true
          ..money = 1e60;
        await GameStorage(prefs).save(seed, nowMillis: 0);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => 0),
          ],
          child: const BobaEmpireApp(),
        ));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('stage-header-name')), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Nút ⚙ phải còn nằm TRONG màn (bản cũ bị đẩy ra ngoài ~39px ở chữ 2×, bấm không tới).
        final gear = tester.getRect(find.byKey(const Key('settings-button')));
        expect(gear.right, lessThanOrEqualTo(320.0 + 0.5), reason: '⚙ bị đẩy ra ngoài màn');
        expect(gear.left, greaterThanOrEqualTo(0));
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
