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
  _labelScaleTests();
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

  for (final locale in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('thanh dưới 5 mục không tràn ở 320px — $locale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // LocaleNotifier đọc khoá 'app_locale' — KHÔNG seed thì vòng lặp 6 ngôn
      // ngữ này chỉ lặp cái tên, app vẫn dựng đúng một locale (lỗi của bản
      // test đầu tiên).
      SharedPreferences.setMockInitialValues({'flutter.app_locale': locale});
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

// --- Nhãn tab không được CO quá nhỏ so với các tab bên cạnh ---
//
// Nhãn bọc FittedBox nên nhãn dài KHÔNG bị cắt cụt mà bị thu nhỏ — kiểm
// "có tràn không" hoàn toàn không thấy. Phải đo tỉ lệ thu nhỏ thật.
//
// Số đo thật (2026-09-28, máy 412px, tiếng Việt):
//   "Thi đấu" 1.0000 · "Cửa hàng" 0.8957 · "Thành tựu" 0.7961
//   "Trân châu" 0.7961 · "Nhượng quyền" 0.5971  <- chật nhất hiện có
//   "Trân châu rơi" 0.5512  <- từng đặt cho tab này, đã rút ngắn vì bé hẳn
// Ngưỡng 0.57 nằm giữa hai con số cuối: chặn nhãn quá dài mà không đụng
// "Nhượng quyền" vốn đã dài sẵn từ trước.
void _labelScaleTests() {
  for (final locale in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('nhãn tab không co dưới 0.57 lần ở máy 412px — $locale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({'flutter.app_locale': locale});
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
          child: const BobaEmpireApp(),
        ),
      );
      await tester.pump();

      for (final key in const [
        'gem-shop-button',
        'prestige-button',
        'achievements-button',
        'compete-button',
        'match3-button',
      ]) {
        final fitted = find
            .descendant(of: find.byKey(Key(key)), matching: find.byType(FittedBox))
            .last;
        final box = tester.renderObject<RenderBox>(fitted);
        final para = tester.renderObject<RenderParagraph>(
          find.descendant(of: fitted, matching: find.byType(RichText)),
        );
        final scale = (box.size.width / para.size.width).clamp(0.0, 1.0);
        expect(scale, greaterThan(0.57),
            reason: '$key ($locale) co còn ${scale.toStringAsFixed(2)} lần — '
                'nhãn quá dài, rút ngắn đi');
      }

      await tester.pumpWidget(const SizedBox());
    });
  }
}
