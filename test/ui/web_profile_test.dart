import 'dart:io';
import 'dart:ui' as ui;

import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/invite_dialog.dart' show shareTextProvider;
import 'package:boba_empire/ui/settings_dialog.dart';
import 'package:boba_empire/ui/web_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCloud extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

/// Hồ sơ xếp hạng công khai: liên kết chia sẻ từ Cài đặt → web (?player=) → RPC player_profile.
void main() {
  test(
    'webProfileUrl: mã hoá tên (khoảng trắng, dấu, ký tự đặc biệt), tham số trước #',
    () {
      expect(webProfileUrl('Alice'), '$webHomeUrl/?player=Alice#board');
      for (final n in ['Trà Sữa', 'a&b=c', '日本語', 'x#y', '100%']) {
        final u = Uri.parse(webProfileUrl(n));
        expect(u.queryParameters['player'], n, reason: n);
        expect(u.fragment, 'board');
      }
    },
  );

  test(
    'web: site.js gọi RPC player_profile, SQL tồn tại, chuỗi giao diện đủ 7 ngôn ngữ',
    () {
      final js = File('docs/assets/site.js').readAsStringSync();
      expect(js, contains("rpc/player_profile"));
      expect(js, contains("get('player')"));
      expect(js, contains('textContent'));
      expect(
        RegExp(r'profileBox.*innerHTML|innerHTML.*profile').hasMatch(js),
        isFalse,
        reason: 'tên người chơi không bao giờ chèn dưới dạng HTML',
      );
      expect(
        File('docs/index.html').readAsStringSync(),
        contains('id="profileBox"'),
      );
      final sql = File('supabase/player_profile_schema.sql').readAsStringSync();
      expect(sql, contains('function player_profile(p_nickname text)'));
      expect(sql, contains('drop function if exists player_profile(text)'),
          reason: 'đổi kiểu trả về (thêm label) cần drop hàm cũ');
      expect(sql, contains("'guild'::text"), reason: 'dòng hội trong hồ sơ');
      expect(js, contains('guild: [\'lbTabGuild\''), reason: 'web hiện dòng hội');
      expect(
        sql,
        contains('grant execute on function player_profile(text) to anon'),
      );
      expect(
        sql.contains('user_id,') && sql.contains('select user_id'),
        isFalse,
        reason: 'không trả user_id',
      );
      for (final l in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
        final t = File('docs/assets/i18n/$l.js').readAsStringSync();
        expect(t, contains('"pfTitle"'), reason: l);
        expect(t, contains('"pfEmpty"'), reason: l);
        expect(
          RegExp(r'"pfTitle": "[^"]*\{n\}').hasMatch(t),
          isTrue,
          reason: l,
        );
        expect(
          RegExp(r'"pfEmpty": "[^"]*\{n\}').hasMatch(t),
          isTrue,
          reason: l,
        );
      }
    },
  );

  Future<ProviderContainer> pump(
    WidgetTester tester,
    String? nick,
    List<String> shared, {
    String locale = 'en',
    Size size = const Size(400, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({'leaderboard_nickname': ?nick});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        cloudSaveControllerProvider.overrideWith(_FakeCloud.new),
        shareTextProvider.overrideWithValue((t, _) async => shared.add(t)),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: ui.Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showSettings(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('settings-links')));
    await tester.tap(find.byKey(const Key('settings-links')));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('chưa đặt tên BXH: không có dòng chia sẻ hồ sơ', (tester) async {
    final c = await pump(tester, null, []);
    expect(find.byKey(const Key('settings-share-profile')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('đã có tên: bấm chia sẻ câu có tên + đúng liên kết hồ sơ', (
    tester,
  ) async {
    final shared = <String>[];
    final c = await pump(tester, 'Trà Sữa', shared);
    await tester.tap(find.byKey(const Key('settings-share-profile')));
    await tester.pump();
    expect(shared, [
      'See Trà Sữa’s ranks in Boba Empire: ${webProfileUrl('Trà Sữa')}',
    ]);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('320px không tràn, câu chia sẻ đủ tham số ($lang)', (
      tester,
    ) async {
      final shared = <String>[];
      final c = await pump(
        tester,
        'NamePlayer',
        shared,
        locale: lang,
        size: const Size(320, 640),
      );
      await tester.ensureVisible(
        find.byKey(const Key('settings-share-profile')),
      );
      await tester.tap(find.byKey(const Key('settings-share-profile')));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: lang);
      expect(shared.single, contains('NamePlayer'), reason: lang);
      expect(
        shared.single,
        contains(webProfileUrl('NamePlayer')),
        reason: lang,
      );
      expect(
        RegExp(r'\{(name|url)\}').hasMatch(shared.single),
        isFalse,
        reason: lang,
      );
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
