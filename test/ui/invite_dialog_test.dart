import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/referral/referral_controller.dart';
import 'package:boba_empire/referral/referral_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/invite_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../referral/fake_referral_repository.dart';

Future<ProviderContainer> _open(
  WidgetTester tester,
  FakeReferralRepo repo, {
  String locale = 'en',
  Size size = const Size(400, 800),
  List<String>? shared,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
    referralRepositoryProvider.overrideWithValue(repo),
    shareTextProvider.overrideWithValue((text, origin) async => shared?.add(text)),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: ui.Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showInviteDialog(ctx),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _close(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('hiện mã, thống kê và luật thưởng đúng chỗ (tham số không bị đảo)', (tester) async {
    final repo = FakeReferralRepo()
      ..current = const ReferralStatus(code: 'ABC234', invited: 5, reached: 2);
    final c = await _open(tester, repo);
    expect(find.text('ABC234'), findsOneWidget);
    expect(find.text('Invited: 5/20 · reached the goal: 2'), findsOneWidget);
    expect(find.textContaining('You get 100 💎 for each friend who reaches stage 3'),
        findsOneWidget);
    expect(find.byKey(const Key('invite-claim')), findsNothing); // chưa có gì để nhận
    await _close(tester, c);
  });

  testWidgets('chép mã vào clipboard và chia sẻ kèm mã', (tester) async {
    final shared = <String>[];
    final clips = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
        (call) async {
      if (call.method == 'Clipboard.setData') {
        clips.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final c = await _open(tester, FakeReferralRepo(), shared: shared);
    await tester.tap(find.byKey(const Key('invite-copy')));
    await tester.pump();
    expect(clips, ['ABC234']);
    expect(find.text('Code copied'), findsOneWidget);
    await tester.tap(find.byKey(const Key('invite-share')));
    await tester.pump();
    expect(shared.single, contains('ABC234'));
    await _close(tester, c);
  });

  testWidgets('có thưởng chưa nhận: nút Nhận đúng số 💎; nhận xong cộng 💎 và nút biến mất',
      (tester) async {
    final repo = FakeReferralRepo()
      ..current = const ReferralStatus(code: 'ABC234', invited: 3, reached: 3, claimable: 3);
    final c = await _open(tester, repo);
    expect(find.text('Claim +300 💎'), findsOneWidget);
    await tester.tap(find.byKey(const Key('invite-claim')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).gems, 300);
    expect(find.byKey(const Key('invite-claim')), findsNothing);
    expect(find.text('Claimed +300 💎'), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('nhập mã: thành công cộng 💎 và ẩn ô nhập; lỗi hiện thông báo đúng', (tester) async {
    final repo = FakeReferralRepo();
    final c = await _open(tester, repo);
    expect(find.byKey(const Key('invite-input')), findsOneWidget);

    repo.failures['redeem'] = ReferralFailure.notFound;
    await tester.enterText(find.byKey(const Key('invite-input')), 'zzzzzz');
    await tester.ensureVisible(find.byKey(const Key('invite-redeem')));
    await tester.tap(find.byKey(const Key('invite-redeem')));
    await tester.pumpAndSettle();
    expect(find.text('Code not found.'), findsOneWidget);
    expect(c.read(gameControllerProvider).gems, 0);

    repo.current = const ReferralStatus(code: 'ABC234', redeemed: true);
    await tester.enterText(find.byKey(const Key('invite-input')), 'abc234');
    await tester.tap(find.byKey(const Key('invite-redeem')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).gems, 100);
    expect(find.byKey(const Key('invite-input')), findsNothing);
    expect(find.byKey(const Key('invite-already')), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('đã nhập mã từ trước: không có ô nhập', (tester) async {
    final repo = FakeReferralRepo()
      ..current = const ReferralStatus(code: 'ABC234', redeemed: true);
    final c = await _open(tester, repo);
    expect(find.byKey(const Key('invite-input')), findsNothing);
    expect(find.byKey(const Key('invite-already')), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('lỗi tải (chưa liên kết email) → thông báo + Thử lại', (tester) async {
    final repo = FakeReferralRepo()..failures['status'] = ReferralFailure.emailRequired;
    final c = await _open(tester, repo);
    expect(find.text('Link your email first.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('invite-retry')));
    await tester.pumpAndSettle();
    expect(find.text('ABC234'), findsOneWidget);
    await _close(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('không tràn ở 320px khi có thưởng chưa nhận ($lang)', (tester) async {
      final repo = FakeReferralRepo()
        ..current = const ReferralStatus(code: 'ABC234', invited: 20, reached: 20, claimable: 20);
      final c = await _open(tester, repo, locale: lang, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('invite-redeem')));
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  }
}
