import 'dart:io';
import 'dart:ui' as ui;

import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_how_to_dialog.dart';
import 'package:boba_empire/ui/collection_share_dialog.dart';
import 'package:boba_empire/ui/settings_dialog.dart';
import 'package:boba_empire/ui/vip_how_to_dialog.dart';
import 'package:boba_empire/ui/web_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCloud extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

/// Liên kết tới trang web: đúng địa chỉ, đúng mục (anchor) có thật trong guide.html, mở bằng bộ
/// mở URL ghi đè được, và báo lỗi khi không mở được.
void main() {
  test('địa chỉ khớp tên miền trong docs/CNAME và mục (anchor) có trong docs/guide.html', () {
    final cname = File('docs/CNAME').readAsStringSync().trim();
    expect(webHomeUrl, 'https://$cname');
    expect(webGuideUrl(), '$webHomeUrl/guide.html');
    expect(webGuideUrl('vip'), '$webHomeUrl/guide.html#vip');
    final guide = File('docs/guide.html').readAsStringSync();
    for (final anchor in ['vip', 'phu-kien']) {
      expect(guide, contains('id="$anchor"'), reason: 'guide.html thiếu mục #$anchor');
    }
    // Trang hướng dẫn có trong sitemap (để Google và liên kết trong app cùng một địa chỉ).
    expect(File('docs/sitemap.xml').readAsStringSync(), contains('$webHomeUrl/guide.html'));
  });

  testWidgets('Cài đặt có 2 dòng web; bấm mở đúng địa chỉ; không mở được → báo lỗi',
      (tester) async {
    final opened = <Uri>[];
    var fail = false;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      cloudSaveControllerProvider.overrideWith(_FakeCloud.new),
      urlOpenerProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return !fail;
      }),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const ui.Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) =>
                TextButton(onPressed: () => showSettings(ctx), child: const Text('open')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Website'), findsOneWidget);
    expect(find.text('bobaempiregame.com'), findsOneWidget);
    expect(find.text('How-to guide (web)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-website')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('settings-web-guide')));
    await tester.pump();
    expect(opened, [Uri.parse(webHomeUrl), Uri.parse('$webHomeUrl/guide.html')]);
    expect(find.textContaining("Couldn't open the website"), findsNothing);

    fail = true;
    await tester.tap(find.byKey(const Key('settings-website')));
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't open the website"), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  Future<(ProviderContainer, List<Uri>)> openHowTo(
      WidgetTester tester, Future<void> Function(BuildContext) show,
      {String locale = 'en', Size size = const Size(400, 900)}) async {
    final opened = <Uri>[];
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      cloudSaveControllerProvider.overrideWith(_FakeCloud.new),
      urlOpenerProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return true;
      }),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: ui.Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(onPressed: () => show(ctx), child: const Text('open')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return (c, opened);
  }

  testWidgets('hộp Hướng dẫn VIP: nút "Full guide on the website" mở đúng mục #vip', (tester) async {
    final (c, opened) = await openHowTo(tester, showVipHowTo);
    expect(find.text('Full guide on the website'), findsOneWidget);
    await tester.tap(find.byKey(const Key('how-to-web-guide')));
    await tester.pump();
    expect(opened, [Uri.parse('$webHomeUrl/guide.html#vip')]);
    // Đóng vẫn hoạt động bình thường.
    await tester.tap(find.byKey(const Key('vip-how-to-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vip-how-to-close')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('hộp Hướng dẫn sưu tầm: nút mở đúng mục #phu-kien', (tester) async {
    final (c, opened) = await openHowTo(tester, showAccessoryHowTo);
    await tester.tap(find.byKey(const Key('how-to-web-guide')));
    await tester.pump();
    expect(opened, [Uri.parse('$webHomeUrl/guide.html#phu-kien')]);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('2 hộp hướng dẫn + Cài đặt không tràn ở 320px ($lang)', (tester) async {
      for (final show in [showVipHowTo, showAccessoryHowTo, showSettings]) {
        final (c, _) = await openHowTo(tester, show,
            locale: lang, size: const Size(320, 640));
        expect(tester.takeException(), isNull, reason: lang);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      }
    });
  }

  testWidgets('câu chia sẻ bộ sưu tập kèm địa chỉ web ở dòng cuối (mọi ngôn ngữ)', (tester) async {
    for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
      final l10n = lookupAppLocalizations(ui.Locale(lang));
      final text = collectionShareText(l10n, {'mint_leaf', 'cupcake'});
      expect(text.trimRight().endsWith(webHomeUrl), isTrue, reason: lang);
      expect(text, contains('2/'), reason: lang); // phần đếm cũ vẫn còn
    }
  });
}
