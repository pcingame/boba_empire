import 'package:boba_empire/auction/auction.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/auction_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake implements AuctionRepository {
  _Fake({this.open = true, this.failBid = false, this.pickups = const AuctionPickups()});
  final bool open;
  final bool failBid;
  AuctionPickups pickups;
  int top = 0;
  final bids = <int>[];
  var acked = 0;

  @override
  Future<AuctionInfo> current() async => AuctionInfo(
      itemId: 'season_sakura',
      endsAt: DateTime.now().toUtc().add(const Duration(days: 1)),
      open: open,
      topBid: top,
      bidCount: 0,
      topIsMe: false,
      topNick: null,
      nextMin: top == 0 ? 100 : top + 10,
      maxBid: 20000);

  @override
  Future<void> bid(int gems) async {
    if (failBid) throw Exception('bid_too_low');
    bids.add(gems);
    top = gems;
  }

  @override
  Future<AuctionPickups> collect() async {
    final p = pickups;
    pickups = const AuctionPickups();
    return p;
  }

  @override
  Future<void> ack(AuctionPickups p) async => acked++;
}

Future<ProviderContainer> _open(WidgetTester tester, _Fake fake, {int gems = 500}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..tutorialSeen = true..gems = gems.toDouble(), nowMillis: 0);
  late ProviderContainer c;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      auctionRepositoryProvider.overrideWithValue(fake),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Consumer(builder: (ctx, ref, _) {
        c = ProviderScope.containerOf(ctx);
        return Scaffold(body: TextButton(onPressed: () => showAuction(ctx), child: const Text('go')));
      }),
    ),
  ));
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  return c;
}

void main() {
  testWidgets('đặt giá: trừ 💎, gọi server, hiện giá mới', (tester) async {
    final fake = _Fake();
    final c = await _open(tester, fake);
    expect(c.read(gameControllerProvider).gems, 500);
    await tester.tap(find.byKey(const Key('auction-bid')));
    await tester.pumpAndSettle();
    expect(fake.bids, [100]);
    expect(c.read(gameControllerProvider).gems, 400);
    expect(find.textContaining('100'), findsWidgets);
  });

  testWidgets('server từ chối: hoàn lại 💎', (tester) async {
    final c = await _open(tester, _Fake(failBid: true));
    await tester.tap(find.byKey(const Key('auction-bid')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).gems, 500);
  });

  testWidgets('thiếu 💎: không gọi server', (tester) async {
    final fake = _Fake();
    final c = await _open(tester, fake, gems: 50);
    await tester.tap(find.byKey(const Key('auction-bid')));
    await tester.pumpAndSettle();
    expect(fake.bids, isEmpty);
    expect(c.read(gameControllerProvider).gems, 50);
  });

  testWidgets('chưa mở: không có nút đặt giá', (tester) async {
    await _open(tester, _Fake(open: false));
    expect(find.byKey(const Key('auction-closed')), findsOneWidget);
    expect(find.byKey(const Key('auction-bid')), findsNothing);
  });

  testWidgets('mở màn: nhận 💎 hoàn + món thắng rồi ack', (tester) async {
    final fake = _Fake(pickups: const AuctionPickups(refundIds: ['r1'], refundGems: 70, wonWeeks: ['2026-10-19'], wonItems: ['season_sakura', 'khong_hop_le']));
    final c = await _open(tester, fake);
    final g = c.read(gameControllerProvider);
    expect(g.gems, 570);
    expect(g.ownedLimited, ['season_sakura']);
    expect(fake.acked, 1);
  });
}
