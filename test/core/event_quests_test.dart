import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/event_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t = DateTime.utc(2026, 10, 25); // Halloween

  test('event quests: progress mirror, claim once, redeem, reset after event', () {
    final s = GameState.newGame(nowMillis: 0);
    addDailyProgress(s, DailyQuestKind.tap, 5); // chưa roll → không ghi
    expect(s.eventProgress, isEmpty);

    rollEvent(s, t);
    expect(s.eventId, 'halloween');
    addDailyProgress(s, DailyQuestKind.tap, 1500);
    expect(claimEventQuest(s, 0, t), Balance.eventQuestGems);
    expect(claimEventQuest(s, 0, t), 0); // chỉ nhận 1 lần
    expect(s.eventPoints, Balance.eventQuestPoints);

    expect(redeemEventItem(s, 'witch', t), isFalse); // 25 < 50
    expect(redeemEventItem(s, 'bat', t), isTrue);
    expect(s.ownedLimited, contains('bat'));
    expect(redeemEventItem(s, 'bat', t), isFalse); // đã có

    rollEvent(s, DateTime.utc(2026, 11, 20)); // hết dịp
    expect(s.eventId, isEmpty);
    expect(s.eventPoints, 0);
  });

  test('event state survives JSON round-trip', () {
    final s = GameState.newGame(nowMillis: 0)
      ..eventId = 'tet'
      ..eventPoints = 40;
    s.eventProgress['buy'] = 7;
    s.eventClaimed.add('tap');
    final r = GameState.fromJson(s.toJson());
    expect(r.eventId, 'tet');
    expect(r.eventPoints, 40);
    expect(r.eventProgress['buy'], 7);
    expect(r.eventClaimed, ['tap']);
  });
}
