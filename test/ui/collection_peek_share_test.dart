library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:boba_empire/ui/collection_peek_dialog.dart';
import 'package:boba_empire/ui/collection_share_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  test('knownAccessoryIds bỏ id lạ (từ bản app mới hơn)', () {
    expect(knownAccessoryIds(['dragon', 'from_future', 'cupcake']),
        {'dragon', 'cupcake'});
    expect(knownAccessoryIds(const []), isEmpty);
  });

  testWidgets('xem bộ sưu tập người khác: món có hiện emoji, thiếu là ❔',
      (tester) async {
    final c = ProviderContainer(overrides: [
      collectionOfProvider('u1').overrideWith((ref) async => {'dragon'}),
    ]);
    await tester.pumpWidget(_app(
      c,
      Builder(
        builder: (ctx) => TextButton(
          onPressed: () =>
              showCollectionPeek(ctx, userId: 'u1', nickname: 'Bạn A'),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Bộ sưu tập của Bạn A'), findsOneWidget);
    expect(find.text('🐉'), findsOneWidget);
    expect(find.text('❔'), findsNWidgets(accessories.length - 1));
    c.dispose();
  });

  testWidgets('lỗi mạng: báo lỗi, không crash', (tester) async {
    final c = ProviderContainer(overrides: [
      collectionOfProvider('u1').overrideWith((ref) async => null),
    ]);
    await tester.pumpWidget(_app(
      c,
      Builder(
        builder: (ctx) => TextButton(
          onPressed: () =>
              showCollectionPeek(ctx, userId: 'u1', nickname: 'A'),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tải được bộ sưu tập'), findsOneWidget);
    expect(tester.takeException(), isNull);
    c.dispose();
  });

  testWidgets('nút chia sẻ ở Kho chép thẻ chữ vào clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..ownedAccessories.addAll(['dragon', 'cupcake']),
        nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);
    await tester.pumpWidget(_app(c, const AccessoryInventoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-share')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-count')), findsOneWidget);
    await tester.tap(find.byKey(const Key('card-copy')));
    await tester.pump();
    expect(copied, contains('2/${accessories.length}'));
    expect(copied, contains('🐉'));
    expect(copied, contains('Boba Empire'));
    expect(find.textContaining('Đã sao chép'), findsOneWidget);
    c.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('chia sẻ ảnh: xuất PNG hợp lệ của tấm thẻ, kèm câu chữ',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..ownedAccessories.addAll(['dragon']),
        nowMillis: 0);
    Uint8List? png;
    String? caption;
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      shareImageProvider.overrideWithValue((bytes, text, origin) async {
        png = bytes;
        caption = text;
      }),
    ]);
    await tester.pumpWidget(_app(c, const AccessoryInventoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-share')));
    await tester.pumpAndSettle();
    // toImage cần engine thật → chạy ngoài FakeAsync.
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.ios_share).last);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    expect(png, isNotNull);
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]); // chữ ký PNG
    expect(png!.length, greaterThan(1000));
    expect(caption, contains('1/${accessories.length}'));
    c.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('chia sẻ ảnh lỗi (share sheet ném): báo lỗi, không crash',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs)
        .save(GameState.newGame(nowMillis: 0), nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      shareImageProvider.overrideWithValue((_, _, _) async => throw 'boom'),
    ]);
    await tester.pumpWidget(_app(c, const AccessoryInventoryPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-share')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.ios_share).last);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    expect(find.textContaining('Không chia sẻ được'), findsOneWidget);
    expect(tester.takeException(), isNull);
    c.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Kho: banner cuối tuần chỉ hiện vào thứ 7/CN', (tester) async {
    Future<ProviderContainer> pumpAt(int ms) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs)
          .save(GameState.newGame(nowMillis: 0), nowMillis: 0);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => ms),
      ]);
      await tester.pumpWidget(_app(c, const AccessoryInventoryPage()));
      await tester.pumpAndSettle();
      return c;
    }

    var c = await pumpAt(0); // 1/1/1970 = thứ 5
    expect(find.byKey(const Key('weekend-banner')), findsNothing);
    c.dispose();
    await tester.pumpWidget(const SizedBox());
    c = await pumpAt(DateTime.utc(2026, 10, 3, 12).millisecondsSinceEpoch);
    expect(find.byKey(const Key('weekend-banner')), findsOneWidget);
    expect(find.textContaining('tỉ lệ rớt'), findsOneWidget);
    c.dispose();
    await tester.pumpWidget(const SizedBox());
  });
}
