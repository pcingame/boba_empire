// Hồi quy: bấm "Tạm nghỉ" ở bảng kết quả thì phải rời trang SẠCH SẼ.
//
// Lỗi người chơi báo (2026-09-28, ảnh chụp trên iPhone): bấm Tạm nghỉ, về được
// lưới màn nhưng bảng "Qua màn!" vẫn nổi trên đó. Gốc rễ: sau khi nút này pop
// dialog + pop trang, phần ĐUÔI của `_showResult` vẫn chạy tiếp trên trang
// đang bị gỡ (`setState` + nạp lại màn) — có lúc nó dựng lại bảng kết quả.
import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/arena/match3_rules.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/match3_controller.dart';
import 'package:boba_empire/ui/match3_journey_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('bấm Tạm nghỉ: rời trang VÀ dialog biến mất', (tester) async {
    final savedBase = Balance.m3TargetBase;
    final savedMoves = Balance.m3Moves;
    Balance.m3TargetBase = 1; // nước nào cũng qua màn
    Balance.m3Moves = 1;      // và HẾT NƯỚC ngay sau nước đó
    addTearDown(() {
      Balance.m3TargetBase = savedBase;
      Balance.m3Moves = savedMoves;
    });

    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // CHƠI LẠI màn đã 3 sao — đúng ca trong ảnh báo lỗi.
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..m3Stars.addAll([3, 3, 3]),
      nowMillis: 0,
    );
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      adServiceProvider.overrideWithValue(const StubAdService()),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Match3JourneyPage(),
      ),
    ));
    // Vào màn 1 từ lưới màn THẬT.
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    Future<void> winLevel() async {
      final st = c.read(match3ControllerProvider);
      final mv = Match3Board.fromCells(st.cells).findMove()!;
      c.read(match3ControllerProvider.notifier).swap(mv.$1, mv.$2);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    }

    // Qua màn 1 -> "Màn sau" -> qua màn 2 -> "Màn sau" -> qua màn 3.
    await winLevel();
    expect(find.text('Màn sau'), findsOneWidget);
    await tester.tap(find.text('Màn sau'));
    await tester.pumpAndSettle();

    await winLevel();
    await tester.tap(find.text('Màn sau'));
    await tester.pumpAndSettle();

    await winLevel();
    expect(find.text('Tạm nghỉ'), findsOneWidget);

    final scoreTruocKhiRoi = c.read(match3ControllerProvider).score;
    expect(scoreTruocKhiRoi, greaterThan(0));

    await tester.tap(find.text('Tạm nghỉ'));
    await tester.pump(); // 1 khung hình: đủ để đuôi hàm chạy nếu nó còn chạy

    // Rời trang rồi thì KHÔNG được nạp lại màn nữa. Nạp lại nghĩa là đuôi
    // `_showResult` vẫn chạy trên trang đang bị gỡ — đường duy nhất có thể
    // dựng lại bảng kết quả và cho nó nổi lên trên lưới màn.
    expect(c.read(match3ControllerProvider).score, scoreTruocKhiRoi,
        reason: 'bàn bị nạp lại sau khi đã rời trang');

    await tester.pumpAndSettle();
    expect(find.byType(Match3JourneyPage), findsOneWidget,
        reason: 'phải về lưới màn');
    expect(find.text('Qua màn!'), findsNothing, reason: 'dialog phải biến mất');
    expect(find.text('Tạm nghỉ'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
