/// Cập nhật tức thời khi trang đang mở: món mới / mốc / huy hiệu hiện ngay,
/// không cần thoát ra vào lại.
library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tạo NGOÀI FakeAsync (setUpAll): GoTrueClient mở timer định kỳ mà testWidgets
// sẽ coi là timer treo.
late final SupabaseClient _client;

class _OkRepo extends AccessoryMarketRepository {
  _OkRepo() : super(_client);
  @override
  Future<Map<String, int>> fetchServerCopies() async => {};
  @override
  Future<void> registerDrop(String accessoryId, {int copies = 1}) async {}
  @override
  Future<int> claimCollectionMilestone(int milestone) async => 20;
}

Widget _app(ProviderContainer c, Widget home) => UncontrolledProviderScope(
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
        home: home,
      ),
    );

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
}

void main() {
  setUpAll(() => _client = SupabaseClient('http://localhost', 'anon'));

  testWidgets('Kho đang mở: món mới, mốc 10 và nhận thưởng hiện ngay',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = await _container();
    final ctrl = c.read(gameControllerProvider.notifier)
      ..debugMarketRepo = _OkRepo();
    await tester.pumpWidget(_app(c, const AccessoryInventoryPage()));
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNothing);

    // Món đầu tiên (như vừa quay trúng rương): ô đổi từ ❔ sang emoji NGAY.
    final first = accessories.first;
    final cell = find.descendant(
        of: find.byKey(Key('accessory-cell-${first.id}')),
        matching: find.text(first.emoji));
    expect(cell, findsNothing);
    ctrl.addOwnedAccessoryLocally(first.id);
    await tester.pump();
    expect(cell, findsOneWidget);

    // Đủ 10 món: nút nhận mốc xuất hiện ngay.
    for (final a in accessories.skip(1).take(9)) {
      ctrl.addOwnedAccessoryLocally(a.id);
    }
    await tester.pump();
    expect(find.byType(ActionChip), findsOneWidget);

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('✓ 10'), findsOneWidget);
    expect(find.byKey(const Key('collection-title')), findsOneWidget);
    c.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Kho: gỡ trang trong lúc đang chờ server không crash',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = await _container();
    final ctrl = c.read(gameControllerProvider.notifier)
      ..debugMarketRepo = _OkRepo();
    for (final a in accessories.take(10)) {
      ctrl.addOwnedAccessoryLocally(a.id);
    }
    await tester.pumpWidget(_app(c, const AccessoryInventoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ActionChip));
    // Gỡ trang NGAY sau khi bấm, trước khi lời gọi server trả về.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    c.dispose();
  });

  testWidgets('FlairBadge: cache đổi khi đang hiển thị thì huy hiệu hiện ngay',
      (tester) async {
    final c = ProviderContainer(overrides: [
      flairCacheProvider.overrideWith(_EmptyCache.new),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: FlairBadge(userId: 'u1')),
    ));
    expect(find.byKey(const Key('flair-badge')), findsNothing);
    (c.read(flairCacheProvider.notifier) as _EmptyCache).put('u1', '🪽');
    await tester.pump();
    expect(find.text('🪽'), findsOneWidget);
    // Gỡ widget rồi để timer 50ms của cache chạy: không được ném.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    c.dispose();
  });
}

class _EmptyCache extends FlairCache {
  @override
  Map<String, String> build() => {'u1': ''};
  void put(String id, String emoji) => state = {...state, id: emoji};
}
