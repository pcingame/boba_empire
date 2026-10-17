/// Mốc sưu tập theo bộ: định nghĩa bộ, KHỚP SQL, nhận qua controller (server giả) và Kho (320px, 7 ngôn ngữ).
library;

import 'dart:io';

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/collection_sets.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/state/game_controller.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Tạo NGOÀI FakeAsync: GoTrueClient mở timer định kỳ mà testWidgets coi là timer treo.
late final SupabaseClient _client;

class _FakeRepo extends AccessoryMarketRepository {
  _FakeRepo() : super(_client);
  Object? error;
  int calls = 0;
  Map<String, int> serverCopies = {};
  final registered = <String, int>{};

  @override
  Future<Map<String, int>> fetchServerCopies() async => serverCopies;
  @override
  Future<void> registerDrop(String accessoryId, {int copies = 1}) async => registered[accessoryId] = copies;
  @override
  Future<int> claimCollectionSet(String setId) async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return collectionSets.firstWhere((s) => s.id == setId).coins;
  }
}

GameState _own(CollectionSet set, {int missing = 0}) => GameState.newGame(nowMillis: 0)
  ..ownedAccessories.addAll(set.members.skip(missing));

Future<(ProviderContainer, GameController, _FakeRepo)> _setup(GameState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
  addTearDown(c.dispose);
  final ctrl = c.read(gameControllerProvider.notifier);
  final repo = _FakeRepo();
  ctrl.debugMarketRepo = repo;
  return (c, ctrl, repo);
}

void main() {
  setUpAll(() => _client = SupabaseClient('http://localhost', 'anon'));
  final legendary = collectionSets.first;

  test('8 bộ: 4 độ hiếm phủ kín 160 món, 4 họ phủ kín 160 món, tổng thưởng 2850', () {
    final byRarity = collectionSets.where((s) => s.rarity != null).expand((s) => s.members).toList();
    final byFamily = collectionSets.where((s) => s.family != null).expand((s) => s.members).toList();
    expect(byRarity.toSet().length, accessories.length);
    expect(byRarity.length, accessories.length);
    expect(byFamily.toSet().length, accessories.length);
    expect(byFamily.length, accessories.length);
    expect(collectionSets.fold<int>(0, (a, s) => a + s.coins), 2850);
    expect(legendary.members.length, 9);
  });

  test('bảng bộ + thưởng trong Dart KHỚP HỆT SQL', () {
    final sql = File('supabase/accessory_market_schema.sql').readAsStringSync();
    final rows = {
      for (final m in RegExp(r"\('((?:rarity|family)_\w+)','(\w+)'\)").allMatches(sql))
        '${m.group(1)}/${m.group(2)}'
    };
    expect(rows, {for (final s in collectionSets) for (final id in s.members) '${s.id}/$id'});
    final fn = sql.substring(sql.indexOf('function claim_collection_set'));
    final body = fn.substring(fn.indexOf('case p_set'), fn.indexOf('else null end'));
    final rewards = {
      for (final m in RegExp(r"when '(\w+)' then (\d+)").allMatches(body)) m.group(1)!: int.parse(m.group(2)!)
    };
    expect(rewards, {for (final s in collectionSets) s.id: s.coins});
    expect(sql, contains('2850 Xu Chợ'));
  });

  test('tiến độ + save: thiếu 1 món chưa đủ; round-trip; save cũ/hỏng = rỗng', () {
    expect(setComplete(_own(legendary, missing: 1), legendary), isFalse);
    final s = _own(legendary);
    expect(setComplete(s, legendary), isTrue);
    expect(setsClaimable(s), 1);
    s.collectionSetsClaimed.add(legendary.id);
    expect(setsClaimable(s), 0);
    expect(GameState.fromJson(s.toJson()).collectionSetsClaimed, [legendary.id]);
    final j = s.toJson()..remove('collectionSetsClaimed');
    expect(GameState.fromJson(j).collectionSetsClaimed, isEmpty);
    final bad = s.toJson()..['collectionSetsClaimed'] = [1, null, 'family_tap'];
    expect(GameState.fromJson(bad).collectionSetsClaimed, ['family_tap']);
  });

  group('controller', () {
    test('thành công: Xu Chợ, đánh dấu đã nhận, bù món local lên server', () async {
      final (c, ctrl, repo) = await _setup(_own(legendary));
      final r = await ctrl.claimCollectionSet(legendary.id);
      expect((r.coins, r.error), (150, null));
      expect(repo.registered.length, 9);
      expect(c.read(gameControllerProvider).collectionSetsClaimed, [legendary.id]);
    });

    test('thiếu món / bộ lạ: không gọi server', () async {
      final (_, ctrl, repo) = await _setup(_own(legendary, missing: 1));
      expect((await ctrl.claimCollectionSet(legendary.id)).error, 'not_reached');
      expect((await ctrl.claimCollectionSet('nope')).error, 'not_reached');
      expect(repo.calls, 0);
    });

    test('mất mạng: không đánh dấu, thử lại được; already_claimed: đánh dấu để ẩn nút', () async {
      final (c, ctrl, repo) = await _setup(_own(legendary));
      repo.error = Exception('timeout');
      expect((await ctrl.claimCollectionSet(legendary.id)).error, 'network');
      expect(c.read(gameControllerProvider).collectionSetsClaimed, isEmpty);
      repo.error = Exception('already_claimed');
      expect((await ctrl.claimCollectionSet(legendary.id)).error, 'already_claimed');
      expect(c.read(gameControllerProvider).collectionSetsClaimed, [legendary.id]);
    });
  });

  for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
    testWidgets('Kho ($loc) 320px × chữ 1.5: chip bộ không tràn; bộ đủ có nút nhận, bấm → đã nhận', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 2800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final (c, ctrl, repo) = await _setup(_own(legendary));
      ctrl.debugMarketRepo = repo;
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(320, 2800), textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            locale: Locale(loc),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AccessoryInventoryPage(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(Key('set-claim-${legendary.id}')), findsOneWidget);
      expect(find.byKey(const Key('set-family_tap')), findsOneWidget);
      await tester.ensureVisible(find.byKey(Key('set-claim-${legendary.id}')));
      await tester.tap(find.byKey(Key('set-claim-${legendary.id}')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).collectionSetsClaimed, [legendary.id]);
      expect(find.byKey(Key('set-${legendary.id}')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose(); // dọn timer của controller
    });
  }
}
