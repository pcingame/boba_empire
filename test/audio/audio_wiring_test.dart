import 'package:boba_empire/arena/match3_rules.dart';
import 'package:boba_empire/audio/audio_service.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/match3_board.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ghi lại các SFX được yêu cầu phát để kiểm chứng UI có gọi đúng.
class _RecordingAudio implements AudioService {
  final List<Sfx> played = [];
  @override
  void play(Sfx sfx) => played.add(sfx);
}

Future<void> _pump(WidgetTester tester, _RecordingAudio audio) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  // Seed đủ tiền để mua được nâng cấp đầu.
  await GameStorage(prefs).save(
    GameState.newGame(nowMillis: 0)..money = 1000,
    nowMillis: 0,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
        audioServiceProvider.overrideWithValue(audio),
      ],
      child: const BobaEmpireApp(),
    ),
  );
}

void main() {
  _match3SfxTests();
  testWidgets('chạm ly → phát Sfx.tap', (tester) async {
    final audio = _RecordingAudio();
    await _pump(tester, audio);

    await tester.tap(find.text('Chạm pha trà'));
    await tester.pump();

    expect(audio.played, contains(Sfx.tap));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mua nâng cấp → phát Sfx.buy', (tester) async {
    final audio = _RecordingAudio();
    await _pump(tester, audio);

    // Nút mua của dòng shop đầu tiên (Trà đen).
    await tester.tap(find.widgetWithText(FilledButton, '15 Xu'));
    await tester.pump();

    expect(audio.played, contains(Sfx.buy));

    await tester.pumpWidget(const SizedBox());
  });
}

// --- Ghép 3: ăn ô phải có tiếng (người chơi báo "ăn điểm mà im ru") ---
void _match3SfxTests() {
  testWidgets('ô nổ thì phát SFX; dây chuyền phát tiếng khác nước ăn lẻ',
      (tester) async {
    final audio = _RecordingAudio();
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Bàn dựng sẵn + một nước đi có thật, phát qua Match3Panel.
    final seq = [
      for (var i = 0, x = 4242; i < m3SeqLength; i++)
        (x = (x * 1103515245 + 12345) & 0x7fffffff, (x >> 16) % m3Types).$2,
    ];
    final board = Match3Board.initial(seq);
    final move = board.findMove()!;
    final result = board.trySwap(move.$1, move.$2);
    expect(result.valid, isTrue);

    // Bàn cờ chỉ phát hoạt ảnh khi `moveId` ĐỔI (didUpdateWidget), không phát
    // ở lần dựng đầu — nên phải dựng trước rồi mới đẩy nước đi vào.
    late StateSetter setOuter;
    var view = Match3View(cells: Match3Board.initial(seq).cells);
    await tester.pumpWidget(ProviderScope(
      overrides: [audioServiceProvider.overrideWithValue(audio)],
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            setOuter = setState;
            return Match3Panel(view: view, onSwap: (_, _) => true);
          }),
        ),
      ),
    ));
    await tester.pump();
    expect(audio.played, isEmpty, reason: 'chưa đi nước nào thì chưa có tiếng');

    setOuter(() => view = Match3View(
          cells: board.cells,
          frames: result.frames,
          moveId: 1,
        ));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(audio.played, isNotEmpty, reason: 'ăn ô mà không phát tiếng nào');
    // Bước 1 luôn là tiếng "ăn lẻ".
    expect(audio.played.first, Sfx.tap);

    await tester.pumpWidget(const SizedBox());
  });
}
