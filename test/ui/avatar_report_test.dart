// Báo cáo ảnh vi phạm trên hồ sơ công khai: xác nhận → gửi; huỷ không gửi; không báo cáo ảnh của mình; lỗi; cổng email.
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/player_avatar.dart';
import 'package:boba_empire/leaderboard/player_profile.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/player_profile_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class _Repo implements AvatarRepository {
  final reports = <String>[];
  Object? error;
  @override
  Future<bool> report(String n) async {
    if (error != null) throw error!;
    reports.add(n);
    return false;
  }

  @override
  Future<String> upload(Uint8List b) async => 'k';
  @override
  Future<void> clear() async {}
  @override
  Future<String> keyFor(String n) async => 'k';
  @override
  String urlFor(String key) => 'http://127.0.0.1:1/$key.jpg';
}

class _Linked extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveLinked('a@b.c');
}

class _Unlinked extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

Future<(ProviderContainer, _Repo)> _open(WidgetTester tester,
    {String viewing = 'Bob', String me = 'Tôi', bool linked = true}) async {
  SharedPreferences.setMockInitialValues({'leaderboard_nickname': me});
  final prefs = await SharedPreferences.getInstance();
  final repo = _Repo();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    avatarRepositoryProvider.overrideWithValue(repo),
    playerProfileProvider(viewing).overrideWith((ref) async => [const ProfileRank(ProfileBoard.income, 1, 100)]),
    cloudSaveControllerProvider.overrideWith(linked ? _Linked.new : _Unlinked.new),
  ]);
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            key: const Key('open'),
            onPressed: () => showPlayerProfile(ctx, viewing),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return (c, repo);
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('báo cáo: xác nhận rồi gửi đúng tên, hiện thông báo', (tester) async {
    final (c, repo) = await _open(tester);
    await tester.tap(find.byKey(const Key('avatar-report')));
    await tester.pumpAndSettle();
    expect(repo.reports, isEmpty, reason: 'chưa xác nhận');
    await tester.tap(find.byKey(const Key('avatar-report-send')));
    await tester.pumpAndSettle();
    expect(repo.reports, ['Bob']);
    expect(find.text('Đã gửi báo cáo. Cảm ơn bạn!'), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('huỷ ở hộp xác nhận: không gửi', (tester) async {
    final (c, repo) = await _open(tester);
    await tester.tap(find.byKey(const Key('avatar-report')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(repo.reports, isEmpty);
    await _end(tester, c);
  });

  testWidgets('xem hồ sơ của chính mình: không có nút báo cáo', (tester) async {
    final (c, _) = await _open(tester, viewing: 'Tôi');
    expect(find.byKey(const Key('avatar-image')), findsOneWidget, reason: 'ảnh vẫn hiện');
    expect(find.byKey(const Key('avatar-report')), findsNothing);
    await _end(tester, c);
  });

  testWidgets('lỗi server: báo lỗi; chưa liên kết: bị cổng chặn, không gửi', (tester) async {
    var (c, repo) = await _open(tester);
    repo.error = Exception('x');
    await tester.tap(find.byKey(const Key('avatar-report')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('avatar-report-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không gửi được báo cáo'), findsOneWidget);
    await _end(tester, c);

    (c, repo) = await _open(tester, linked: false);
    await tester.tap(find.byKey(const Key('avatar-report')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('avatar-report-send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('online-gate-dialog')), findsOneWidget);
    expect(repo.reports, isEmpty);
    await _end(tester, c);
  });
}
