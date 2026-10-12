// Hộp Thưởng top tuần: trạng thái rỗng, danh sách, nhận thưởng (💎 + thông báo + khoá nút), lỗi, không tràn;
// và dòng trong hub Thi đấu có chấm đỏ khi có thưởng chưa nhận.
import 'package:boba_empire/core/lb_rewards.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/lb_rewards.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/compete_hub_dialog.dart';
import 'package:boba_empire/ui/lb_rewards_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements LbRewardRepository {
  List<LbReward> rewards = [];
  Object? claimError;
  final claimed = <String>[];
  @override
  Future<List<LbReward>> status() async => [
        for (final r in rewards)
          LbReward(week: r.week, board: r.board, rank: r.rank, gems: r.gems, claimed: r.claimed || claimed.contains(r.id)),
      ];
  @override
  Future<int> claim(LbReward r) async {
    if (claimError != null) throw claimError!;
    claimed.add(r.id);
    return r.gems;
  }
}

class _Cloud extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveLinked('a@b.c');
}

LbReward _r(LbBoard b, int rank, {String week = '2026-10-12'}) =>
    LbReward(week: week, board: b, rank: rank, gems: lbRewardGemsFor(rank), claimed: false);

Future<(ProviderContainer, _Repo)> _open(WidgetTester tester,
    {List<LbReward> rewards = const [], String locale = 'vi', Size size = const Size(400, 900), bool hub = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
  final repo = _Repo()..rewards = rewards;
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000),
    lbRewardRepositoryProvider.overrideWithValue(repo),
    cloudSaveControllerProvider.overrideWith(_Cloud.new),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () => hub ? showCompeteHub(context) : showLbRewards(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  if (hub) await c.read(lbRewardsControllerProvider.notifier).refresh(force: true);
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return (c, repo);
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('chưa có thưởng: hiện lời giải thích + câu động viên', (tester) async {
    final (c, _) = await _open(tester);
    expect(find.byKey(const Key('lbr-intro')), findsOneWidget);
    expect(find.textContaining('300 / 200 / 100'), findsOneWidget);
    expect(find.byKey(const Key('lbr-empty')), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('có thưởng: liệt kê từng (bảng, tuần) kèm huy chương; nhận → +💎, thông báo, nút khoá', (tester) async {
    final (c, repo) = await _open(tester, rewards: [_r(LbBoard.income, 1), _r(LbBoard.vip, 3, week: '2026-10-05')]);
    expect(find.byKey(const Key('lbr-2026-10-12/income')), findsOneWidget);
    expect(find.byKey(const Key('lbr-2026-10-05/vip')), findsOneWidget);
    expect(find.text('🥇'), findsOneWidget);
    expect(find.text('🥉'), findsOneWidget);
    expect(find.text('Thu nhập · tuần 12/10'), findsOneWidget);
    final g0 = c.read(gameControllerProvider).gems;
    await tester.tap(find.byKey(const Key('lbr-claim-2026-10-12/income')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).gems, g0 + 300);
    expect(repo.claimed, ['2026-10-12/income']);
    expect(find.textContaining('Đã nhận 300'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('lbr-claim-2026-10-12/income'))).onPressed, isNull);
    // Phần còn lại vẫn nhận được.
    expect(tester.widget<FilledButton>(find.byKey(const Key('lbr-claim-2026-10-05/vip'))).onPressed, isNotNull);
    await _end(tester, c);
  });

  testWidgets('đã nhận rồi (server từ chối): báo, KHÔNG cộng 💎', (tester) async {
    final (c, repo) = await _open(tester, rewards: [_r(LbBoard.pearls, 2)]);
    repo.claimError = const LbRewardException(LbRewardFailure.alreadyClaimed);
    final g0 = c.read(gameControllerProvider).gems;
    await tester.tap(find.byKey(const Key('lbr-claim-2026-10-12/pearls')));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đã nhận phần thưởng này rồi.'), findsOneWidget);
    expect(c.read(gameControllerProvider).gems, g0);
    await _end(tester, c);
  });

  testWidgets('hết hạn / mất kết nối: báo đúng, không văng', (tester) async {
    final (c, repo) = await _open(tester, rewards: [_r(LbBoard.collection, 1)]);
    repo.claimError = const LbRewardException(LbRewardFailure.notFound);
    await tester.tap(find.byKey(const Key('lbr-claim-2026-10-12/collection')));
    await tester.pumpAndSettle();
    expect(find.text('Phần thưởng đã hết hạn hoặc không còn.'), findsOneWidget);
    // Snackbar được xếp hàng: dọn cái cũ để thấy cái mới ngay.
    ScaffoldMessenger.of(tester.element(find.byType(AlertDialog))).clearSnackBars();
    await tester.pumpAndSettle();
    repo.claimError = StateError('mạng');
    await tester.tap(find.byKey(const Key('lbr-claim-2026-10-12/collection')));
    await tester.pumpAndSettle();
    expect(find.text('Không kết nối được, thử lại sau nhé.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _end(tester, c);
  });

  for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$l] 360px: đủ 4 bảng, không tràn', (tester) async {
      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      addTearDown(() => FlutterError.onError = prev);
      final (c, _) = await _open(tester,
          rewards: [for (final b in LbBoard.values) _r(b, 1)], locale: l, size: const Size(360, 800));
      FlutterError.onError = prev;
      expect(errors, isEmpty, reason: errors.join('\n'));
      await _end(tester, c);
    });
  }

  testWidgets('hub Thi đấu: dòng thưởng + chấm đỏ khi có thưởng chưa nhận; mở được hộp', (tester) async {
    final (c, _) = await _open(tester, rewards: [_r(LbBoard.income, 2)], hub: true);
    expect(find.byKey(const Key('compete-lb-rewards')), findsOneWidget);
    expect(find.byKey(const Key('compete-lb-rewards-dot')), findsOneWidget);
    await tester.tap(find.byKey(const Key('compete-lb-rewards')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lbr-intro')), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('hub Thi đấu: không có thưởng → không chấm đỏ', (tester) async {
    final (c, _) = await _open(tester, hub: true);
    expect(find.byKey(const Key('compete-lb-rewards-dot')), findsNothing);
    await _end(tester, c);
  });
}
