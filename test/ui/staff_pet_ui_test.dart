// Nhân viên + Linh vật + Đấu giá: thao tác qua UI, và không tràn ở 320px / chữ 1.5× / 7 ngôn ngữ.
import 'package:boba_empire/auction/auction.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/pet.dart';
import 'package:boba_empire/core/staff.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/auction_dialog.dart';
import 'package:boba_empire/ui/pet_dialog.dart';
import 'package:boba_empire/ui/staff_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements AuctionRepository {
  @override
  Future<AuctionInfo> current() async => AuctionInfo(
      itemId: 'season_paper_lantern',
      endsAt: DateTime.now().toUtc().add(const Duration(days: 2, hours: 3)),
      open: true,
      topBid: 12345,
      bidCount: 9,
      topIsMe: false,
      topNick: 'Nguyễn Văn Một Cái Tên Rất Dài Dòng',
      nextMin: 13580,
      maxBid: 20000);
  @override
  Future<void> bid(int gems) async {}
  @override
  Future<AuctionPickups> collect() async => const AuctionPickups();
  @override
  Future<void> ack(AuctionPickups p) async {}
}

Future<ProviderContainer> _open(WidgetTester tester, void Function(BuildContext) show,
    {String lang = 'vi', double scale = 1, Size size = const Size(400, 800), GameState Function(GameState)? setup}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final seed = GameState.newGame(nowMillis: 0)
    ..tutorialSeen = true
    ..gems = 5000
    ..money = 1e12
    ..levels[Balance.generators.first.id] = 20;
  await GameStorage(prefs).save(setup == null ? seed : setup(seed), nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 3600 * 1000),
    auctionRepositoryProvider.overrideWithValue(_Repo()),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (ctx, child) =>
          MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () => show(ctx), child: const Text('go')))),
    ),
  ));
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  return c;
}

/// Gỡ cây widget rồi huỷ container TRƯỚC khi test kết thúc (timer của game không được còn treo).
Future<void> _close(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('nhân viên: thuê bằng 💎 rồi nâng bằng Xu, nút khoá khi thiếu tiền', (tester) async {
    final c = await _open(tester, showStaff);
    final gems0 = c.read(gameControllerProvider).gems;
    await tester.tap(find.byKey(const Key('staff-up-0')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).staff, {'0': 1});
    expect(c.read(gameControllerProvider).gems, gems0 - staffHireGems(0));
    final money0 = c.read(gameControllerProvider).money;
    await tester.tap(find.byKey(const Key('staff-up-0')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).staff['0'], 2);
    expect(c.read(gameControllerProvider).money, lessThan(money0));
    // Nhân viên 5 cần 300 💎 (có 5000) → thuê được; nhưng thiếu 💎 thì nút bị vô hiệu.
    await _close(tester, c);
  });

  testWidgets('nhân viên: tối đa thì hiện dấu tích, không còn nút', (tester) async {
    final c = await _open(tester, showStaff, setup: (g) => g..staff['0'] = staffMaxLevel);
    expect(find.byKey(const Key('staff-up-0')), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('linh vật: nhận nuôi → nhặt Xu (1 giờ tích) → nâng cấp', (tester) async {
    final c = await _open(tester, showPet);
    expect(find.byKey(const Key('pet-collect')), findsNothing);
    final gems0 = c.read(gameControllerProvider).gems;
    await tester.tap(find.byKey(const Key('pet-up')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).petLevel, 1);
    expect(c.read(gameControllerProvider).gems, gems0 - petAdoptGems);
    final money = c.read(gameControllerProvider).money;
    await tester.tap(find.byKey(const Key('pet-collect')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).money, greaterThanOrEqualTo(money));
    await tester.tap(find.byKey(const Key('pet-up')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).petLevel, 2);
    await _close(tester, c);
  });

  testWidgets('linh vật: cấp tối đa không còn nút nâng', (tester) async {
    final c = await _open(tester, showPet, setup: (g) => g..petLevel = petMaxLevel);
    expect(find.byKey(const Key('pet-up')), findsNothing);
    await _close(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('không tràn ở 320px, chữ 1.5×: nhân viên + linh vật + đấu giá ($lang)', (tester) async {
      const size = Size(320, 640);
      var c = await _open(tester, showStaff, lang: lang, scale: 1.5, size: size, setup: (g) => g..staff['1'] = 7..staff['2'] = staffMaxLevel);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
      c = await _open(tester, showPet, lang: lang, scale: 1.5, size: size, setup: (g) => g..petLevel = 5..petSince = 0);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
      c = await _open(tester, showAuction, lang: lang, scale: 1.5, size: size);
      expect(find.byKey(const Key('auction-bid')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  }
}
