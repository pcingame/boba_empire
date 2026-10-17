// Màn Phó bản Hội: thanh/ải/vai trò/nhận thưởng qua repository giả, không tràn ở 320px × chữ 1.5 × 7 ngôn ngữ.
library;

import 'package:boba_empire/core/format.dart';
import 'package:boba_empire/core/guild_dungeon.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_dungeon_controller.dart';
import 'package:boba_empire/guild/guild_dungeon_repository.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/guild_dungeon_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DungeonState _state({
  DungeonBar? role,
  int roleChanges = 0,
  int cleared = 0,
  Set<int> claimed = const {},
  Map<DungeonBar, int>? bars,
  Map<DungeonBar, int>? mine,
}) {
  Map<DungeonBar, int> t(int s) =>
      {for (final b in DungeonBar.values) b: dungeonTarget(b, s, 4, 0)};
  return DungeonState(
    tier: 0,
    role: role,
    roleChanges: roleChanges,
    bars: bars ?? {for (final b in DungeonBar.values) b: 0},
    targets: [t(1), t(2), t(3)],
    cleared: cleared,
    claimed: claimed,
    mine: mine ?? {for (final b in DungeonBar.values) b: 0},
    board: const [
      DungeonMember(userId: 'a', nickname: 'An', role: DungeonBar.tap, tap: 3000, off: 3600, rec: 4),
      DungeonMember(userId: 'b', nickname: 'Bình', role: null, tap: 0, off: 0, rec: 0),
    ],
  );
}

class _FakeRepo implements GuildDungeonRepository {
  _FakeRepo(this.s);
  DungeonState s;
  final submits = <({int tap, int off, int rec})>[];
  final claims = <int>[];
  int stateCalls = 0;
  GuildFailure? claimFails;

  @override
  Future<DungeonState?> state() async {
    stateCalls++;
    return s;
  }

  @override
  Future<void> submit({required int tap, required int off, required int rec}) async =>
      submits.add((tap: tap, off: off, rec: rec));

  @override
  Future<void> setRole(DungeonBar role) async {
    if (s.role != null && s.role != role) {
      if (!s.canChangeRole) throw const GuildException(GuildFailure.dungeonRoleLocked);
    }
    s = _state(
      role: role,
      roleChanges: s.role != null && s.role != role ? 1 : s.roleChanges,
      cleared: s.cleared,
      claimed: s.claimed,
      bars: s.bars,
      mine: s.mine,
    );
  }

  @override
  Future<({int gems, int coins, bool chest})> claim(int stage) async {
    if (claimFails != null) throw GuildException(claimFails!);
    claims.add(stage);
    s = _state(
        role: s.role,
        roleChanges: s.roleChanges,
        cleared: s.cleared,
        claimed: {...s.claimed, stage},
        bars: s.bars,
        mine: s.mine);
    return (gems: dungeonRewardGems[stage - 1], coins: dungeonRewardCoins[stage - 1], chest: stage == 3);
  }
}

