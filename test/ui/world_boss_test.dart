// Boss Thế Giới: hằng số khớp SQL, mô hình mốc, trang (máu, mốc, nhận quà chỉ cộng 💎 SAU khi server OK,
// lỗi), chấm đỏ, không tràn ở 320px mọi ngôn ngữ.
import 'dart:io';

import 'package:lottie/lottie.dart';

import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/raid.dart';
import 'package:boba_empire/core/world_boss.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/world_boss_page.dart';
import 'package:boba_empire/world_boss/world_boss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Linked extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveLinked('a@b.c');
}

class _Unlinked extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

class _Ad implements AdService {
  _Ad(this.outcome);
  final RewardOutcome outcome;
  int shown = 0;
  @override
  Future<RewardOutcome> showRewardedAd() async {
    shown++;
    return outcome;
  }
}

class _Repo implements WorldBossRepository {
  Object? claimDayError;
  int dayGems = 0;
  @override
  Future<int> claimDay(int phase) async {
    log.add('claimDay:$phase');
    if (claimDayError != null) throw claimDayError!;
    data = WorldBossState(
        boss: data.boss, hp: data.hp, damage: data.damage, mine: data.mine, rank: data.rank, players: data.players,
        endsAtSeconds: data.endsAtSeconds, claimed: data.claimed, board: data.board, auto: data.auto, adLeft: data.adLeft,
        daily: WorldBossState(
            boss: 0, hp: data.daily!.hp, damage: data.daily!.damage, mine: data.daily!.mine, rank: 1, players: 5,
            endsAtSeconds: data.daily!.endsAtSeconds, claimed: {...data.daily!.claimed, phase}, board: const [],
            minDamage: worldBossDayMinDamageToClaim));
    return dayGems;
  }

  Object? adError;
  int adLeft = 4;
  int adCalls = 0;
  @override
  Future<int> adStrike() async {
    adCalls++;
    if (adError != null) throw adError!;
    return adLeft;
  }

  WorldBossState data = _state();
  Object? claimError;
  Object? buyError;
  bool buyFresh = true;
  final log = <String>[];

  @override
  Future<WorldBossState> state() async => data;

  @override
  Future<void> submit({required int tap, required int off, required int rec}) async => log.add('submit:$tap:$off:$rec');

  @override
  Future<bool> buyAuto() async {
    log.add('buyAuto');
    if (buyError != null) throw buyError!;
    final fresh = buyFresh;
    data = WorldBossState(
        boss: data.boss, hp: data.hp, damage: data.damage, mine: data.mine, rank: data.rank, players: data.players,
        endsAtSeconds: data.endsAtSeconds, claimed: data.claimed, board: data.board, auto: true);
    return fresh;
  }

  @override
  Future<({int gems, bool chest})> claim(int phase) async {
    log.add('claim:$phase');
    if (claimError != null) throw claimError!;
    data = WorldBossState(
        boss: data.boss, hp: data.hp, damage: data.damage, mine: data.mine, rank: data.rank, players: data.players,
        endsAtSeconds: data.endsAtSeconds, claimed: {...data.claimed, phase}, board: data.board);
    return (gems: worldBossPhaseGems[phase - 1], chest: phase == worldBossPhases);
  }
}

WorldBossState _state({int hp = 100000, int damage = 45000, int mine = 500, int boss = 0, Set<int> claimed = const {}}) =>
    WorldBossState(
        boss: boss, hp: hp, damage: damage, mine: mine, rank: mine > 0 ? 2 : null, players: 37,
        endsAtSeconds: 1000 + 3 * 86400, claimed: claimed,
        board: [const WorldBossRow('An', 20000), const WorldBossRow('Binh', 500)]);

