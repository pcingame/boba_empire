// Luồng kết thúc màn: bảng kết quả hiện, có nút "xem QC thêm nước" khi chưa
// dùng, bấm vào thì chơi tiếp bàn ĐANG DỞ (không nạp lại màn từ đầu).
import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/arena/match3_rules.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/match3_levels.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/match3_controller.dart';
import 'package:boba_empire/ui/match3_play_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late int savedMoves;
  setUp(() {
    savedMoves = Balance.m3Moves;
    Balance.m3Moves = 1; // hết nước sau đúng 1 nước đi
  });
  tearDown(() => Balance.m3Moves = savedMoves);

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      // StubAdService: luôn "xem xong, nhận thưởng".
      adServiceProvider.overrideWithValue(const StubAdService()),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Match3PlayPage(level: Match3Level(1)),
      ),
    ));
    await tester.pump(); // postFrameCallback nạp màn
    return container;
  }

  /// Đi một nước hợp lệ bất kỳ qua controller (gõ toạ độ ô trong test rất giòn).
  void playOne(ProviderContainer c) {
    final state = c.read(match3ControllerProvider);
    final move = Match3Board.fromCells(state.cells).findMove()!;
    expect(c.read(match3ControllerProvider.notifier).swap(move.$1, move.$2),
        isTrue);
  }

  testWidgets('hết nước → hiện bảng kết quả kèm nút xem QC thêm nước',
      (tester) async {
    final c = await pumpPage(tester);
    playOne(c);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Chưa đạt mục tiêu'), findsOneWidget);
    expect(find.text('Xem QC: +${Balance.m3AdExtraMoves} nước'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    c.dispose(); // dừng Timer 1 giây của GameController, không thì test báo
  });

  testWidgets('bấm xem QC → cộng nước, giữ nguyên điểm và bàn đang dở',
      (tester) async {
    final c = await pumpPage(tester);
    playOne(c);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final before = c.read(match3ControllerProvider);
    await tester.tap(find.text('Xem QC: +${Balance.m3AdExtraMoves} nước'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final after = c.read(match3ControllerProvider);
    expect(after.movesLeft, Balance.m3AdExtraMoves);
    expect(after.finished, isFalse);
    expect(after.score, before.score, reason: 'không được reset điểm');
    expect(after.cells, before.cells, reason: 'phải là bàn đang dở');
    expect(after.adContinueUsed, isTrue);
    expect(find.text('Chưa đạt mục tiêu'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    c.dispose(); // dừng Timer 1 giây của GameController, không thì test báo
  });

  testWidgets('qua màn → nút "Màn sau" đưa thẳng sang màn kế tiếp',
      (tester) async {
    // Mục tiêu 0 điểm: nước nào cũng đủ 1 sao.
    final savedBase = Balance.m3TargetBase;
    Balance.m3TargetBase = 1;
    addTearDown(() => Balance.m3TargetBase = savedBase);

    final c = await pumpPage(tester);
    playOne(c);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Qua màn!'), findsOneWidget);
    expect(find.text('Màn sau'), findsOneWidget);
    expect(find.text('Danh sách màn'), findsNothing);

    await tester.tap(find.text('Màn sau'));
    await tester.pumpAndSettle();

    expect(find.text('Màn 2'), findsOneWidget, reason: 'phải sang màn 2');
    expect(c.read(match3ControllerProvider).level.id, 2);
    expect(c.read(match3ControllerProvider).score, 0, reason: 'màn mới, điểm 0');

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('màn cuối thì không mời sang màn sau', (tester) async {
    final savedBase = Balance.m3TargetBase;
    final savedCount = Balance.m3LevelCount;
    Balance.m3TargetBase = 1;
    Balance.m3LevelCount = 1;
    addTearDown(() {
      Balance.m3TargetBase = savedBase;
      Balance.m3LevelCount = savedCount;
    });

    final c = await pumpPage(tester);
    playOne(c);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Màn sau'), findsNothing);
    expect(find.text('Danh sách màn'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('đã dùng lượt QC rồi thì lần kết thúc sau không mời nữa',
      (tester) async {
    final c = await pumpPage(tester);
    playOne(c);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Xem QC: +${Balance.m3AdExtraMoves} nước'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    for (var i = 0; i < Balance.m3AdExtraMoves; i++) {
      playOne(c);
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Chưa đạt mục tiêu'), findsOneWidget);
    expect(find.text('Xem QC: +${Balance.m3AdExtraMoves} nước'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    c.dispose(); // dừng Timer 1 giây của GameController, không thì test báo
  });
}
