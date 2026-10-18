// Trang hồ sơ của tôi: thống kê, đổi/gỡ avatar (picker + server giả), lỗi, huỷ, quá lớn, chưa liên kết bị chặn.
import 'dart:typed_data';

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/player_avatar.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/my_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements AvatarRepository {
  final uploads = <int>[];
  var cleared = 0;
  Object? error;
  @override
  Future<String> upload(Uint8List bytes) async {
    if (error != null) throw error!;
    uploads.add(bytes.length);
    return 'k${uploads.length}';
  }

  @override
  Future<void> clear() async => cleared++;
  @override
  Future<String> keyFor(String nickname) async => '';
  @override
  String urlFor(String key) => 'http://127.0.0.1:1/$key.jpg';
  final reports = <String>[];
  @override
  Future<bool> report(String nickname) async {
    if (error != null) throw error!;
    reports.add(nickname);
    return false;
  }
}

class _Linked extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveLinked('a@b.c');
}

class _Unlinked extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

Future<(ProviderContainer, _Repo, SharedPreferences)> _open(WidgetTester tester,
    {Uint8List? picked, bool linked = true, String nickname = 'Tôi'}) async {
  SharedPreferences.setMockInitialValues({if (nickname.isNotEmpty) 'leaderboard_nickname': nickname});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..stage = 5, nowMillis: 0);
  final repo = _Repo();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000),
    avatarRepositoryProvider.overrideWithValue(repo),
    avatarPickerProvider.overrideWithValue(() async => picked),
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
      home: const MyProfilePage(),
    ),
  ));
  await tester.pumpAndSettle();
  return (c, repo, prefs);
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('hiện biệt danh, thống kê, nút hạng/chia sẻ', (tester) async {
    final (c, _, _) = await _open(tester);
    expect(find.text('Tôi'), findsOneWidget);
    expect(find.text('0/${160}'), findsOneWidget);
    expect(find.byKey(const Key('my-ranks')), findsOneWidget);
    expect(find.byKey(const Key('my-avatar-remove')), findsNothing);
    await _end(tester, c);
  });

  testWidgets('chưa có biệt danh: nhắc đặt tên, ẩn nút hạng/chia sẻ', (tester) async {
    final (c, _, _) = await _open(tester, nickname: '');
    expect(find.byKey(const Key('my-ranks')), findsNothing);
    expect(find.byKey(const Key('my-share')), findsNothing);
    await _end(tester, c);
  });

  testWidgets('đổi avatar: tải lên, lưu khoá, hiện nút gỡ; gỡ → xoá server + khoá rỗng', (tester) async {
    final (c, repo, prefs) = await _open(tester, picked: Uint8List(2000));
    await tester.tap(find.byKey(const Key('my-avatar-change')));
    await tester.pumpAndSettle();
    expect(repo.uploads, [2000]);
    expect(c.read(myAvatarProvider), 'k1');
    expect(prefs.getString('profile_avatar_key'), 'k1');
    await tester.tap(find.byKey(const Key('my-avatar-remove')));
    await tester.pumpAndSettle();
    expect(repo.cleared, 1);
    expect(c.read(myAvatarProvider), '');
    await _end(tester, c);
  });

  testWidgets('huỷ chọn ảnh: không tải gì; ảnh quá lớn: báo lỗi, không tải; lỗi server: báo lỗi', (tester) async {
    var (c, repo, _) = await _open(tester, picked: null);
    await tester.tap(find.byKey(const Key('my-avatar-change')));
    await tester.pumpAndSettle();
    expect(repo.uploads, isEmpty);
    await _end(tester, c);

    (c, repo, _) = await _open(tester, picked: Uint8List(avatarMaxBytes + 1));
    await tester.tap(find.byKey(const Key('my-avatar-change')));
    await tester.pumpAndSettle();
    expect(repo.uploads, isEmpty);
    expect(find.textContaining('quá lớn'), findsOneWidget);
    await _end(tester, c);

    (c, repo, _) = await _open(tester, picked: Uint8List(10));
    repo.error = Exception('network');
    await tester.tap(find.byKey(const Key('my-avatar-change')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tải được ảnh'), findsOneWidget);
    expect(c.read(myAvatarProvider), '');
    await _end(tester, c);
  });

  testWidgets('chưa liên kết email: bị chặn bởi cổng, không tải', (tester) async {
    final (c, repo, _) = await _open(tester, picked: Uint8List(10), linked: false);
    await tester.tap(find.byKey(const Key('my-avatar-change')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('online-gate-dialog')), findsOneWidget);
    expect(repo.uploads, isEmpty);
    await _end(tester, c);
  });
}
