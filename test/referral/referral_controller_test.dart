import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/referral/referral_controller.dart';
import 'package:boba_empire/referral/referral_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_referral_repository.dart';

Future<ProviderContainer> _open(FakeReferralRepo repo,
    {int stage = 1, bool redeemed = false, bool sent = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..stage = stage
        ..referralRedeemed = redeemed
        ..referralStageSent = sent,
      nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
    referralRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(c.dispose);
  return c;
}

ReferralController _ctrl(ProviderContainer c) =>
    c.read(referralControllerProvider.notifier);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tải trạng thái → Loaded; lỗi → Error đúng loại', () async {
    final repo = FakeReferralRepo();
    final c = await _open(repo);
    await _ctrl(c).load();
    expect((c.read(referralControllerProvider) as ReferralLoaded).status.code, 'ABC234');

    repo.failures['status'] = ReferralFailure.emailRequired;
    await _ctrl(c).load();
    expect((c.read(referralControllerProvider) as ReferralError).failure,
        ReferralFailure.emailRequired);
  });

  test('nhập mã: server OK rồi mới cộng 💎 và đánh dấu đã nhập', () async {
    final repo = FakeReferralRepo();
    final c = await _open(repo);
    final out = await _ctrl(c).redeem('ABC234');
    expect(out.ok, isTrue);
    expect(out.gems, referralInviteeReward);
    final s = c.read(gameControllerProvider);
    expect(s.gems, referralInviteeReward);
    expect(s.referralRedeemed, isTrue);
  });

  test('nhập mã lỗi → không cộng 💎, không đánh dấu', () async {
    for (final f in [
      ReferralFailure.notFound,
      ReferralFailure.invalidCode,
      ReferralFailure.alreadyRedeemed,
      ReferralFailure.inviterFull,
      ReferralFailure.emailRequired,
      ReferralFailure.network,
    ]) {
      final repo = FakeReferralRepo()..failures['redeem'] = f;
      final c = await _open(repo);
      final out = await _ctrl(c).redeem('ZZZZZZ');
      expect(out.failure, f);
      final s = c.read(gameControllerProvider);
      expect(s.gems, 0, reason: '$f');
      expect(s.referralRedeemed, isFalse, reason: '$f');
    }
  });

  test('nhập mã khi đã ở giai đoạn ≥ 3: báo giai đoạn ngay để người mời được thưởng',
      () async {
    final repo = FakeReferralRepo();
    final c = await _open(repo, stage: 5);
    await _ctrl(c).redeem('ABC234');
    expect(repo.lastStage, 5);
    expect(c.read(gameControllerProvider).referralStageSent, isTrue);
  });

  test('báo giai đoạn: chỉ khi đã nhập mã, đủ giai đoạn, chưa báo; báo xong đặt cờ', () async {
    var repo = FakeReferralRepo();
    var c = await _open(repo, stage: 4, redeemed: false);
    await _ctrl(c).reportStageIfNeeded();
    expect(repo.calls, isEmpty, reason: 'chưa nhập mã → không báo');

    repo = FakeReferralRepo();
    c = await _open(repo, stage: 2, redeemed: true);
    await _ctrl(c).reportStageIfNeeded();
    expect(repo.calls, isEmpty, reason: 'chưa đủ giai đoạn');

    repo = FakeReferralRepo();
    c = await _open(repo, stage: 4, redeemed: true, sent: true);
    await _ctrl(c).reportStageIfNeeded();
    expect(repo.calls, isEmpty, reason: 'đã báo rồi');

    repo = FakeReferralRepo();
    c = await _open(repo, stage: 4, redeemed: true);
    await _ctrl(c).reportStageIfNeeded();
    expect(repo.lastStage, 4);
    expect(c.read(gameControllerProvider).referralStageSent, isTrue);
  });

  test('báo giai đoạn lỗi: nuốt lỗi, KHÔNG đặt cờ (thử lại lần sau)', () async {
    final repo = FakeReferralRepo()..failures['reportStage'] = ReferralFailure.network;
    final c = await _open(repo, stage: 4, redeemed: true);
    await _ctrl(c).reportStageIfNeeded();
    expect(c.read(gameControllerProvider).referralStageSent, isFalse);
  });

  test('nhận thưởng người mời: cộng đúng 💎 theo số bạn; lỗi thì không cộng', () async {
    final repo = FakeReferralRepo()
      ..current = const ReferralStatus(code: 'ABC234', invited: 3, reached: 3, claimable: 3);
    final c = await _open(repo);
    final out = await _ctrl(c).claim();
    expect(out.gems, 3 * referralInviterReward);
    expect(c.read(gameControllerProvider).gems, 3 * referralInviterReward);
    expect((c.read(referralControllerProvider) as ReferralLoaded).status.claimable, 0);

    repo.failures['claim'] = ReferralFailure.nothingToClaim;
    final fail = await _ctrl(c).claim();
    expect(fail.failure, ReferralFailure.nothingToClaim);
    expect(c.read(gameControllerProvider).gems, 3 * referralInviterReward);
  });

  test('cờ mời bạn được lưu qua save/load; save cũ không có khoá → false', () {
    final g = GameState.newGame(nowMillis: 0)
      ..referralRedeemed = true
      ..referralStageSent = true;
    final back = GameState.fromJson(g.toJson());
    expect(back.referralRedeemed, isTrue);
    expect(back.referralStageSent, isTrue);
    final old = GameState.fromJson(GameState.newGame(nowMillis: 0).toJson()
      ..remove('referralRedeemed')
      ..remove('referralStageSent'));
    expect(old.referralRedeemed, isFalse);
    expect(old.referralStageSent, isFalse);
  });
}
