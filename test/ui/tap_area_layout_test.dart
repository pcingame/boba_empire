import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thanh nhiệm vụ là một dải trong bố cục (không nổi đè lên cảnh/cửa hàng) và
/// vòng "Chạm pha trà" không đè lên nó hay lên tiêu đề giai đoạn — kể cả màn thấp
/// (điện thoại Android dài), nơi từng bị chồng.
void main() {
  // (rộng, cao) tính bằng dp — gồm màn thấp/hẹp và màn lớn.
  const sizes = [
    (320.0, 568.0),
    (360.0, 640.0),
    (360.0, 780.0),
    (393.0, 852.0),
    (411.0, 915.0),
    (430.0, 932.0),
  ];
  for (final (w, h) in sizes) {
    for (final stage in [1, 8, 18]) {
      testWidgets('${w.toInt()}x${h.toInt()} GĐ$stage: nhiệm vụ không đè cảnh, vòng chạm không đè gì',
          (tester) async {
        tester.view.physicalSize = Size(w * 3, h * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await GameStorage(prefs).save(
            GameState.newGame(nowMillis: 0)..stage = stage,
            nowMillis: 0);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => 0),
          ],
          child: const BobaEmpireApp(),
        ));
        await tester.pumpAndSettle();

        final quest = tester.getRect(find.byKey(const Key('quest-bar')));
        final circle = tester.getRect(find.byKey(const Key('tap-circle')));
        // Dải nhiệm vụ nằm TRÊN cảnh: vòng chạm (trong cảnh) ở dưới nó.
        expect(circle.top, greaterThanOrEqualTo(quest.bottom - 0.5),
            reason: 'vòng chạm (top ${circle.top}) đè thanh nhiệm vụ '
                '(bottom ${quest.bottom})');
        // Và không tràn xuống đè hàng tên giai đoạn bên dưới cảnh.
        final header =
            tester.getRect(find.byKey(const Key('stage-header-name')));
        expect(circle.bottom, lessThanOrEqualTo(header.top + 0.5),
            reason: 'vòng chạm (bottom ${circle.bottom}) tràn xuống đè tiêu đề '
                'giai đoạn (top ${header.top})');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  // Dải nhiệm vụ MỘT dòng ở màn hẹp: mô tả dài (vi/pt/th/es) + số đích lớn hoặc nút
  // "Nhận +N💎" không được tràn.
  for (final locale in ['vi', 'en', 'pt', 'es', 'th', 'id', 'ko']) {
    for (final done in [false, true]) {
      testWidgets('[$locale] dải nhiệm vụ ${done ? "đã xong (nút Nhận)" : "đang làm"} '
          'ở màn 320px không tràn', (tester) async {
        tester.platformDispatcher.localesTestValue = [ui.Locale(locale)];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await GameStorage(prefs).save(
            GameState.newGame(nowMillis: 0)
              // xong: nhiệm vụ đầu "chạm 25 lần" với 1000 lần chạm; đang làm: chuỗi
              // "kiếm thêm" (ngưỡng lớn, mô tả dài).
              ..questIndex = done ? 0 : 12
              ..tapCount = done ? 1000 : 0,
            nowMillis: 0);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => 0),
          ],
          child: const BobaEmpireApp(),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('quest-bar')), findsOneWidget);
        expect(find.byKey(const Key('quest-claim')),
            done ? findsOneWidget : findsNothing);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
