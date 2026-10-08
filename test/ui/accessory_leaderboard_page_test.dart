/// Bảng xếp hạng Sưu tập: danh hiệu 3 bậc (hạng 1 "Vua Phụ Kiện", hạng 2-20
/// "Nhà Sưu Tầm" cho trường hợp test này) hiện đúng tới hạng 20, hạng 21 trở
/// đi không có. Controller giả — cùng khuôn `story_speedrun_tabs_test.dart`.
library;

import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/l10n/app_localizations_en.dart';
import 'package:boba_empire/market/accessory_market_controller.dart';
import 'package:boba_empire/leaderboard/accessory_leaderboard_controller.dart';
import 'package:boba_empire/leaderboard/accessory_leaderboard_repository.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/ui/accessory_leaderboard_page.dart';
import 'package:boba_empire/ui/collection_peek_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _entries = [
  AccessoryLeaderboardEntry(
      userId: 'u1', nickname: 'HangNhat', ownedCount: 50, rank: 1),
  AccessoryLeaderboardEntry(
      userId: 'u20', nickname: 'HangHaiMuoi', ownedCount: 20, rank: 20),
  AccessoryLeaderboardEntry(
      userId: 'u21', nickname: 'HangHaiMot', ownedCount: 19, rank: 21),
];

class _Fake extends AccessoryLeaderboardController {
  @override
  AccessoryLeaderboardViewState build() => const AccessoryLeaderboardLoaded(
        entries: _entries,
        myUserId: 'someone-else',
        myOwnedCount: 0,
      );

  @override
  Future<void> refresh({bool silent = false}) async {}
}

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {'u1': '🐉', 'u20': '', 'u21': ''};
}

Widget _app({String locale = 'vi', String? merchant}) => ProviderScope(
      overrides: [
        if (merchant != null)
          marketMerchantIdProvider.overrideWith((ref) async => merchant),
        accessoryLeaderboardControllerProvider.overrideWith(_Fake.new),
        flairCacheProvider.overrideWith(_Flair.new),
        collectionOfProvider('u1').overrideWith((ref) async => {'dragon'}),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccessoryLeaderboardPage(),
      ),
    );

void main() {
  testWidgets(
      'hạng 1 có 🥇 Vua Phụ Kiện, hạng 20 có 🏅 Nhà Sưu Tầm, hạng 21 thì không',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('🥇 Vua Phụ Kiện'), findsOneWidget);
    expect(find.text('🏅 Nhà Sưu Tầm'), findsOneWidget);
    // Hạng 21 không có dòng danh hiệu nào (không tìm thấy text chứa nó).
    expect(find.textContaining('Vua Phụ Kiện'), findsOneWidget);
    expect(find.textContaining('Nhà Sưu Tầm'), findsOneWidget);
  });

  testWidgets('huy hiệu nằm CÙNG DÒNG với tên (không đẩy tên xuống)',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final flair = tester.getCenter(find.byKey(const Key('flair-badge')));
    final name = tester.getCenter(find.text('HangNhat'));
    expect((flair.dy - name.dy).abs(), lessThan(4));
    expect(flair.dx, lessThan(name.dx));
  });

  testWidgets('bấm một hàng mở bộ sưu tập của người đó', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lb-row-u1')));
    await tester.pumpAndSettle();
    expect(find.text('Bộ sưu tập của HangNhat'), findsOneWidget);
    expect(find.text('🐉'), findsWidgets);
  });

  group('người có 2 danh hiệu (Top + Thương nhân tuần)', () {
    final l10n = AppLocalizationsEn();

    for (final locale in ['en', 'vi']) {
      testWidgets('[$locale] hiện ĐỦ cả hai danh hiệu, không bị cắt "…" ở màn 320px',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_app(locale: locale, merchant: 'u1'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final row = find.byKey(const Key('lb-row-u1'));
        final texts = find.descendant(of: row, matching: find.byType(Text));
        final all = [
          for (final w in tester.widgetList<Text>(texts)) w.data ?? '',
        ];
        // Mỗi danh hiệu là một mục riêng, nguyên vẹn.
        expect(all.any((s) => s.startsWith('🥇')), isTrue, reason: '$all');
        expect(all.any((s) => s.startsWith('🛒')), isTrue, reason: '$all');
        if (locale == 'en') {
          expect(all, contains('🛒 ${l10n.marketMerchantTitle}'));
        }
        // Mỗi danh hiệu KHÔNG bị cắt: không giới hạn dòng, không ellipsis (trước
        // đây hai danh hiệu nối thành một dòng maxLines 1 → "Weekly Mer…").
        // Lưu ý: font Ahem của flutter_test rộng gấp đôi font thật, nên không đo
        // theo pixel mà kiểm thuộc tính cắt chữ.
        for (final w in tester.widgetList<Text>(texts)) {
          final d = w.data ?? '';
          if (d.startsWith('🥇') || d.startsWith('🛒')) {
            expect(w.maxLines, isNull, reason: d);
            expect(w.overflow, isNot(TextOverflow.ellipsis), reason: d);
          }
        }
      });
    }

    testWidgets('người chỉ có 1 danh hiệu vẫn hiện bình thường', (tester) async {
      await tester.pumpWidget(_app(merchant: 'someone-else'));
      await tester.pumpAndSettle();
      expect(find.text('🥇 Vua Phụ Kiện'), findsOneWidget);
      expect(find.textContaining('🛒'), findsNothing);
    });
  });
}
