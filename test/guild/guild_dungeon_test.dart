// Phó bản Hội: hằng số khớp SQL, công thức ngưỡng, bộ đếm theo tuần, lưu/đọc, các điểm nối trong controller.
import 'dart:convert';
import 'dart:io';

import 'package:boba_empire/core/guild.dart' show guildWeekIndex;
import 'package:boba_empire/core/guild_dungeon.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sql = File('supabase/guild_dungeon_schema.sql').readAsStringSync();

  /// Giá trị `when <kind> then N` trong thân hàm SQL [fn].
  Map<String, int> cases(String fn) {
    final body = sql.substring(sql.indexOf('function $fn')).split(r'$$;').first;
    return {
      for (final m in RegExp(r"when '?(\w+)'? then (\d+)").allMatches(body)) m.group(1)!: int.parse(m.group(2)!),
    };
  }

  int constant(String fn) =>
      int.parse(RegExp('function $fn\\(\\) returns integer\\s*language sql immutable as \\\$\\\$ select (\\d+) \\\$\\\$')
          .firstMatch(sql)!
          .group(1)!);

  test('hằng số khớp SQL: đơn vị, hệ số ải, tối thiểu, thưởng', () {
    final unit = cases('guild_dungeon_unit');
    for (final b in DungeonBar.values) {
      expect(unit[b.wire], dungeonUnit[b], reason: b.name);
    }
    final mult = cases('guild_dungeon_stage_mult');
    expect([mult['1'], mult['2'], mult['3']], dungeonStageMult);
    expect(constant('guild_dungeon_min_members'), dungeonMinMembers);
    expect(constant('guild_dungeon_min_tap'), dungeonMinToClaim[DungeonBar.tap]);
    expect(constant('guild_dungeon_min_off'), dungeonMinToClaim[DungeonBar.off]);
    expect(constant('guild_dungeon_min_rec'), dungeonMinToClaim[DungeonBar.rec]);
    final coins = cases('guild_dungeon_reward_coins');
    expect([coins['1'], coins['2'], coins['3']], dungeonRewardCoins);
    expect(cases('guild_dungeon_reward_gems')['3'], dungeonRewardGems[2]);
    expect(dungeonRewardGems.sublist(0, 2), [0, 0]);
    expect(dungeonChestStage, 3);
    // Hệ số vai ×1.5 = 3/2 (v * 3 / 2 trong SQL).
    expect(sql, contains('* 3 / 2'));
    expect((dungeonRoleBonusNum, dungeonRoleBonusDen), (3, 2));
  });

  test('ngưỡng: khớp số trong kịch bản SQL (4 người) và làm tròn lên', () {
    expect([for (final b in DungeonBar.values) dungeonTarget(b, 1, 4, 0)], [6000, 86400, 100]);
    expect(dungeonTarget(DungeonBar.tap, 3, 4, 0), 24000);
    expect(dungeonTarget(DungeonBar.tap, 1, 4, 2), 9000); // bậc 2 → ×1.5
    expect(dungeonTarget(DungeonBar.tap, 1, 1, 0), 4500, reason: 'hội 1 người tính như 3');
    // 25 × 3 × 1 × 125 / 100 = 93.75 → làm tròn LÊN 94 như ceil() của SQL.
    expect(dungeonTarget(DungeonBar.rec, 1, 3, 1), 94);
  });

  test('bộ đếm: cộng dồn trong tuần, sang tuần mới thì về 0, số xấu bị bỏ', () {
    final s = GameState.newGame(nowMillis: 0);
    final mon = 11 * _day + 1000; // thứ Hai thứ hai sau epoch (tuần 1)
    addDungeon(s, DungeonBar.tap, 5, mon);
    addDungeon(s, DungeonBar.off, 90.7, mon);
    addDungeon(s, DungeonBar.rec, 2, mon);
    for (final bad in [0, -3, double.nan, double.infinity]) {
      addDungeon(s, DungeonBar.tap, bad, mon);
    }
    expect(dungeonTotals(s, mon), (tap: 5, off: 90, rec: 2));
    expect(dungeonTotals(s, mon + 6 * _day), (tap: 5, off: 90, rec: 2), reason: 'vẫn cùng tuần');
    expect(dungeonTotals(s, mon + 7 * _day), (tap: 0, off: 0, rec: 0));
    expect(s.dungeonWeek, 2);
    expect(guildWeekIndex(mon), 1);
  });

  test('lưu/đọc, save cũ = 0, dữ liệu hỏng bị kẹp', () {
    final s = GameState.newGame(nowMillis: 0)
      ..dungeonWeek = 9
      ..dungeonTap = 123
      ..dungeonOffline = 45.5
      ..dungeonRecipe = 6;
    final back = GameState.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect((back.dungeonWeek, back.dungeonTap, back.dungeonOffline, back.dungeonRecipe), (9, 123, 45.5, 6));
    final old = s.toJson()
      ..remove('dungeonWeek')
      ..remove('dungeonTap')
      ..remove('dungeonOffline')
      ..remove('dungeonRecipe');
    final o = GameState.fromJson(jsonDecode(jsonEncode(old)) as Map<String, dynamic>);
    expect((o.dungeonTap, o.dungeonOffline, o.dungeonRecipe), (0, 0, 0));
    final bad = s.toJson()
      ..['dungeonTap'] = -9
      ..['dungeonOffline'] = -1
      ..['dungeonRecipe'] = -2;
    final b = GameState.fromJson(jsonDecode(jsonEncode(bad)) as Map<String, dynamic>);
    expect((b.dungeonTap, b.dungeonOffline, b.dungeonRecipe), (0, 0, 0));
  });

  group('điểm nối trong controller', () {
    Future<(ProviderContainer, void Function(int))> harness({int lastSeen = 0}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: lastSeen);
      var now = 100 * _day;
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(c.dispose);
      return (c, (int ms) => now = ms);
    }

    test('chạm + Công thức đúng + đơn 3★ + thắng Ghép 3 cộng đúng thanh', () async {
      final (c, _) = await harness(lastSeen: 100 * _day);
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.tapCup();
      ctrl.tapCup();
      expect(ctrl.dungeonProgress(), (tap: 2, off: 0, rec: 0));
      ctrl.answerRecipe(1, true);
      expect(ctrl.dungeonProgress().rec, 1);
      ctrl.answerRecipe(1, true); // chưa đến hạn: không tính bậc → không tính điểm
      expect(ctrl.dungeonProgress().rec, 1);
      ctrl.answerRecipe(2, false);
      expect(ctrl.dungeonProgress().rec, 1, reason: 'trả lời sai không tính');
      ctrl.grantOrderEssence();
      expect(ctrl.dungeonProgress().rec, 2);
      ctrl.grantMatch3Result(1, 2);
      expect(ctrl.dungeonProgress().rec, 3);
      ctrl.grantMatch3Result(2, 0);
      expect(ctrl.dungeonProgress().rec, 3, reason: 'thua không tính');
    });

    test('offline: vắng 2 giờ → ~7200 giây vào thanh 🌙', () async {
      final (c, _) = await harness(lastSeen: 100 * _day - 2 * 3600 * 1000);
      final off = c.read(gameControllerProvider.notifier).dungeonProgress().off;
      expect(off, closeTo(7200, 5));
    });
  });
}
