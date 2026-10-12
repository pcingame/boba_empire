import 'package:boba_empire/guild/guild_alert.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:flutter_test/flutter_test.dart';

GuildMine _view({
  int total = 0,
  int myPoints = 0,
  List<int> claimed = const [],
  List<int> questsClaimed = const [],
  int bossHp = 0,
  bool bossClaimed = false,
  GuildFund fund = const GuildFund(),
  bool teamAvailable = false,
  bool teamClaimed = false,
  List<GuildMemberInfo> others = const [],
}) =>
    GuildMine(
      myUserId: 'me',
      guild: MyGuild(
        id: 'g',
        name: 'G',
        tag: 'G',
        emoji: '🧋',
        ownerId: 'me',
        total: total,
        claimed: claimed,
        questsClaimed: questsClaimed,
        bossHp: bossHp,
        bossClaimed: bossClaimed,
        fund: fund,
        teamAvailable: teamAvailable,
        teamClaimed: teamClaimed,
        members: [GuildMemberInfo(userId: 'me', nickname: 'me', points: myPoints), ...others],
      ),
    );

void main() {
  test('không có gì để nhận thì không chấm đỏ', () {
    expect(guildHasClaimable(_view()), isFalse);
    expect(guildHasClaimable(_view(total: 50000, myPoints: 100)), isFalse,
        reason: 'mốc đạt nhưng cá nhân <300 điểm thì chưa nhận được');
  });

  test('mốc tuần đạt + đủ điểm cá nhân = có thưởng; đã nhận thì hết', () {
    expect(guildHasClaimable(_view(total: 10000, myPoints: 300)), isTrue);
    expect(guildHasClaimable(_view(total: 10000, myPoints: 300, claimed: [1])), isFalse);
  });

  test('Boss hạ gục chưa nhận, nhiệm vụ cá nhân xong chưa nhận, quỹ đạt chưa nhận', () {
    expect(guildHasClaimable(_view(total: 20000, myPoints: 300, bossHp: 20000, claimed: [1])), isTrue);
    expect(
        guildHasClaimable(_view(total: 20000, myPoints: 300, bossHp: 20000, claimed: [1], bossClaimed: true)),
        isFalse);
    expect(guildHasClaimable(_view(myPoints: 1000)), isTrue);
    expect(guildHasClaimable(_view(myPoints: 1000, questsClaimed: [1])), isFalse);
    expect(
        guildHasClaimable(_view(fund: const GuildFund(progress: 500, target: 500, mine: 10))), isTrue);
    expect(
        guildHasClaimable(
            _view(fund: const GuildFund(progress: 500, target: 500, mine: 10, claimed: true))),
        isFalse);
    expect(guildHasClaimable(_view(fund: const GuildFund(progress: 500, target: 500, mine: 5))), isFalse);
  });

  test('nhiệm vụ chung: đủ người + mình đạt + chưa nhận = có thưởng', () {
    const other = [GuildMemberInfo(userId: 'u', nickname: 'u', points: 1000)];
    expect(guildHasClaimable(_view(myPoints: 1000, teamAvailable: true, others: other)), isTrue);
    expect(
        guildHasClaimable(_view(
            myPoints: 1000,
            teamAvailable: true,
            teamClaimed: true,
            questsClaimed: [1],
            others: other)),
        isFalse);
    expect(guildHasClaimable(_view(myPoints: 1000, others: other)), isTrue,
        reason: 'server cũ không có nhiệm vụ chung → chỉ còn nhiệm vụ cá nhân 1000 điểm');
  });
}
