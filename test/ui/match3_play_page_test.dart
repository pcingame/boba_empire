// Luồng kết thúc màn: bảng kết quả hiện, có nút "xem QC thêm nước" khi chưa
// dùng, bấm vào thì chơi tiếp bàn ĐANG DỞ (không nạp lại màn từ đầu).
import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/arena/match3_rules.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/match3_levels.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/match3_controller.dart';
import 'package:boba_empire/ui/match3_board.dart';
import 'package:boba_empire/ui/match3_play_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  _landscapeTests();
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

  /// Điểm của nước hợp lệ đầu tiên ở màn 1. Bàn tất định nên con số này cố
  /// định — dùng để đặt mục tiêu sao cho đi 1 nước là ĐÚNG 1 sao (đặt mục tiêu
  /// bằng 1 thì nước nào cũng ra thẳng 3 sao, mất luôn nhánh "Chơi nốt").
  int firstMoveScore() {
    // specials: true để khớp controller — bật kẹo thì ghép 4 sinh kẹo thay vì
    // xoá sạch, nên điểm nước đầu khác hẳn bản không bật.
    final board =
        Match3Board.initial(const Match3Level(1).seq(), specials: true);
    final move = board.findMove()!;
    return board.trySwap(move.$1, move.$2).score;
  }

  /// Đi một nước hợp lệ bất kỳ qua controller (gõ toạ độ ô trong test rất giòn).
  void playOne(ProviderContainer c) {
    final state = c.read(match3ControllerProvider);
    final move = Match3Board.fromCells(state.cells).findMove()!;
    expect(c.read(match3ControllerProvider.notifier).swap(move.$1, move.$2),
        isTrue);
  }

  testWidgets('màn thu thập: HUD hiện biểu tượng ô và tiến độ N/M',
      (tester) async {
    final savedEvery = Balance.m3CollectEvery;
    final savedMoves = Balance.m3Moves;
    Balance.m3CollectEvery = 3;
    Balance.m3Moves = 20;
    addTearDown(() {
      Balance.m3CollectEvery = savedEvery;
      Balance.m3Moves = savedMoves;
    });

    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      adServiceProvider.overrideWithValue(const StubAdService()),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Match3PlayPage(level: Match3Level(6)),
      ),
    ));
    await tester.pump();

    final level = c.read(match3ControllerProvider).level;
    final icon = match3Icons[level.collectType];
    // Tiến độ "🟤 0/13" chứa cả số hiện tại lẫn mục tiêu nên không cần thêm
    // nhãn mục tiêu riêng nữa.
    expect(find.text('$icon 0/${level.target}'), findsOneWidget);
    expect(find.textContaining('Điểm:'), findsNothing);
    // Thanh sao phải có mặt: đó là thứ cho biết còn cách mốc sao bao xa.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

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
    expect(find.text('Chưa đạt mục tiêu'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    c.dispose(); // dừng Timer 1 giây của GameController, không thì test báo
  });

  testWidgets('đạt mục tiêu giữa chừng → báo NGAY, không đốt nốt số nước',
      (tester) async {
    final savedBase = Balance.m3TargetBase;
    final savedMoves = Balance.m3Moves;
    Balance.m3TargetBase = firstMoveScore().toDouble(); // đi 1 nước = đúng 1 sao
    Balance.m3Moves = 20; // vẫn còn rất nhiều nước
    addTearDown(() {
      Balance.m3TargetBase = savedBase;
      Balance.m3Moves = savedMoves;
    });

    final c = await pumpPage(tester);
    playOne(c);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Đạt mục tiêu!'), findsOneWidget);
    expect(c.read(match3ControllerProvider).movesLeft, greaterThan(0),
        reason: 'phải báo khi còn nước, không đợi hết nước');

    // Nói rõ còn thiếu bao nhiêu nữa là 2★ → "Chơi nốt" là lựa chọn có thông tin.
    final play = c.read(match3ControllerProvider);
    final next = match3NextStar(play.progress, play.level.target)!;
    expect(next.$1, 2);
    expect(find.textContaining('nữa là 2★'), findsOneWidget);
    expect(find.textContaining('${next.$2}'), findsWidgets);
    // Còn nước thì không mời xem QC thêm nước (vô nghĩa).
    expect(find.text('Xem QC: +${Balance.m3AdExtraMoves} nước'), findsNothing);
    expect(find.text('Chơi nốt'), findsOneWidget);
    expect(find.text('Tạm nghỉ'), findsOneWidget);
    expect(find.text('Màn sau'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('chọn "Chơi nốt" → chơi tiếp bàn đang dở, không hỏi lại mỗi nước',
      (tester) async {
    final savedBase = Balance.m3TargetBase;
    final savedMoves = Balance.m3Moves;
    Balance.m3TargetBase = firstMoveScore().toDouble(); // đi 1 nước = đúng 1 sao
    Balance.m3Moves = 20; // vẫn còn rất nhiều nước
    addTearDown(() {
      Balance.m3TargetBase = savedBase;
      Balance.m3Moves = savedMoves;
    });

    final c = await pumpPage(tester);
    playOne(c);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Chơi nốt'));
    await tester.pumpAndSettle();

    final after = c.read(match3ControllerProvider);
    expect(after.level.id, 1);
    expect(after.score, greaterThan(0), reason: 'giữ nguyên bàn đang dở');

    // Đi thêm vài nước: KHÔNG được hỏi lại.
    for (var i = 0; i < 3; i++) {
      playOne(c);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Đạt mục tiêu!'), findsNothing, reason: 'nước ${i + 1}');
    }

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
      'đã chọn "Chơi nốt" nhưng đạt 3★ giữa chừng → hỏi NGAY (Màn sau / Tạm nghỉ), không đợi hết nước',
      (tester) async {
    final savedBase = Balance.m3TargetBase;
    final savedMoves = Balance.m3Moves;
    Balance.m3TargetBase = firstMoveScore().toDouble(); // nước đầu = đúng 1★
    Balance.m3Moves = 40; // còn rất nhiều nước
    addTearDown(() {
      Balance.m3TargetBase = savedBase;
      Balance.m3Moves = savedMoves;
    });

    final c = await pumpPage(tester);
    playOne(c);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Đạt mục tiêu!'), findsOneWidget);
    await tester.tap(find.text('Chơi nốt'));
    await tester.pumpAndSettle();

    // Đi tiếp tới khi đủ 3★ (không được hỏi trước đó vì 1★/2★ đã chọn chơi nốt).
    var moves = 0;
    while (c.read(match3ControllerProvider).stars < 3 && moves < 30) {
      expect(find.text('Đạt mục tiêu!'), findsNothing);
      expect(find.text('Qua màn!'), findsNothing);
      playOne(c);
      moves++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(c.read(match3ControllerProvider).stars, greaterThanOrEqualTo(3));
    await tester.pump(const Duration(seconds: 2));

    expect(c.read(match3ControllerProvider).movesLeft, greaterThan(0),
        reason: 'hỏi khi còn nước, không đợi hết nước');
    expect(find.text('Qua màn!'), findsOneWidget);
    expect(find.text('Tạm nghỉ'), findsOneWidget);
    expect(find.text('Màn sau'), findsOneWidget);
    expect(find.text('Chơi nốt'), findsNothing, reason: 'hết sao để săn');

    await tester.pumpWidget(const SizedBox());
    c.dispose();
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

    expect(find.text('Màn sau'), findsOneWidget);

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
    expect(find.text('Tạm nghỉ'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
      'hết nước LẠI được mời xem QC: mỗi lần xem +5 nước, không giới hạn số lần',
      (tester) async {
    // Mục tiêu rất cao: đi 11 nước mà đạt mục tiêu thì ra bảng "qua màn", không
    // phải bảng "hết nước" cần kiểm ở đây.
    final savedBase = Balance.m3TargetBase;
    Balance.m3TargetBase = 1e9;
    addTearDown(() => Balance.m3TargetBase = savedBase);
    final c = await pumpPage(tester);
    playOne(c);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final adButton = find.text('Xem QC: +${Balance.m3AdExtraMoves} nước');

    for (var round = 1; round <= 3; round++) {
      expect(find.text('Chưa đạt mục tiêu'), findsOneWidget,
          reason: 'lần $round: hết nước thì hiện bảng kết quả');
      expect(adButton, findsOneWidget, reason: 'lần $round: vẫn được mời xem QC');
      await tester.tap(adButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(c.read(match3ControllerProvider).movesLeft, Balance.m3AdExtraMoves,
          reason: 'lần $round: cộng đúng 5 nước');
      for (var i = 0; i < Balance.m3AdExtraMoves; i++) {
        playOne(c);
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 2));
    }
    expect(find.text('Chưa đạt mục tiêu'), findsOneWidget);
    expect(adButton, findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    c.dispose(); // dừng Timer 1 giây của GameController, không thì test báo
  });
}

// --- Bố cục khi máy nằm ngang: HUD đứng cạnh bàn cờ, không xếp dọc ---
void _landscapeTests() {
  testWidgets('nằm ngang: bàn cờ không bị co còn bằng con tem', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      adServiceProvider.overrideWithValue(const StubAdService()),
    ]);
    Future<double> boardWidth(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
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
      await tester.pump();
      return tester.getSize(find.byType(Match3Panel)).width;
    }

    final portrait = await boardWidth(const Size(400, 800));
    final landscape = await boardWidth(const Size(800, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Đo thật ở 800x400: bố cục ngang cho bàn rộng 344 (0.86 lần lúc đứng),
    // còn nếu cứ xếp dọc thì chỉ còn 246 (0.61 lần) vì chiều cao bóp lại.
    // Ngưỡng 0.75 nằm gọn giữa hai con số đó.
    expect(landscape, greaterThan(portrait * 0.75),
        reason: 'ngang $landscape vs dọc $portrait');

    await tester.pumpWidget(const SizedBox());
    c.dispose(); // dừng Timer 1 giây của GameController trước khi test kết thúc
  });
}
