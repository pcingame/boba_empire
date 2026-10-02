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
  // Tên giai đoạn từng bị cắt "…" (vd "Quỹ đầu tư toàn…") vì Flexible ngang hàng
  // với Expanded của nút mở khoá chia đều chỗ trống → tên chỉ được ~một nửa chỗ
  // trống dù nút cần ít hơn. Giờ tên lấy chiều rộng tự nhiên, chỉ chặn ở 50% hàng
  // (từ khi chip chế độ mua ×1/×10/MAX nằm cùng hàng; trước là 62%).
  //
  // Test chạy bằng font Ahem (mỗi ký tự rộng 1em, rộng gấp ~2 lần font thật) nên
  // KHÔNG so tỉ lệ thu nhỏ với ngưỡng tuyệt đối; kiểm tra thứ thật sự cần đảm bảo:
  // tên được cấp ĐỦ chỗ = min(nhu cầu, 50% hàng), không bị nút giành mất.
  for (final locale in ['vi', 'en']) {
    testWidgets('[$locale] tên giai đoạn 1-17 được cấp đủ min(nhu cầu, 50% hàng)',
        (tester) async {
      for (var stage = 1; stage <= 17; stage++) {
        final (given, natural) = await _measure(tester, locale, stage);
        final wanted = natural < _rowWidth * 0.5 ? natural : _rowWidth * 0.5;
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
}
