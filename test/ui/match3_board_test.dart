import 'package:boba_empire/arena/match3_rules.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/ui/match3_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bảng phẳng không có dãy 3: loại = (2r + 3c) mod 5.
List<int> _cells() => [
      for (var i = 0; i < m3Cells; i++) (2 * (i ~/ m3Size) + 3 * (i % m3Size)) % m3Types,
    ];

Match3View _view({
  List<int>? cells,
  List<List<int>> frames = const [],
  int moveId = 0,
  bool stuck = false,
  bool finished = false,
}) =>
    Match3View(
      cells: cells ?? _cells(),
      frames: frames,
      moveId: moveId,
      stuck: stuck,
      finished: finished,
    );

/// Bọc ProviderScope: bàn cờ giờ đọc `audioServiceProvider` để phát tiếng khi
/// ô nổ (mặc định là SilentAudioService nên test không kêu gì).
Widget _host(Locale locale, Widget child) => ProviderScope(
      child: _app(locale, child),
    );

Widget _app(Locale locale, Widget child) => MaterialApp(
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

bool _rec(List<(int, int)> log, int c, int d) {
  log.add((c, d));
  return true;
}

Finder _tile(int i) => find.byKey(Key('m3-tile-$i'));

void main() {
  _specialFaceTests();
  _boardFitsTests();
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('không tràn ở ${locale.languageCode}, máy nhỏ + chữ to', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.6)),
          child: _host(locale, Match3Panel(view: _view(stuck: true), onSwap: (_, _) => true)),
        ),
      );
      await tester.pumpAndSettle(); // ném FlutterError nếu RenderFlex tràn
    });
  }

  testWidgets('chạm 2 ô kề nhau gọi onSwap đúng (cell, dir) — ngang và dọc, cả hai chiều', (tester) async {
    final swaps = <(int, int)>[];
    await tester.pumpWidget(_host(const Locale('vi'),
        Match3Panel(view: _view(), onSwap: (c, d) => _rec(swaps, c, d))));
    await tester.tap(_tile(0));
    await tester.pump();
    await tester.tap(_tile(1));
    await tester.pump();
    expect(swaps.last, (0, 0)); // ô 0 với ô phải

    await tester.tap(_tile(9));
    await tester.pump();
    await tester.tap(_tile(1));
    await tester.pump();
    expect(swaps.last, (1, 1)); // ô 1 với ô dưới (chọn từ dưới lên)

    await tester.tap(_tile(20));
    await tester.pump();
    await tester.tap(_tile(19));
    await tester.pump();
    expect(swaps.last, (19, 0)); // chọn từ phải sang trái
    expect(swaps.length, 3);
  });

  testWidgets('ô không kề (chéo, cuối hàng sang đầu hàng sau) không đổi, chỉ chuyển lựa chọn', (tester) async {
    final swaps = <(int, int)>[];
    await tester.pumpWidget(_host(const Locale('vi'),
        Match3Panel(view: _view(), onSwap: (c, d) => _rec(swaps, c, d))));
    await tester.tap(_tile(0));
    await tester.pump();
    await tester.tap(_tile(9)); // chéo
    await tester.pump();
    await tester.tap(_tile(7));
    await tester.pump();
    await tester.tap(_tile(8)); // cuối hàng 0 -> đầu hàng 1: KHÔNG kề
    await tester.pump();
    expect(swaps, isEmpty);
  });

  testWidgets('nước bị từ chối (onSwap=false) không làm hỏng giao diện; chạm lại vẫn dùng được', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(const Locale('vi'),
        Match3Panel(view: _view(), onSwap: (_, _) => ++calls < 0)));
    await tester.tap(_tile(0));
    await tester.pump();
    await tester.tap(_tile(1));
    await tester.pump();
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 400)); // hết nháy đỏ
    await tester.tap(_tile(2));
    await tester.pump();
    await tester.tap(_tile(3));
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('vuốt sang ô kề gọi onSwap', (tester) async {
    final swaps = <(int, int)>[];
    await tester.pumpWidget(_host(const Locale('vi'),
        Match3Panel(view: _view(), onSwap: (c, d) => _rec(swaps, c, d))));
    await tester.fling(_tile(10), const Offset(120, 0), 1500);
    await tester.pump();
    expect(swaps.single, (10, 0));
    await tester.fling(_tile(30), const Offset(0, -120), 1500);
    await tester.pump();
    expect(swaps.last, (22, 1)); // vuốt lên = đổi với ô phía trên (ô 22 với ô dưới nó là 30)
  });

  testWidgets('hết nước (stuck) hoặc hết giờ thì khoá chạm', (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(const Locale('vi'),
        Match3Panel(view: _view(stuck: true), onSwap: (_, _) => ++calls > 0)));
    await tester.tap(_tile(0));
    await tester.tap(_tile(1));
    await tester.pump();
    expect(calls, 0);

    await tester.pumpWidget(_host(const Locale('vi'),
        Match3Panel(view: _view(finished: true), onSwap: (_, _) => ++calls > 0)));
    await tester.tap(_tile(0));
    await tester.tap(_tile(1));
    await tester.pump();
    expect(calls, 0);
  });

  Future<void> playMove(WidgetTester tester, Match3Board board, Match3View Function(List<int> cells, List<List<int>> frames, int id) mk,
      StateSetter Function() setter, void Function(Match3View) assign, int id) async {
    final move = board.findMove()!;
    final result = board.trySwap(move.$1, move.$2);
    setter()(() => assign(mk([...board.cells], result.frames, id)));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('hoạt ảnh trên nước đi + dây chuyền THẬT: ô rơi/bù khớp bảng cuối (không phải dựng lại)', (tester) async {
    match3DebugFallbacks = 0;
    final seq = [
      for (var i = 0, x = 2026; i < m3SeqLength; i++)
        (x = (x * 1103515245 + 12345) & 0x7fffffff, (x >> 16) % 5).$2,
    ];
    final board = Match3Board.initial(seq);
    late StateSetter setOuter;
    var view = _view(cells: [...board.cells]);
    await tester.pumpWidget(_host(
      const Locale('vi'),
      StatefulBuilder(builder: (context, setState) {
        setOuter = setState;
        return Match3Panel(view: view, onSwap: (_, _) => true);
      }),
    ));
    for (var id = 1; id <= 8; id++) {
      await playMove(tester, board, (cells, frames, i) => _view(cells: cells, frames: frames, moveId: i), () => setOuter,
          (v) => view = v, id);
      // Số ô mỗi loại đang hiển thị = số ô mỗi loại của bảng cuối.
      for (var t = 0; t < m3Types; t++) {
        final want = board.cells.where((v) => v == t).length;
        expect(find.text(match3Icons[t]).evaluate().length, want, reason: 'nước $id, loại $t');
      }
    }
    expect(match3DebugFallbacks, 0);
  });

  testWidgets('gợi ý nước đi hiện sau khi rảnh 6 giây và mất khi chạm', (tester) async {
    final seq = [
      for (var i = 0, x = 2026; i < m3SeqLength; i++)
        (x = (x * 1103515245 + 12345) & 0x7fffffff, (x >> 16) % 5).$2,
    ];
    final cells = Match3Board.initial(seq).cells;
    expect(Match3Board.fromCells(cells).findMove(), isNotNull);
    await tester.pumpWidget(_host(
      const Locale('vi'),
      Match3Panel(view: _view(cells: [...cells]), onSwap: (_, _) => true),
    ));
    int amberBorders() => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .where((c) => (c.decoration as BoxDecoration?)?.border?.top.color == Colors.amber)
        .length;
    expect(amberBorders(), 0);
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 200));
    expect(amberBorders(), 2);
    await tester.tap(_tile(0));
    await tester.pump(const Duration(milliseconds: 200));
    expect(amberBorders(), 0);
  });

  testWidgets('nước bị chặn khi đang phát hoạt ảnh', (tester) async {
    final seq = [
      for (var i = 0, x = 2026; i < m3SeqLength; i++)
        (x = (x * 1103515245 + 12345) & 0x7fffffff, (x >> 16) % 5).$2,
    ];
    final board = Match3Board.initial(seq);
    var calls = 0;
    late StateSetter setOuter;
    var view = _view(cells: [...board.cells]);
    await tester.pumpWidget(_host(
      const Locale('vi'),
      StatefulBuilder(builder: (context, setState) {
        setOuter = setState;
        return Match3Panel(view: view, onSwap: (_, _) => ++calls > 0);
      }),
    ));
    final move = board.findMove()!;
    final result = board.trySwap(move.$1, move.$2);
    setOuter(() => view = _view(cells: [...board.cells], frames: result.frames, moveId: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(_tile(20));
    await tester.tap(_tile(21));
    await tester.pump();
    expect(calls, 0);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(_tile(20));
    await tester.pump();
    await tester.tap(_tile(21));
    await tester.pump();
    expect(calls, 1);
  });
}

// --- Kẹo đặc biệt hiển thị được (giá trị ô > 4, chỉ chơi đơn mới sinh ra) ---
void _specialFaceTests() {
  testWidgets('bom chéo và bom màu vẽ ra biểu tượng riêng, không vỡ bàn',
      (tester) async {
    final cells = _cells();
    cells[10] = m3CrossBase + 2; // bom chéo loại 🍓
    cells[20] = m3ColorBase + 4; // bom màu loại 🍵
    await tester.pumpWidget(_host(
      const Locale('vi'),
      Match3Panel(view: _view(cells: cells), onSwap: (_, _) => true),
    ));
    await tester.pump();

    expect(find.text('💥'), findsOneWidget);
    expect(find.text('🌈'), findsOneWidget);
    // Các ô còn lại vẫn là ô thường, không có ô nào mất mặt.
    expect(find.text(match3Icons[0]).evaluate().length, greaterThan(0));

    await tester.pumpWidget(const SizedBox());
  });

  test('match3IconFor ánh xạ đúng', () {
    expect(match3IconFor(0), match3Icons[0]);
    expect(match3IconFor(m3CrossBase + 3), '💥');
    expect(match3IconFor(m3ColorBase), '🌈');
    expect(match3IconFor(-1), '');
  });
}

// --- Bàn cờ phải vừa CHIỀU CAO ĐƯỢC CẤP, không phải nửa chiều cao màn hình ---
void _boardFitsTests() {
  testWidgets('khung thấp (banner chiếm chỗ) → bàn co lại, không tràn',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // _host bọc sẵn SingleChildScrollView (giống Đấu Trường) nên phải dựng
    // khung riêng có CHIỀU CAO GIỚI HẠN — đúng cách chơi đơn đặt bàn cờ.
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(
          children: [
            // Chiều cao còn lại nhỏ hơn nhiều so với nửa màn hình (400px) —
            // đúng tình huống banner + HUD ăn mất chỗ.
            Expanded(
              child: Center(
                child: Match3Panel(view: _view(), onSwap: (_, _) => true),
              ),
            ),
            const SizedBox(height: 560), // giả lập banner + HUD ăn chỗ
          ],
        ),
      ),
    ));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('khung cao vô hạn (trong vùng cuộn) vẫn dựng được',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(
      const Locale('vi'),
      SingleChildScrollView(
        child: Match3Panel(view: _view(), onSwap: (_, _) => true),
      ),
    ));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
  });
}