Future<(ProviderContainer, _FakeRepo)> _pump(
  WidgetTester tester,
  DungeonState s, {
  Locale locale = const Locale('vi'),
  Size size = const Size(400, 1600),
  double textScale = 1.0,
  Widget home = const GuildDungeonPage(),
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
  final repo = _FakeRepo(s);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000000),
    guildDungeonRepositoryProvider.overrideWithValue(repo),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
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
  testWidgets('hiện ải 1, ba thanh, bảng đóng góp; giá trị offline theo giờ', (tester) async {
    final (c, _) = await _pump(tester, _state(bars: {
      DungeonBar.tap: 3000,
      DungeonBar.off: 43200,
      DungeonBar.rec: 100,
    }));
    expect(find.byKey(const Key('guild-dungeon-stage')), findsOneWidget);
    expect(find.text('Ải 1/3'), findsWidgets);
    expect(find.text('${formatNumber(3000, decimals: 0)} / ${formatNumber(6000, decimals: 0)}'), findsOneWidget);
    expect(find.text('12 giờ / 24 giờ'), findsOneWidget);
    expect(find.byKey(const Key('guild-dungeon-done')), findsOneWidget, reason: 'chỉ thanh 📜 đủ 100/100');
    expect(find.byKey(const Key('guild-dungeon-member-a')), findsOneWidget);
    expect(find.text('Bình'), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('chọn vai lần đầu → chọn lại một lần → hết lượt thì khoá', (tester) async {
    final (c, repo) = await _pump(tester, _state());
    expect(find.text('Chưa chọn vai — chọn một vai để được ×1.5.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guild-dungeon-role-tap')));
    await tester.pumpAndSettle();
    expect(repo.s.role, DungeonBar.tap);
    expect(find.text('Đóng góp đúng vai được ×1.5. Đổi vai được 1 lần trong tuần.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guild-dungeon-role-rec')));
    await tester.pumpAndSettle();
    expect(repo.s.role, DungeonBar.rec);
    expect(find.text('Bạn đã dùng lượt đổi vai tuần này.'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('guild-dungeon-role-tap'))).onSelected, isNull);
    await _end(tester, c);
  });

  testWidgets('nhận thưởng: nút chỉ bật khi ải đã qua + đủ đóng góp; ải 3 cấp 💎 + rương', (tester) async {
    final (c, repo) = await _pump(
        tester,
        _state(cleared: 3, mine: {DungeonBar.tap: 500, DungeonBar.off: 0, DungeonBar.rec: 0}));
    for (final s in [1, 2, 3]) {
      expect(tester.widget<FilledButton>(find.byKey(Key('guild-dungeon-claim-$s'))).onPressed, isNotNull);
    }
    final gems0 = c.read(gameControllerProvider).gems;
    await tester.tap(find.byKey(const Key('guild-dungeon-claim-1')));
    await tester.pumpAndSettle();
    expect(repo.claims, [1]);
    expect(c.read(gameControllerProvider).gems, gems0, reason: 'ải 1 không có 💎');
    expect(tester.widget<FilledButton>(find.byKey(const Key('guild-dungeon-claim-1'))).onPressed, isNull);
    final owned0 = c.read(gameControllerProvider).ownedAccessories.length;
    await tester.tap(find.byKey(const Key('guild-dungeon-claim-3')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).gems, gems0 + 100);
    expect(c.read(gameControllerProvider).ownedAccessories.length, greaterThanOrEqualTo(owned0));
    expect(tester.takeException(), isNull);
    await _end(tester, c);
  });

  testWidgets('chưa qua ải hoặc chưa đóng góp thì không nhận được', (tester) async {
    final (c, _) = await _pump(tester, _state(cleared: 1));
    expect(tester.widget<FilledButton>(find.byKey(const Key('guild-dungeon-claim-1'))).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.byKey(const Key('guild-dungeon-claim-2'))).onPressed, isNull);
    expect(find.textContaining('đóng góp một ít'), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('server từ chối nhận → hiện lỗi, không cộng 💎', (tester) async {
    final (c, repo) = await _pump(
        tester, _state(cleared: 3, mine: {DungeonBar.tap: 500, DungeonBar.off: 0, DungeonBar.rec: 0}));
    repo.claimFails = GuildFailure.alreadyClaimed;
    final gems0 = c.read(gameControllerProvider).gems;
    await tester.tap(find.byKey(const Key('guild-dungeon-claim-3')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).gems, gems0);
    expect(find.byType(SnackBar), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('mở màn → báo tổng luỹ kế của máy này (kèm số chạm mới)', (tester) async {
    final (c, repo) = await _pump(tester, _state());
    expect(repo.submits.every((t) => t.tap == 0), isTrue, reason: 'mới mở: chưa chạm lần nào');
    c.read(gameControllerProvider.notifier).tapCup();
    await c.read(guildDungeonControllerProvider.notifier).refresh(silent: true, force: true);
    expect(repo.submits.last.tap, 1);
    await _end(tester, c);
  });

  testWidgets('mở màn chi tiết ngay sau thẻ: không tải lại trong 15s, kéo làm mới (force) thì có', (tester) async {
    final (c, repo) = await _pump(tester, _state());
    final n = repo.stateCalls;
    expect(n, 1, reason: 'màn tự tải một lần khi mở');
    final ctrl = c.read(guildDungeonControllerProvider.notifier);
    await ctrl.refresh(silent: true);
    await ctrl.refresh(silent: true);
    expect(repo.stateCalls, n, reason: 'còn tươi → bỏ qua');
    await ctrl.refresh(silent: true, force: true);
    expect(repo.stateCalls, n + 1);
    await _end(tester, c);
  });

  testWidgets('bảng đóng góp: có nút nhắc chat cho hội viên khi còn thanh thiếu; hết thanh thiếu thì ẩn', (tester) async {
    final (c, _) = await _pump(tester, _state());
    expect(find.byKey(const Key('guild-dungeon-nudge-a')), findsOneWidget);
    expect(find.byKey(const Key('guild-dungeon-nudge-b')), findsOneWidget);
    await _end(tester, c);
    final full = {for (final b in DungeonBar.values) b: 999999999};
    final (c2, _) = await _pump(tester, _state(bars: full));
    expect(find.byKey(const Key('guild-dungeon-nudge-a')), findsNothing);
    await _end(tester, c2);
  });

  testWidgets('thẻ trên màn Hội: chấm đỏ khi có ải chờ nhận', (tester) async {
    final (c, _) = await _pump(
        tester,
        _state(cleared: 1, mine: {DungeonBar.tap: 500, DungeonBar.off: 0, DungeonBar.rec: 0}),
        home: const Scaffold(body: GuildDungeonCard()));
    expect(find.byKey(const Key('guild-dungeon-card')), findsOneWidget);
    expect(find.byKey(const Key('guild-dungeon-dot')), findsOneWidget);
    expect(find.text('Đã qua 1/3 ải'), findsOneWidget);
    await _end(tester, c);
  });

  for (final loc in AppLocalizations.supportedLocales) {
    testWidgets('không tràn ở 320px × chữ 1.5 (${loc.languageCode})', (tester) async {
      final (c, _) = await _pump(
          tester,
          _state(
              role: DungeonBar.off,
              roleChanges: 1,
              cleared: 2,
              claimed: {1},
              bars: {DungeonBar.tap: 123456, DungeonBar.off: 360000, DungeonBar.rec: 99},
              mine: {DungeonBar.tap: 500, DungeonBar.off: 5000, DungeonBar.rec: 20}),
          locale: loc,
          size: const Size(320, 3200),
          textScale: 1.5);
      expect(tester.takeException(), isNull);
      await _end(tester, c);
    });
  }
}
