/// "Kho phụ kiện": lưới 50 ô khoá/mở + không tràn ở mọi ngôn ngữ, máy nhỏ +
/// chữ to (cùng khuôn story_speedrun_tabs_test.dart — lớp bug overflow đã gặp
/// thật ở cột hạng bảng xếp hạng chính).
library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _app(Locale locale) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AccessoryInventoryPage(),
    ),
  );
}

void main() {
  testWidgets('nút Gói phụ kiện rộng bằng cả bề ngang nội dung (không lệch trái)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(await _app(const Locale('vi')));
    await tester.pumpAndSettle();
    final size = tester.getSize(find.byKey(const Key('accessory-pack-button')));
    expect(size.width, 400 - 2 * 16); // lề nội dung 16 mỗi bên
  });

  testWidgets('ván mới: 0/80, cả 80 ô đều khoá ("???")', (tester) async {
    // Đủ cao để GridView dựng hết 50 ô (17 hàng) không cần cuộn — GridView.builder
    // chỉ dựng ô đang hiện trên màn, đếm thiếu nếu màn quá thấp.
    await tester.binding.setSurfaceSize(const Size(400, 7600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(await _app(const Locale('vi')));
    await tester.pumpAndSettle();

    expect(find.text('Đã có 0/80'), findsOneWidget);
    expect(find.text('???'), findsNWidgets(accessories.length + limitedAccessories.length));
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
        'không tràn ở ${locale.languageCode}, máy nhỏ + chữ to, lưới 50 ô',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
              size: Size(320, 640), textScaler: TextScaler.linear(1.6)),
          child: await _app(locale),
        ),
      );
      await tester.pumpAndSettle(); // ném FlutterError nếu RenderFlex tràn
    });
  }
}
