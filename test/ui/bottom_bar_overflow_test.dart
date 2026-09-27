// Thanh điều hướng có 5 mục: mỗi ô chỉ còn ~20% bề ngang. Máy hẹp + bản dịch
// dài là công thức tràn RenderFlex quen thuộc của app này.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Cỡ chữ hệ thống phóng to là lớp lỗi riêng: ô tab chỉ rộng ~20% màn hình.
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('thanh dưới 5 mục không tràn ở 320px, cỡ chữ x$scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..tutorialSeen = true,
        nowMillis: 0,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => 0),
          ],
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const BobaEmpireApp(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('match3-button')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final locale in ['vi', 'en', 'es', 'id', 'pt', 'th']) {
    testWidgets('thanh dưới 5 mục không tràn ở 320px — $locale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Save có Sao nhiều chữ số: huy hiệu số to từng tràn sang tab bên cạnh.
      await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)
          ..prestigeStars = 16600000000
          ..tutorialSeen = true,
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
      await tester.pump();

      expect(find.byKey(const Key('match3-button')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));

      // Nhãn phải hiện ĐỦ CHỮ, không bị cắt cụt thành "Thàn...". Text có
      // maxLines+ellipsis không gây tràn RenderFlex nên chỉ nhìn "có tràn
      // không" thì test vô dụng — phải hỏi thẳng RenderParagraph.
      for (final key in const [
        'gem-shop-button',
        'prestige-button',
        'achievements-button',
        'compete-button',
        'match3-button',
      ]) {
        // .last: nút Nhượng quyền có thêm Text huy hiệu số Sao đứng trước.
        final label = find
            .descendant(
              of: find.byKey(Key(key)),
              matching: find.byType(Text),
            )
            .last;
        expect(label, findsOneWidget, reason: '\$key thiếu nhãn');
        final para = tester.renderObject<RenderParagraph>(
          find.descendant(of: label, matching: find.byType(RichText)),
        );
        expect(para.didExceedMaxLines, isFalse,
            reason: '$key ($locale) bị cắt cụt nhãn');
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