Future<(ProviderContainer, _Repo)> _open(WidgetTester tester, _Repo repo,
    {String locale = 'vi', Size size = const Size(400, 900), double gems = 0, AdService? ad, bool adsRemoved = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..gems = gems..adsRemoved = adsRemoved, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000 * 1000),
    worldBossRepositoryProvider.overrideWithValue(repo),
    cloudSaveControllerProvider.overrideWith(_Linked.new),
    if (ad != null) adServiceProvider.overrideWithValue(ad),
  ]);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WorldBossPage(),
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
  test('hằng số khớp SQL', () {
    final sql = File('supabase/world_boss_schema.sql').readAsStringSync();
    int num(String fn) => int.parse(RegExp('function $fn\\(\\)[^;]*?select (\\d+)').firstMatch(sql)!.group(1)!);
    expect(num('wb_base_hp'), worldBossBaseHp);
    expect(num('wb_dmg_per_tap'), worldBossDmgPerTap);
    expect(num('wb_off_seconds_per_dmg'), worldBossOffSecondsPerDmg);
    expect(num('wb_dmg_per_rec'), worldBossDmgPerRec);
    expect(num('wb_min_damage_to_claim'), worldBossMinDamageToClaim);
    expect(num('wb_auto_per_hour'), worldBossAutoPerHour);
    expect(num('wb_ad_damage'), worldBossAdDamage);
    expect(num('wb_day_base_hp'), worldBossDayBaseHp);
    expect(num('wb_day_min_damage_to_claim'), worldBossDayMinDamageToClaim);
    expect(num('wb_ad_per_day'), worldBossAdPerDay);
    final gems = RegExp(r'when (\d) then (\d+)').allMatches(sql.substring(sql.indexOf('wb_phase_gems'))).map((m) => int.parse(m.group(2)!)).toList();
    expect(gems, worldBossPhaseGems);
    expect(worldBossEmoji.length, worldBossCount);
  });

  test('file Lottie boss đọc được (không hỏng, không ảnh ngoài)', () async {
    final bytes = File('assets/anim/boss_wolfie.json').readAsBytesSync();
    final comp = await LottieComposition.fromBytes(bytes);
    expect(comp.duration.inMilliseconds, greaterThan(500));
    expect(bytes.length, lessThan(200 * 1024));
  });

  test('file Lottie boss ngày đọc được', () async {
    final bytes = File('assets/anim/boss_frankenstein.json').readAsBytesSync();
    final comp = await LottieComposition.fromBytes(bytes);
    expect(comp.duration.inMilliseconds, greaterThan(500));
    expect(bytes.length, lessThan(200 * 1024));
  });

  test('thưởng boss ngày khớp SQL (💎 chỉ mốc cuối)', () {
    final sql = File('supabase/world_boss_schema.sql').readAsStringSync();
    final m = RegExp(r'wb_day_phase_gems[^;]*?when 5 then (\d+) else (\d+)').firstMatch(sql)!;
    expect([for (var p = 1; p <= 5; p++) p == 5 ? int.parse(m.group(1)!) : int.parse(m.group(2)!)], worldBossDayPhaseGems);
    expect(worldBossDayPhaseSeconds.length, worldBossPhases);
  });

  test('sát thương ước tính khớp công thức SQL', () {
    expect(worldBossDamage(tap: 1000, off: 3000, rec: 10), 1500);
  });

  test('mốc: khớp SQL tổng×5 ≥ máu×mốc; nhận cần đủ sát thương và chưa nhận', () {
    final s = _state(hp: 100000, damage: 45000, mine: 500);
    expect(s.phaseReached(2), isTrue);
    expect(s.phaseReached(3), isFalse);
    expect(s.canClaim(1), isTrue);
    expect(s.canClaim(3), isFalse);
    expect(s.claimableCount, 2);
    expect(_state(mine: 50).canClaim(1), isFalse, reason: 'dưới sát thương tối thiểu');
    expect(_state(claimed: {1}).canClaim(1), isFalse);
    expect(_state(damage: 100000).defeated, isTrue);
    expect(_state(damage: 999999).hpLeft, 0);
  });

  testWidgets('trang: tên boss, máu còn lại, mốc đã phá có nút Nhận, mốc chưa phá khoá', (tester) async {
    final (c, repo) = await _open(tester, _Repo());
    expect(find.byKey(const Key('wb-name')), findsOneWidget);
    expect(find.byKey(const Key('wb-boss')), findsOneWidget);
    expect(repo.log.first, startsWith('submit:'), reason: 'báo sát thương trước khi tải');
    await tester.scrollUntilVisible(find.byKey(const Key('wb-claim-3')), 300, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<FilledButton>(find.byKey(const Key('wb-claim-1'))).onPressed, isNotNull);
    expect(tester.widget<FilledButton>(find.byKey(const Key('wb-claim-2'))).onPressed, isNotNull);
    expect(tester.widget<FilledButton>(find.byKey(const Key('wb-claim-3'))).onPressed, isNull);
    await tester.ensureVisible(find.byKey(const Key('wb-seg-board')));
    await tester.tap(find.byKey(const Key('wb-seg-board')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('wb-row-1')), 300, scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('wb-row-1')), findsOneWidget);
    expect(find.byKey(const Key('wb-claim-1')), findsNothing, reason: 'tab bảng ẩn danh sách mốc');
    await _end(tester, c);
  });

  testWidgets('nhận mốc: gọi server rồi mới cộng 💎; nút chuyển thành Đã nhận', (tester) async {
    final (c, repo) = await _open(tester, _Repo());
    final before = c.read(gameControllerProvider).gems;
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wb-claim-1')));
    await tester.pumpAndSettle();
    expect(repo.log, contains('claim:1'));
    expect(c.read(gameControllerProvider).gems, before + worldBossPhaseGems[0]);
    expect(c.read(gameControllerProvider).money, greaterThan(0)); // + Xu thưởng thêm
    expect(find.byKey(const Key('wb-claim-1')), findsNothing);
    await _end(tester, c);
  });

  testWidgets('boss tuần chưa tới Chủ Nhật: nút đánh/xem QC mờ, hiện đếm ngược mở', (tester) async {
    final repo = _Repo();
    repo.data = WorldBossState(
        boss: 0, hp: 100000, damage: 0, mine: 0, rank: null, players: 0, endsAtSeconds: 1000 + 3 * 86400,
        claimed: const {}, board: const [], open: false, startsAtSeconds: 1000 + 86400);
    final (c, _) = await _open(tester, repo);
    expect(tester.widget<FilledButton>(find.byKey(const Key('wb-hit'))).onPressed, isNull);
    expect(tester.widget<GestureDetector>(find.byKey(const Key('wb-boss-tap'))).onTap, isNull);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('wb-ad'))).onPressed, isNull);
    expect(find.textContaining('Chủ Nhật'), findsWidgets);
    await _end(tester, c);
  });

  testWidgets('server cũ không gửi open → coi như mở', (tester) async {
    expect(WorldBossState.fromJson({'hp': 10, 'damage': 0}).open, isTrue);
    expect(WorldBossState.fromJson({'hp': 10, 'damage': 0, 'open': false}).open, isFalse);
  });

  testWidgets('server từ chối: KHÔNG cộng 💎, báo lỗi', (tester) async {
    final repo = _Repo()..claimError = StateError('already claimed');
    final (c, _) = await _open(tester, repo);
    final before = c.read(gameControllerProvider).gems;
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wb-claim-1')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).gems, before);
    expect(find.byType(SnackBar), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('chạm boss / nút ⚔️: +1 chạm vào bộ đếm, máu giảm ngay, gom lại rồi báo server', (tester) async {
    final (c, repo) = await _open(tester, _Repo());
    final before = c.read(gameControllerProvider.notifier).dungeonProgress().tap;
    repo.log.clear();
    repo.data = _state(damage: 70000);
    await tester.ensureVisible(find.byKey(const Key('wb-boss-tap')));
    await tester.tap(find.byKey(const Key('wb-boss-tap')));
    await tester.tap(find.byKey(const Key('wb-boss-tap')));
    await tester.tap(find.byKey(const Key('wb-hit')));
    await tester.pump();
    expect(c.read(gameControllerProvider.notifier).dungeonProgress().tap, before + 3);
    expect(find.text('+3 💥'), findsOneWidget);
    expect(repo.log.where((e) => e.startsWith('submit')), isEmpty, reason: 'chưa tới 700ms thì chưa báo');
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(repo.log.where((e) => e.startsWith('submit')).length, 1, reason: 'ba lần chạm gom thành một lần báo');
    expect(find.byKey(const Key('wb-pending')), findsNothing);
    await tester.scrollUntilVisible(find.byKey(const Key('wb-claim-3')), 200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<FilledButton>(find.byKey(const Key('wb-claim-3'))).onPressed, isNotNull);
    await _end(tester, c);
  });

  testWidgets('Hướng dẫn: hộp thoại có nguồn sát thương + điều kiện nhận quà (boss tuần và ngày khác nhau)', (tester) async {
    final (c, _) = await _open(tester, _Repo());
    await tester.tap(find.byKey(const Key('wb-guide')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wb-guide-dialog')), findsOneWidget);
    expect(find.textContaining('120'), findsWidgets); // +120 mỗi quảng cáo
    expect(find.textContaining('$worldBossMinDamageToClaim'), findsWidgets);
    await _end(tester, c);
  });

  testWidgets('hạ boss: hiện thông báo; chưa ai đánh: bảng trống', (tester) async {
    final repo = _Repo()..data = _state(damage: 100000, mine: 0);
    final (c, _) = await _open(tester, repo);
    expect(find.text('Boss đã bị hạ! 🎉'), findsOneWidget);
    expect(find.byKey(const Key('wb-need')), findsOneWidget, reason: 'chưa đủ sát thương để nhận quà');
    await _end(tester, c);
  });

  testWidgets('tự động đánh: server bật TRƯỚC rồi mới trừ 💎; hiện trạng thái đang bật', (tester) async {
    final (c, repo) = await _open(tester, _Repo(), gems: 250);
    await tester.ensureVisible(find.byKey(const Key('wb-auto-buy')));
    await tester.tap(find.byKey(const Key('wb-auto-buy')));
    await tester.pumpAndSettle();
    expect(repo.log, contains('buyAuto'));
    expect(c.read(gameControllerProvider).gems, 250 - worldBossAutoGems);
    expect(find.byKey(const Key('wb-auto-on')), findsOneWidget);
    expect(find.byKey(const Key('wb-auto-buy')), findsNothing);
    await _end(tester, c);
  });

  testWidgets('tự động đánh: không đủ 💎 → không gọi server, không trừ', (tester) async {
    final (c, repo) = await _open(tester, _Repo(), gems: 10);
    await tester.ensureVisible(find.byKey(const Key('wb-auto-buy')));
    await tester.tap(find.byKey(const Key('wb-auto-buy')));
    await tester.pumpAndSettle();
    expect(repo.log, isNot(contains('buyAuto')));
    expect(c.read(gameControllerProvider).gems, 10);
    expect(find.byType(SnackBar), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('tự động đánh: đã bật từ trước (server false) → KHÔNG trừ 💎 lần nữa', (tester) async {
    final repo = _Repo()..buyFresh = false;
    final (c, _) = await _open(tester, repo, gems: 250);
    await tester.ensureVisible(find.byKey(const Key('wb-auto-buy')));
    await tester.tap(find.byKey(const Key('wb-auto-buy')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).gems, 250);
    await _end(tester, c);
  });

  testWidgets('tự động đánh: server lỗi → KHÔNG trừ 💎, báo lỗi', (tester) async {
    final repo = _Repo()..buyError = StateError('boom');
    final (c, _) = await _open(tester, repo, gems: 250);
    await tester.ensureVisible(find.byKey(const Key('wb-auto-buy')));
    await tester.tap(find.byKey(const Key('wb-auto-buy')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).gems, 250);
    expect(find.byType(SnackBar), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('xem quảng cáo xong → báo server +sát thương; đóng sớm → không gọi server', (tester) async {
    final ad = _Ad(RewardOutcome.earned);
    final (c, repo) = await _open(tester, _Repo(), ad: ad);
    await tester.tap(find.byKey(const Key('wb-ad')));
    await tester.pumpAndSettle();
    expect(ad.shown, 1);
    expect(repo.adCalls, 1);
    expect(find.byType(SnackBar), findsOneWidget);
    await _end(tester, c);

    final ad2 = _Ad(RewardOutcome.dismissed);
    final (c2, repo2) = await _open(tester, _Repo(), ad: ad2);
    await tester.tap(find.byKey(const Key('wb-ad')));
    await tester.pumpAndSettle();
    expect(ad2.shown, 1);
    expect(repo2.adCalls, 0, reason: 'không xem hết thì không có sát thương');
    await _end(tester, c2);
  });

  testWidgets('đã gỡ quảng cáo: bỏ bước xem, vẫn +sát thương', (tester) async {
    final ad = _Ad(RewardOutcome.earned);
    final (c, repo) = await _open(tester, _Repo(), ad: ad, adsRemoved: true);
    await tester.tap(find.byKey(const Key('wb-ad')));
    await tester.pumpAndSettle();
    expect(ad.shown, 0);
    expect(repo.adCalls, 1);
    await _end(tester, c);
  });

  testWidgets('hết lượt quảng cáo trong ngày: nút mờ; server báo hết → thông báo', (tester) async {
    final repo = _Repo()
      ..data = WorldBossState(
          boss: 0, hp: 100000, damage: 0, mine: 0, rank: null, players: 0, endsAtSeconds: 1000 + 86400,
          claimed: const {}, board: const [], adLeft: 0);
    final (c, _) = await _open(tester, repo, ad: _Ad(RewardOutcome.earned));
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('wb-ad'))).onPressed, isNull);
    await _end(tester, c);

    final repo2 = _Repo()..adError = StateError('ad limit');
    final (c2, _) = await _open(tester, repo2, ad: _Ad(RewardOutcome.earned));
    await tester.tap(find.byKey(const Key('wb-ad')));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    await _end(tester, c2);
  });

  WorldBossState withDaily({int dayDamage = 12000, int dayMine = 50, Set<int> dayClaimed = const {}}) => WorldBossState(
      boss: 0, hp: 100000, damage: 45000, mine: 500, rank: 2, players: 37, endsAtSeconds: 1000 + 3 * 86400,
      claimed: const {}, board: const [],
      daily: WorldBossState(
          boss: 0, hp: 20000, damage: dayDamage, mine: dayMine, rank: 1, players: 5, endsAtSeconds: 1000 + 86400,
          claimed: dayClaimed, board: const [], minDamage: worldBossDayMinDamageToClaim));

  test('boss ngày: mốc và mức tối thiểu riêng; chấm đỏ cộng cả hai', () {
    final s = withDaily();
    expect(s.daily!.phaseReached(3), isTrue);
    expect(s.daily!.phaseReached(4), isFalse);
    expect(s.daily!.canClaim(1), isTrue, reason: '50 ≥ 30');
    expect(withDaily(dayMine: 20).daily!.canClaim(1), isFalse);
    expect(s.claimableCount, 2 + 3);
    expect(WorldBossState.fromJson({'hp': 100, 'daily': {'hp': 50, 'mine': 40}}).daily!.minDamage, worldBossDayMinDamageToClaim);
  });

  testWidgets('có boss ngày: 2 tab, tab ngày hiện Frankenstein và thưởng Xu; không có → không có tab', (tester) async {
    final repo = _Repo()..data = withDaily();
    final (c, _) = await _open(tester, repo);
    expect(find.byKey(const Key('wb-tab-day')), findsOneWidget);
    expect(find.text('🧟 Quái Vật Frankenstein'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wb-tab-week')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wb-tab-week')), findsOneWidget);
    await _end(tester, c);

    final (c2, _) = await _open(tester, _Repo());
    expect(find.byKey(const Key('wb-tab-day')), findsNothing, reason: 'server cũ chưa có boss ngày');
    await _end(tester, c2);
  });

  testWidgets('nhận mốc boss ngày: server OK rồi mới cộng Xu (+💎 nếu có); lỗi thì không cộng', (tester) async {
    final repo = _Repo()
      ..data = withDaily()
      ..dayGems = 0;
    final (c, _) = await _open(tester, repo);
    final before = c.read(gameControllerProvider).money;
    await tester.scrollUntilVisible(find.byKey(const Key('wb-claim-1')), 300, scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
    await tester.ensureVisible(find.byKey(const Key('wb-claim-1')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wb-claim-1')).first);
    await tester.pumpAndSettle();
    expect(repo.log, contains('claimDay:1'));
    expect(c.read(gameControllerProvider).money, greaterThanOrEqualTo(before + raidRewardFloor));
    await _end(tester, c);

    final repo2 = _Repo()
      ..data = withDaily()
      ..claimDayError = StateError('already claimed');
    final (c2, _) = await _open(tester, repo2);
    final b2 = c2.read(gameControllerProvider).money;
    await tester.scrollUntilVisible(find.byKey(const Key('wb-claim-1')), 300, scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
    await tester.ensureVisible(find.byKey(const Key('wb-claim-1')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wb-claim-1')).first);
    await tester.pumpAndSettle();
    expect(c2.read(gameControllerProvider).money, b2);
    await _end(tester, c2);
  });

  test('chấm đỏ: số mốc nhận được, 0 khi chưa liên kết', () async {
    final repo = _Repo();
    final linked = ProviderContainer(overrides: [
      cloudSaveControllerProvider.overrideWith(_Linked.new),
      worldBossRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(linked.dispose);
    expect(await linked.read(worldBossAlertProvider.future), 2);
    final unlinked = ProviderContainer(overrides: [
      cloudSaveControllerProvider.overrideWith(_Unlinked.new),
      worldBossRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(unlinked.dispose);
    expect(await unlinked.read(worldBossAlertProvider.future), 0);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
    testWidgets('không tràn ở 320px, chữ 1.5×, số cực lớn ($lang)', (tester) async {
      final repo = _Repo()
        ..data = WorldBossState(
            boss: 6, hp: 1 << 50, damage: 1 << 49, mine: 123456789012, rank: 12345, players: 987654,
            endsAtSeconds: 1000 + 6 * 86400, claimed: {1},
            board: [for (var i = 0; i < 20; i++) WorldBossRow('Người chơi tên rất dài số $i', 99999999999 - i)],
            daily: WorldBossState(
                boss: 0, hp: 1 << 40, damage: 1 << 39, mine: 98765432109, rank: 99999, players: 123456,
                endsAtSeconds: 1000 + 86400, claimed: {2}, minDamage: worldBossDayMinDamageToClaim,
                board: [for (var i = 0; i < 20; i++) WorldBossRow('Tên rất dài của người chơi số $i', 88888888888 - i)]));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 1000 * 1000),
        worldBossRepositoryProvider.overrideWithValue(repo),
        cloudSaveControllerProvider.overrideWith(_Linked.new),
      ]);
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WorldBossPage(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wb-name')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: lang);
      expect(find.textContaining(RegExp(r'\{[a-z]+\}')), findsNothing, reason: lang);
      await _end(tester, c);
    });
  }
}
