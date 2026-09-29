// Mọi màn chính phải MỞ ĐƯỢC ở cả hai hướng iPad mà không tràn.
//
// Khác ipad_layout_test.dart (đo bề ngang nội dung): file này đi rộng — bấm
// qua cả 5 tab + vào một màn Trân Châu Rơi. `pumpAndSettle` tự ném nếu có
// RenderFlex tràn, nên chỉ cần mở được là đã bắt được lớp lỗi đó.
//
// Hướng NGANG chỉ tồn tại trên iPad (điện thoại khoá dọc) và mới bật
// 2026-09-29 — trước đó chưa màn nào từng được dựng ở hướng này.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boba_empire/ui/widgets/phone_width.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
    GameState.newGame(nowMillis: 0)
      ..tutorialSeen = true
      ..m3HowToSeen = true
      ..stage = 6
      ..gems = 900
      ..lifetimeEarnings = 5e15
      ..prestigeStars = 1200
      ..m3Stars.addAll([3, 3, 2, 1, 1])
      ..levels['black_tea'] = 40
      ..levels['milk_tea'] = 25,
    nowMillis: 0,
  );
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
  await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return c;
}

void main() {
  for (final entry in {
    'iPad 13 dọc': const Size(1032, 1376),
    'iPad 13 ngang': const Size(1376, 1032),
  }.entries) {
    for (final btn in const [
      'gem-shop-button',
      'prestige-button',
      'achievements-button',
      'compete-button',
      'match3-button',
    ]) {
      testWidgets('${entry.key} · $btn mở được, không tràn', (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final c = await _pump(tester, entry.value);
        await tester.tap(find.byKey(Key(btn)));
        await tester.pumpAndSettle();
        // pumpAndSettle tự ném nếu có RenderFlex tràn.
        final card = find
            .descendant(of: find.byType(Dialog), matching: find.byType(Material));
        if (card.evaluate().isNotEmpty) {
          final s = tester.getSize(card.first);
          expect(s.height, lessThanOrEqualTo(entry.value.height),
              reason: '$btn: hộp thoại cao ${s.height}dp, vượt màn hình');
          expect(s.width, lessThanOrEqualTo(kPhoneMaxWidth),
              reason: '$btn: hộp thoại rộng ${s.width}dp, chưa được kẹp');
        }
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      });
    }

    testWidgets('${entry.key} · vào màn chơi Trân Châu Rơi', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = await _pump(tester, entry.value);
      await tester.tap(find.byKey(const Key('match3-button')));
      await tester.pumpAndSettle();
      // Ô màn 1 ở góc trên trái của lưới.
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();

      // Bàn cờ KHÔNG phải GridView mà là LayoutBuilder + Stack, và ô đã bị
      // chặn trần 52dp sẵn trong match3_board.dart — nên nó vốn không giãn
      // theo màn iPad. Kiểm cả hai phía: nằm trong phần đã kẹp, và không bị
      // co bé hơn lúc cầm điện thoại.
      final board =
          tester.getSize(find.byKey(const Key('arena-match3-board')));
      expect(board.width, lessThanOrEqualTo(kPhoneMaxWidth),
          reason: '${entry.key}: bàn cờ rộng ${board.width}dp, chưa kẹp');
      expect(board.width, greaterThan(300),
          reason: '${entry.key}: bàn cờ chỉ ${board.width}dp — quá bé');
      // Bug thật (2026-09-29): trần cỡ ô cũ (52dp/ô = 416dp bàn) ăn cả iPad,
      // nên bàn cờ trên iPad giống hệt trên iPhone dù cột nội dung rộng gấp
      // đôi — "hơi nhỏ" theo đúng nghĩa đen. Chỉ kiểm nhánh dọc (portrait):
      // nhánh ngang chia đôi cột cho HUD nên có trần khác.
      if (entry.key.contains('dọc')) {
        expect(board.width, greaterThan(480),
            reason: '${entry.key}: bàn cờ chỉ ${board.width}dp — '
                'trần cỡ ô (66dp/ô trong match3_board.dart) bị hạ nhầm');
      }

      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
