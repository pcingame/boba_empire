// Hướng dẫn lần đầu tương tác (lớp phủ trên màn chơi): bước chạm cốc → mua nâng cấp
// đầu tiên → giải thích; bỏ qua được; không chặn thao tác; đúng vị trí đích.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart';
import 'package:boba_empire/ui/tutorial_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cài đặt đọc trạng thái sao lưu đám mây (cần Supabase) — thay bằng bản "chưa
/// liên kết" để mở được hộp thoại trong test.
class _FakeCloudSave extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

const _closeKey = Key('how-to-play-close');
const _bubble = Key('ftue-bubble');

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  GameState? seed,
  Size size = const Size(400, 800),
  String? locale,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({'app_locale': ?locale});
  final prefs = await SharedPreferences.getInstance();
  if (seed != null) await GameStorage(prefs).save(seed, nowMillis: 0);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        cloudSaveControllerProvider.overrideWith(_FakeCloudSave.new),
        clockProvider.overrideWithValue(() => 0),
      ],
      child: const BobaEmpireApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(HomePage)));
}

Future<void> _end(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  setUp(() => debugAutoShowTutorial = true);
  tearDown(() => debugAutoShowTutorial = false);

  testWidgets('nút ? mở bảng Cách chơi (có icon) rồi đóng được; không tự mở',
      (tester) async {
    await _pump(tester, seed: GameState.newGame(nowMillis: 0)..tutorialSeen = true);
    expect(find.byKey(_closeKey), findsNothing);
    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('how-to-play-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(_closeKey), findsOneWidget);
    expect(find.byType(CircleAvatar), findsWidgets, reason: 'mỗi mục có icon');
    await tester.tap(find.byKey(_closeKey));
    await tester.pumpAndSettle();
    expect(find.byKey(_closeKey), findsNothing);
    await _end(tester);
  });

  testWidgets('lần chơi đầu: lớp phủ chỉ cốc, KHÔNG bật hộp thoại chữ', (tester) async {
    final c = await _pump(tester);
    expect(find.byKey(_closeKey), findsNothing);
    expect(find.byKey(_bubble), findsOneWidget);
    expect(find.text('Chạm vào ly để pha trà và kiếm Xu!'), findsOneWidget);
    expect(find.byKey(const Key('ftue-ring')), findsOneWidget);
    expect(c.read(gameControllerProvider).tutorialSeen, isFalse,
        reason: 'chưa xong thì chưa đánh dấu đã xem');
    await _end(tester);
  });

  testWidgets('vòng sáng nằm đúng quanh cốc (bước chạm)', (tester) async {
    await _pump(tester);
    final ring = tester.getRect(find.byKey(const Key('ftue-ring')));
    final cup = tester.getRect(find.byKey(ftueCupKey));
    expect((ring.center - cup.center).distance, lessThan(2));
    expect(ring.width, greaterThan(cup.width), reason: 'bao quanh, không đè khít');
    await _end(tester);
  });

  testWidgets('bố cục dịch chuyển (đổi kích thước màn): vòng sáng ĐI THEO cốc, không đứng yên',
      (tester) async {
    await _pump(tester);
    var ring = tester.getRect(find.byKey(const Key('ftue-ring')));
    var cup = tester.getRect(find.byKey(ftueCupKey));
    expect((ring.center - cup.center).distance, lessThan(2));
    final before = cup.center;

    await tester.binding.setSurfaceSize(const Size(400, 640));
    await tester.pumpAndSettle();
    cup = tester.getRect(find.byKey(ftueCupKey));
    ring = tester.getRect(find.byKey(const Key('ftue-ring')));
    expect((cup.center - before).distance, greaterThan(5),
        reason: 'cốc phải thật sự đã dịch chuyển để test có ý nghĩa');
    expect((ring.center - cup.center).distance, lessThan(2),
        reason: 'vòng sáng phải bám theo cốc mới');
    await _end(tester);
  });

  testWidgets('không chặn thao tác: chạm cốc xuyên qua lớp phủ vẫn kiếm Xu',
      (tester) async {
    final c = await _pump(tester);
    final before = c.read(gameControllerProvider).money;
    await tester.tap(find.byKey(const Key('tap-circle')));
    await tester.pump();
    expect(c.read(gameControllerProvider).money, greaterThan(before));
    await _end(tester);
  });

  testWidgets('chạm đủ để mua nổi nâng cấp đầu → chuyển sang bước "mua", ring trên nút mua',
      (tester) async {
    final c = await _pump(tester);
    expect(find.text('Chạm vào ly để pha trà và kiếm Xu!'), findsOneWidget);
    for (var i = 0; i < 60; i++) {
      if (find.text('Chạm vào ly để pha trà và kiếm Xu!').evaluate().isEmpty) break;
      await tester.tap(find.byKey(const Key('tap-circle')));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();
    expect(find.textContaining('Đủ Xu rồi!'), findsOneWidget);
    final ring = tester.getRect(find.byKey(const Key('ftue-ring')));
    final buy = tester.getRect(find.byKey(ftueBuyKey));
    expect((ring.center - buy.center).distance, lessThan(2),
        reason: 'vòng sáng quanh nút mua');
    expect(c.read(gameControllerProvider).levelOf('tra_den'), 0);
    await _end(tester);
  });

  testWidgets('đủ tiền sẵn → vào thẳng bước mua; mua xong → bước giải thích; "Đã hiểu" kết thúc',
      (tester) async {
    final c = await _pump(tester, seed: GameState.newGame(nowMillis: 0)..money = 500);
    expect(find.textContaining('Đủ Xu rồi!'), findsOneWidget);

    await tester.tap(find.byKey(ftueBuyKey)); // bấm thẳng nút mua dưới lớp phủ
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).levelOf('tra_den'), 1);
    expect(find.textContaining('Xu tự tăng mỗi giây'), findsOneWidget);
    expect(find.byKey(const Key('ftue-ok')), findsOneWidget);
    expect(c.read(gameControllerProvider).tutorialSeen, isFalse);

    await tester.tap(find.byKey(const Key('ftue-ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(_bubble), findsNothing);
    expect(c.read(gameControllerProvider).tutorialSeen, isTrue);
    await _end(tester);
  });

  testWidgets('"Bỏ qua" ở bước bất kỳ → tắt hẳn và đánh dấu đã xem', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.byKey(const Key('ftue-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(_bubble), findsNothing);
    expect(c.read(gameControllerProvider).tutorialSeen, isTrue);
    // Chạm tiếp cũng không hiện lại.
    await tester.tap(find.byKey(const Key('tap-circle')));
    await tester.pumpAndSettle();
    expect(find.byKey(_bubble), findsNothing);
    await _end(tester);
  });

  testWidgets('đã xem rồi thì không hiện; cờ tắt thì cũng không hiện', (tester) async {
    await _pump(tester, seed: GameState.newGame(nowMillis: 0)..tutorialSeen = true);
    expect(find.byKey(_bubble), findsNothing);
    await _end(tester);

    debugAutoShowTutorial = false;
    await _pump(tester);
    expect(find.byKey(_bubble), findsNothing);
    await _end(tester);
  });

  testWidgets('save cũ đã mua nhưng chưa đánh dấu đã xem → chỉ hiện bước giải thích',
      (tester) async {
    await _pump(
        tester, seed: GameState.newGame(nowMillis: 0)..levels['tra_den'] = 3);
    expect(find.byKey(const Key('ftue-ok')), findsOneWidget);
    await _end(tester);
  });

  testWidgets('tắt app giữa chừng rồi mở lại: hướng dẫn tiếp tục đúng bước', (tester) async {
    final c = await _pump(tester, seed: GameState.newGame(nowMillis: 0)..money = 500);
    expect(find.textContaining('Đủ Xu rồi!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    // Mở lại với CÙNG prefs → vẫn bước mua (chưa mua, chưa đánh dấu đã xem).
    final prefs = (await SharedPreferences.getInstance());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        cloudSaveControllerProvider.overrideWith(_FakeCloudSave.new),
        clockProvider.overrideWithValue(() => 0),
      ],
      child: const BobaEmpireApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Đủ Xu rồi!'), findsOneWidget);
    await _end(tester);
  });

  // Bóng chỉ dẫn đứng riêng (không kéo theo layout màn chính): không tràn ở màn
  // hẹp, mọi ngôn ngữ, cả 3 bước.
  for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$locale] bóng chỉ dẫn không tràn trên 320x568 ở cả 3 bước',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final seeds = {
        'tap': GameState.newGame(nowMillis: 0),
        'buy': GameState.newGame(nowMillis: 0)..money = 500,
        'explain': GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
      };
      for (final e in seeds.entries) {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await GameStorage(prefs).save(e.value, nowMillis: 0);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => 0),
          ],
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
                body: Stack(children: [TutorialOverlay(enabled: true)])),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${e.key}/$locale');
        expect(find.byKey(_bubble), findsOneWidget, reason: '${e.key}/$locale');
        final r = tester.getRect(find.byKey(_bubble));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(320));
        // Hủy cây + container giữa các bước để timer của GameController dừng.
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
}
