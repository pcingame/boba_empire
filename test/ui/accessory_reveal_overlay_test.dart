// Hiệu ứng nhận phụ kiện: hiện đủ emoji + tên + nhãn độ hiếm (+ MỚI nếu mới),
// tự gỡ khi xong, không chặn chạm, không tràn ở 320dp, tắt khi giảm chuyển động.
library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/l10n/l10n_ext.dart';
import 'package:boba_empire/ui/widgets/accessory_reveal.dart';
import 'package:boba_empire/ui/widgets/mascot.dart'
    show debugDisableMascotAnimation;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  AccessoryDrop drop,
  Locale locale, {
  VoidCallback? onTapBelow,
}) async {
  tester.view.physicalSize = const Size(320 * 2, 640 * 2);
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              key: const Key('go'),
              onPressed: () {
                onTapBelow?.call();
                playAccessoryReveal(context, drop);
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('go')));
  await tester.pump(); // khung đầu: dựng overlay, ticker bắt đầu
}

void main() {
  // flutter_test_config.dart tắt animation toàn cục; file này cần BẬT để kiểm.
  setUp(() => debugDisableMascotAnimation = false);
  tearDown(() => debugDisableMascotAnimation = true);

  for (final rarity in AccessoryRarity.values) {
    for (final isNew in [true, false]) {
      testWidgets(
        '[${rarity.name}, ${isNew ? "mới" : "trùng"}] hiện rồi tự gỡ',
        (tester) async {
          final a = accessories.firstWhere((a) => a.rarity == rarity);
          await _pump(
            tester,
            AccessoryDrop(a, isNew: isNew),
            const Locale('vi'),
          );
          await tester.pump(const Duration(milliseconds: 800));
          expect(find.text(a.emoji), findsOneWidget);
          // Có Material tổ tiên: thiếu thì Text bị gạch chân vàng trên máy thật.
          expect(
            find.ancestor(
              of: find.text(a.emoji),
              matching: find.byType(Material),
            ),
            findsWidgets,
          );
          final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
          expect(find.text(accessoryName(l10n, a.id)), findsOneWidget);
          expect(find.text(accessoryRarityLabel(l10n, rarity)), findsOneWidget);
          expect(
            find.text(l10n.marketBadgeNew),
            isNew ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('✨'),
            rarity.index >= AccessoryRarity.epic.index
                ? findsWidgets
                : findsNothing,
          );
          await tester.pump(const Duration(seconds: 3));
          expect(
            find.text(a.emoji),
            findsNothing,
            reason: 'overlay phải tự gỡ',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '[${locale.languageCode}] huyền thoại, tên dài: không tràn ở 320dp, chữ 1.3x',
      (tester) async {
        // Tên dài nhất mỗi ngôn ngữ — duyệt cả danh mục để không đoán.
        final l10n = await AppLocalizations.delegate.load(locale);
        final longest = accessories.reduce(
          (a, b) =>
              accessoryName(l10n, a.id).length >=
                  accessoryName(l10n, b.id).length
              ? a
              : b,
        );
        await _pump(tester, AccessoryDrop(longest, isNew: true), locale);
        for (var ms = 0; ms <= 2400; ms += 200) {
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull, reason: 'ms=$ms');
        }
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  testWidgets('không chặn chạm: bấm lại nút bên dưới khi hiệu ứng đang chạy', (
    tester,
  ) async {
    var taps = 0;
    final a = accessories.first;
    await _pump(
      tester,
      AccessoryDrop(a, isNew: true),
      const Locale('vi'),
      onTapBelow: () => taps++,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('go')), warnIfMissed: false);
    expect(taps, 2);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('giảm chuyển động: không dựng hiệu ứng', (tester) async {
    debugDisableMascotAnimation = true;
    final a = accessories.first;
    await _pump(tester, AccessoryDrop(a, isNew: true), const Locale('vi'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(a.emoji), findsNothing);
  });
}
