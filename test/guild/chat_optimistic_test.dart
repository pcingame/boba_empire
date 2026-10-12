// Cập nhật lạc quan cho chat Hội: bật/tắt reaction đúng quy tắc server; áp nhiều lần bật/tắt đang chờ.
import 'package:boba_empire/guild/chat_optimistic.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:flutter_test/flutter_test.dart';

GuildMessage _m(int id, [List<GuildReaction> rs = const []]) =>
    GuildMessage(id: id, userId: 'u', nickname: 'n', body: 'b', reactions: rs);

String _fmt(GuildMessage m) => m.reactions.map((r) => '${r.emoji}${r.count}${r.mine ? '*' : ''}').join(',');

void main() {
  group('toggleReaction', () {
    test('chưa có chip → tạo chip của mình (1)', () {
      expect(_fmt(toggleReaction(_m(1), '👍')), '👍1*');
    });
    test('chip của người khác → cộng thêm của mình', () {
      final m = _m(1, const [GuildReaction(emoji: '👍', count: 2, mine: false)]);
      expect(_fmt(toggleReaction(m, '👍')), '👍3*');
    });
    test('chip mình đã bấm → bỏ (giảm 1); còn 1 mình thì xoá chip', () {
      final two = _m(1, const [GuildReaction(emoji: '❤️', count: 2, mine: true)]);
      expect(_fmt(toggleReaction(two, '❤️')), '❤️1');
      final one = _m(1, const [GuildReaction(emoji: '❤️', count: 1, mine: true)]);
      expect(toggleReaction(one, '❤️').reactions, isEmpty);
    });
    test('bật hai lần = về như cũ; không đổi bản gốc', () {
      final base = _m(1, const [GuildReaction(emoji: '😂', count: 3, mine: false)]);
      expect(_fmt(toggleReaction(toggleReaction(base, '😂'), '😂')), '😂3');
      expect(_fmt(base), '😂3', reason: 'bản gốc bất biến');
    });
    test('giữ nguyên các trường khác của tin và các chip khác', () {
      final base = _m(7, const [GuildReaction(emoji: '🎉', count: 1, mine: false)]);
      final out = toggleReaction(base, '👍');
      expect((out.id, out.userId, out.nickname, out.body), (7, 'u', 'n', 'b'));
      expect(_fmt(out), '🎉1,👍1*');
    });
  });

  group('applyPendingToggles', () {
    test('rỗng → trả nguyên danh sách', () {
      final list = [_m(1)];
      expect(identical(applyPendingToggles(list, {}), list), isTrue);
    });
    test('chỉ áp lên đúng tin có id khớp, đúng emoji', () {
      final out = applyPendingToggles([_m(1), _m(2)], {'2|👍'});
      expect(_fmt(out[0]), '');
      expect(_fmt(out[1]), '👍1*');
    });
    test('nhiều emoji chờ trên cùng một tin; id 1 không nhầm với 12', () {
      final out = applyPendingToggles([_m(1), _m(12)], {'1|👍', '1|❤️', '12|😂'});
      expect(_fmt(out[0]), '👍1*,❤️1*');
      expect(_fmt(out[1]), '😂1*');
    });
  });
}
