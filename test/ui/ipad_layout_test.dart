// Bố cục trên máy màn rộng (iPad).
//
// App thiết kế ở bề ngang điện thoại (~400dp). Trên iPad Pro 13" (1032dp dọc)
// KHÔNG có gì tràn RenderFlex — nên kiểu kiểm "có tràn không" quen dùng ở các
// test khác hoàn toàn mù ở đây. Cái hỏng là thứ khác: nội dung bị kéo giãn hết
// chiều ngang, thanh dưới 5 mục dàn ra cả gang tay, giữa màn là dải trống.
//
// Vậy nên đo THẲNG bề ngang thật của nội dung so với bề ngang màn hình.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/widgets/phone_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kích thước thật (dp) của các máy cần đỡ.
const _sizes = <String, Size>{
  'iPad Pro 13" dọc': Size(1032, 1376),
  'iPad Pro 13" ngang': Size(1376, 1032),
  'iPad mini dọc': Size(744, 1133),
  'iPhone 15 Pro Max': Size(430, 932),
  'iPhone SE': Size(375, 667),
  // Split View trên iPad co app còn ~320dp. Vì Info.plist KHÔNG đặt
  // UIRequiresFullScreen nên trường hợp này là thật, không phải giả định.
  'iPad chia đôi hẹp': Size(320, 1024),
};

Future<ProviderContainer> _pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
    GameState.newGame(nowMillis: 0)..tutorialSeen = true,
    nowMillis: 0,
  );
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: const BobaEmpireApp(),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return c;
}

void main() {
  _contentWidthTests();
  _journeyTests();
}

/// Nội dung không được rộng quá [kPhoneMaxWidth] trên máy tablet, và PHẢI
/// dùng hết bề ngang trên điện thoại (kẹp nhầm trên điện thoại là lỗi nặng
/// hơn nhiều — ảnh hưởng toàn bộ người chơi, không phải thiểu số tablet).
void _contentWidthTests() {
  _sizes.forEach((name, size) {
    testWidgets('màn chính: bề ngang nội dung hợp lý — $name', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = await _pumpHome(tester);

      // Thanh dưới là thứ lộ nhất: 5 mục dàn ngang.
      final bar = tester.getSize(find.byKey(const Key('match3-button')));
      final expectedMax = size.width <= kPhoneMaxWidth
          ? size.width / 5
          : kPhoneMaxWidth / 5;
      expect(bar.width, lessThanOrEqualTo(expectedMax + 1),
          reason: '$name: mỗi mục thanh dưới rộng ${bar.width}dp — '
              'nội dung đang giãn hết màn thay vì kẹp ở $kPhoneMaxWidth');

      // Trên điện thoại KHÔNG được kẹp: phải còn dùng gần hết bề ngang.
      if (size.width <= kPhoneMaxWidth) {
        expect(bar.width, greaterThan(size.width / 5 - 12),
            reason: '$name: điện thoại mà nội dung bị thu hẹp — '
                'PhoneWidth đang kẹp nhầm cả máy nhỏ');
      }

      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  });
}

/// Lưới màn Trân Châu Rơi: 4 cột cố định. Không kẹp thì mỗi ô to bằng nắm tay
/// trên iPad mà vẫn chỉ 4 cột.
///
/// Đi qua ĐƯỜNG THẬT (dựng BobaEmpireApp rồi bấm tab) chứ không tự dựng
/// MaterialApp riêng: chỗ kẹp bề ngang nằm ở `MaterialApp.builder` trong
/// main.dart, nên một MaterialApp tự chế trong test sẽ không có nó và test
/// hoá ra đang đo một app khác với app thật.
void _journeyTests() {
  for (final name in ['iPad Pro 13" dọc', 'iPhone SE']) {
    testWidgets('lưới màn: ô không phình trên máy rộng — $name',
        (tester) async {
      final size = _sizes[name]!;
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)
          ..tutorialSeen = true
          ..m3HowToSeen = true
          ..m3Stars.addAll([3, 2, 1]),
        nowMillis: 0,
      );
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ]);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const BobaEmpireApp()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('match3-button')));
      await tester.pumpAndSettle();

      final grid = tester.getSize(find.byType(GridView));
      expect(grid.width, lessThanOrEqualTo(kPhoneMaxWidth + 1),
          reason: '$name: lưới rộng ${grid.width}dp, chưa kẹp');
      expect(grid.width / 4, lessThanOrEqualTo(150),
          reason: '$name: mỗi ô màn rộng ${grid.width / 4}dp — quá to');

      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
