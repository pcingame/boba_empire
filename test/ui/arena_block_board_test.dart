import 'package:boba_empire/arena/arena_controller.dart';
import 'package:boba_empire/arena/arena_models.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/ui/arena_block_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

ArenaInMatch _view({
  int? current = 2,
  int? next = 0,
  bool stuck = false,
  List<int>? rows,
}) =>
    ArenaInMatch(
      myScore: 0,
      opponentScore: 0,
      remaining: const Duration(seconds: 30),
      tiersBought: const {},
      mode: ArenaMode.blocks,
      boardRows: rows ?? List<int>.filled(20, 0),
      currentPiece: current,
      nextPiece: next,
      stuck: stuck,
    );

Widget _host(Locale locale, Widget child) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('không tràn ở ${locale.languageCode}, máy nhỏ + chữ to', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.6),
          ),
          child: _host(locale, ArenaBlockPanel(view: _view(stuck: true), onDrop: (_, _) {})),
        ),
      );
      await tester.pumpAndSettle(); // ném FlutterError nếu RenderFlex tràn
    });
  }

  testWidgets('Thả gọi onDrop với hướng/cột đang chọn; xoay+trái đổi tham số', (tester) async {
    final drops = <(int, int)>[];
    await tester.pumpWidget(
      _host(const Locale('vi'),
          ArenaBlockPanel(view: _view(current: 0), onDrop: (r, c) => drops.add((r, c)))),
    );
    await tester.tap(find.byKey(const Key('arena-block-drop')));
    expect(drops.single, (0, 3)); // I ngang, cột mặc định 3

    await tester.tap(find.byKey(const Key('arena-block-rotate')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('arena-block-left')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('arena-block-drop')));
    expect(drops.last, (1, 2)); // I dọc, lùi 1 cột
  });

  testWidgets('tràn (stuck) khoá mọi nút', (tester) async {
    await tester.pumpWidget(
      _host(const Locale('vi'), ArenaBlockPanel(view: _view(stuck: true), onDrop: (_, _) {})),
    );
    for (final k in ['arena-block-left', 'arena-block-rotate', 'arena-block-right']) {
      expect(tester.widget<IconButton>(find.byKey(Key(k))).onPressed, isNull);
    }
    expect(tester.widget<FilledButton>(find.byKey(const Key('arena-block-drop'))).onPressed,
        isNull);
  });

  testWidgets('cột chọn không hợp lệ (bảng kín hàng trên) thì nút Thả bị khoá', (tester) async {
    // Hàng 0 kín hoàn toàn: khối nào cũng không đặt được ở hàng trên cùng.
    final rows = List<int>.filled(20, 0)..[0] = 1023;
    await tester.pumpWidget(
      _host(const Locale('vi'),
          ArenaBlockPanel(view: _view(rows: rows), onDrop: (_, _) {})),
    );
    expect(tester.widget<FilledButton>(find.byKey(const Key('arena-block-drop'))).onPressed,
        isNull);
  });
}
