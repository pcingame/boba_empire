// Chat Hội gửi ảnh: chọn → gửi (kèm chữ), ảnh quá lớn/huỷ/lỗi, hiển thị bong bóng ảnh, không tràn ở 320px.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/chat_image.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/guild_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guild/fake_guild_repository.dart';

final _now = DateTime.utc(2026, 10, 8).millisecondsSinceEpoch;

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

Future<(ProviderContainer, FakeGuildRepository)> _open(
  WidgetTester tester,
  Uint8List? picked, {
  void Function(FakeGuildRepository)? seed,
  Size size = const Size(360, 800),
  String locale = 'vi',
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: _now)..guildWeek = 0, nowMillis: _now);
  final repo = FakeGuildRepository(mine: fakeGuild());
  seed?.call(repo);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
    guildRepositoryProvider.overrideWithValue(repo),
    flairCacheProvider.overrideWith(_Flair.new),
    guildChatImagePickerProvider.overrideWithValue(() async => picked),
  ]);
  await c.read(guildControllerProvider.notifier).refresh();
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: ui.Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: GuildChatPage()),
    ),
  ));
  await tester.pumpAndSettle();
  return (c, repo);
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  test('GuildMessage đọc image_key; server cũ không có khoá → null', () {
    final base = {'id': 1, 'user_id': 'u', 'nickname': 'A', 'body': 'x'};
    expect(GuildMessage.fromJson(base).imageKey, isNull);
    expect(GuildMessage.fromJson({...base, 'image_key': 'abc'}).imageKey, 'abc');
  });

  testWidgets('chọn ảnh → gửi, hiện bong bóng ảnh (không chữ 📷)', (tester) async {
    final (c, repo) = await _open(tester, Uint8List(1000));
    await tester.tap(find.byKey(const Key('guild-chat-attach')));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('chatPostImage'));
    expect(repo.chatMessages.single.imageKey, isNotNull);
    expect(find.byKey(Key('guild-chat-image-${repo.chatMessages.single.id}')), findsOneWidget);
    expect(find.text('📷'), findsNothing);
    await _end(tester, c);
  });

  testWidgets('chữ đang gõ được gửi kèm ảnh làm chú thích', (tester) async {
    final (c, repo) = await _open(tester, Uint8List(500));
    await tester.enterText(find.byKey(const Key('guild-chat-input')), 'nhìn nè');
    await tester.tap(find.byKey(const Key('guild-chat-attach')));
    await tester.pumpAndSettle();
    expect(repo.chatMessages.single.body, 'nhìn nè');
    expect(find.text('nhìn nè'), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('ảnh quá lớn: báo, không gửi', (tester) async {
    final (c, repo) = await _open(tester, Uint8List(guildChatImageMaxBytes + 1));
    await tester.tap(find.byKey(const Key('guild-chat-attach')));
    await tester.pumpAndSettle();
    expect(repo.calls, isNot(contains('chatPostImage')));
    expect(find.textContaining('350KB'), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('huỷ chọn ảnh: không có gì xảy ra', (tester) async {
    final (c, repo) = await _open(tester, null);
    await tester.tap(find.byKey(const Key('guild-chat-attach')));
    await tester.pumpAndSettle();
    expect(repo.calls, isNot(contains('chatPostImage')));
    expect(repo.chatMessages, isEmpty);
    await _end(tester, c);
  });

  testWidgets('gửi lỗi: báo lỗi, giữ lại chữ, không có tin', (tester) async {
    final (c, repo) = await _open(tester, Uint8List(10),
        seed: (r) => r.failures['chatPostImage'] = const GuildException(GuildFailure.chatRateLimited));
    await tester.enterText(find.byKey(const Key('guild-chat-input')), 'chú thích');
    await tester.tap(find.byKey(const Key('guild-chat-attach')));
    await tester.pumpAndSettle();
    expect(repo.chatMessages, isEmpty);
    expect(tester.widget<TextField>(find.byKey(const Key('guild-chat-input'))).controller!.text, 'chú thích');
    expect(find.byType(SnackBar), findsOneWidget);
    await _end(tester, c);
  });

  for (final lang in ['vi', 'en', 'th']) {
    testWidgets('tin ảnh + chú thích dài không tràn ở 320px ($lang)', (tester) async {
      final (c, _) = await _open(tester, null,
          size: const Size(320, 640),
          locale: lang,
          seed: (r) {
            r.chatMessages.addAll([
              GuildMessage(id: 2, userId: 'u2', nickname: 'Bob', body: '📷', imageKey: 'k1'),
              GuildMessage(id: 1, userId: 'me', nickname: 'Alice', body: 'chú thích ' * 15, imageKey: 'k2'),
            ]);
          });
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('guild-chat-image-1')), findsOneWidget);
      // Chạm ảnh mở xem to.
      await tester.tap(find.byKey(const Key('guild-chat-image-2')));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _end(tester, c);
    });
  }
}
