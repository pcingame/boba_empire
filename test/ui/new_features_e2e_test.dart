// Đi qua app THẬT (BobaEmpireApp) bằng nút thật: Trò chơi → Quán của tôi → từng mục; Thi đấu → Sự kiện tuần → Đấu giá;
// Cài đặt → Thống kê. Bắt lỗi nối dây (context sau pop, khoá cổng, phím) mà test từng hộp riêng lẻ không thấy.
import 'dart:io';

import 'package:boba_empire/auction/auction.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Cloud extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveLinked('a@b.c');
}

class _Repo implements AuctionRepository {
  @override
  Future<AuctionInfo> current() async => AuctionInfo(
      itemId: 'season_sakura', endsAt: DateTime.now().toUtc().add(const Duration(days: 1)), open: true, topBid: 0, bidCount: 0, topIsMe: false, topNick: null, nextMin: 100, maxBid: 20000);
  @override
  Future<void> bid(int gems) async {}
  @override
  Future<AuctionPickups> collect() async => const AuctionPickups();
  @override
  Future<void> ack(AuctionPickups p) async {}
}

Future<ProviderContainer> _app(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 850));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..tutorialSeen = true
        ..gems = 5000
        ..money = 1e12
        ..levels[Balance.generators.first.id] = 10,
      nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
    cloudSaveControllerProvider.overrideWith(_Cloud.new),
    auctionRepositoryProvider.overrideWithValue(_Repo()),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  expect(f, findsOneWidget, reason: key);
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _closeDialog(WidgetTester tester) async {
  await tester.tapAt(const Offset(2, 2)); // chạm vùng mờ ngoài hộp
  await tester.pumpAndSettle();
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('Trò chơi → Quán của tôi → Nhân viên / Khách quen / Thời tiết / Linh vật đều mở và thao tác được', (tester) async {
    final c = await _app(tester);

    await _tap(tester, 'match3-button');
    await _tap(tester, 'games-shop');
    await _tap(tester, 'shop-staff');
    await _tap(tester, 'staff-up-0');
    expect(c.read(gameControllerProvider).staff['0'], 1);
    await _closeDialog(tester);

    await _tap(tester, 'match3-button');
    await _tap(tester, 'games-shop');
    await _tap(tester, 'shop-regulars');
    expect(find.byType(AlertDialog), findsOneWidget);
    await _closeDialog(tester);

    await _tap(tester, 'match3-button');
    await _tap(tester, 'games-shop');
    await _tap(tester, 'shop-delivery');
    await _tap(tester, 'delivery-tier-0');
    expect(c.read(gameControllerProvider).contractTier, 0);
    await _closeDialog(tester);

    await _tap(tester, 'match3-button');
    await _tap(tester, 'games-shop');
    await _tap(tester, 'shop-pet');
    await _tap(tester, 'pet-up');
    expect(c.read(gameControllerProvider).petLevel, 1);
    await _closeDialog(tester);

    await _end(tester, c);
  });

  testWidgets('Thi đấu → Đấu giá mở được (đã liên kết email)', (tester) async {
    final c = await _app(tester);
    await _tap(tester, 'compete-button');
    await _tap(tester, 'compete-auction');
    expect(find.byKey(const Key('auction-bid')), findsOneWidget);
    await _closeDialog(tester);
    await _end(tester, c);
  });

  testWidgets('Cài đặt → Thống kê & ảnh khoe mở được và có số liệu', (tester) async {
    final c = await _app(tester);
    await _tap(tester, 'settings-button');
    await _tap(tester, 'settings-stats');
    expect(find.text('🧋 Boba Empire'), findsOneWidget);
    await _closeDialog(tester);
    await _end(tester, c);
  });

  test('cổng email: Đấu giá/Boss chỉ gọi từ hộp Thi đấu, ngay sau ensureOnlineLinked', () {
    final callers = <String, List<String>>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('/l10n/')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final name in ['showAuction', 'showWorldBoss']) {
          if (!lines[i].contains('$name(') || lines[i].contains('Future<void> $name')) continue;
          callers.putIfAbsent(name, () => []).add(f.path);
          final window = lines.sublist(i < 6 ? 0 : i - 6, i + 1).join('\n');
          expect(window, contains('ensureOnlineLinked'), reason: '${f.path}:${i + 1}');
        }
      }
    }
    expect(callers['showAuction'], ['lib/ui/compete_hub_dialog.dart']);
    expect(callers['showWorldBoss'], ['lib/ui/compete_hub_dialog.dart']);
  });
}
