// Nhắc tên (@tag) trong chat Hội: khớp tên dài nhất, ranh giới từ, không dính email, gợi ý khi gõ, chèn tên.
import 'package:boba_empire/guild/mentions.dart';
import 'package:flutter_test/flutter_test.dart';

const _names = ['Bob', 'Bob Lee', 'An', 'Anh', '🐶áu áu#2', 'HOANG.'];

String _hit(String body) => [for (final m in findMentions(body, _names)) m.nickname].join('|');

void main() {
  group('findMentions', () {
    test('khớp tên đơn, không phân biệt hoa thường, trả đúng chữ hoa thường của thành viên', () {
      expect(_hit('hi @bob!'), 'Bob');
      expect(_hit('@BOB ơi'), 'Bob');
      final m = findMentions('xin chào @bob', _names).single;
      expect((m.start, m.end), (9, 13));
    });

    test('tên dài nhất thắng: "@Bob Lee" không bị cắt thành "@Bob"', () {
      expect(_hit('@Bob Lee đâu rồi'), 'Bob Lee');
      expect(_hit('@Bob kìa'), 'Bob');
    });

    test('ranh giới: "@An" không khớp trong "@Anh"; "@Anh" khớp Anh', () {
      expect(_hit('@Anh ơi'), 'Anh');
      expect(_hit('@An ơi'), 'An');
      expect(_hit('@Ancd'), '');
    });

    test('dấu câu sau tên vẫn khớp; hết chuỗi vẫn khớp', () {
      expect(_hit('@Bob, @An. @Anh?'), 'Bob|An|Anh');
      expect(_hit('gọi @An'), 'An');
    });

    test('emoji, khoảng trắng và ký tự đặc biệt trong tên', () {
      expect(_hit('@🐶áu áu#2 ơi'), '🐶áu áu#2');
      expect(_hit('ê @hoang. à'), 'HOANG.');
    });

    test('không dính email / chữ liền trước @', () {
      expect(_hit('mail a@Bob.com'), '');
      expect(_hit('x@Bob'), '');
    });

    test('nhiều lần nhắc trong một tin; không có @ thì rỗng', () {
      expect(_hit('@Bob @An @Bob'), 'Bob|An|Bob');
      expect(_hit('không nhắc ai'), '');
      expect(_hit(''), '');
      expect(_hit('@'), '');
    });

    test('tên rỗng bị bỏ qua, không lặp vô hạn', () {
      expect(findMentions('@ x', ['', 'x']), isEmpty);
    });
  });

  group('mentionsNickname', () {
    test('có/không nhắc đúng người', () {
      expect(mentionsNickname('ê @Bob nhé', 'bob', _names), isTrue);
      expect(mentionsNickname('ê @Bob Lee nhé', 'Bob', _names), isFalse, reason: 'đó là nhắc Bob Lee');
      expect(mentionsNickname('ê @Bob Lee nhé', 'Bob Lee', _names), isTrue);
      expect(mentionsNickname('không có', 'An', _names), isFalse);
    });
  });

  group('gõ dở lần nhắc', () {
    test('activeMentionQuery: sau @ ở đầu hoặc sau khoảng trắng', () {
      expect(activeMentionQuery('@', 1), '');
      expect(activeMentionQuery('hi @bo', 6), 'bo');
      expect(activeMentionQuery('hi @bo xin', 6), 'bo', reason: 'chỉ xét tới con trỏ');
      expect(activeMentionQuery('hi@bo', 5), isNull, reason: '@ dính chữ trước');
      expect(activeMentionQuery('không có', 3), isNull);
    });

    test('cho phép khoảng trắng trong tên (tới 20 ký tự); quá dài hoặc xuống dòng thì thôi', () {
      expect(activeMentionQuery('@áu á', 5), 'áu á');
      expect(activeMentionQuery('@${'x' * 21}', 22), isNull);
      expect(activeMentionQuery('@a\nb', 4), isNull);
      expect(activeMentionQuery('@a @b', 5), 'b', reason: '@ thứ hai (sau khoảng trắng) mở lần nhắc mới');
      expect(activeMentionQuery('@a@b', 4), isNull, reason: '@ dính chữ trước');
    });

    test('activeMentionQuery với cursor ngoài biên → null', () {
      expect(activeMentionQuery('abc', 99), isNull);
      expect(activeMentionQuery('abc', -1), isNull);
    });

    test('mentionSuggestions: tiền tố, bỏ chính mình, giới hạn, rỗng thì lấy theo thứ tự', () {
      expect(mentionSuggestions('b', _names), ['Bob', 'Bob Lee']);
      expect(mentionSuggestions('B', _names, exclude: 'bob'), ['Bob Lee']);
      expect(mentionSuggestions('', _names, limit: 2), ['Bob', 'Bob Lee']);
      expect(mentionSuggestions('zzz', _names), isEmpty);
    });

    test('insertMention thay phần đang gõ và đặt con trỏ sau dấu cách', () {
      final (t, c) = insertMention('hi @bo', 6, 'Bob');
      expect(t, 'hi @Bob ');
      expect(c, t.length);
      final (t2, c2) = insertMention('@b xin chào', 2, 'Bob Lee');
      expect(t2, '@Bob Lee xin chào', reason: 'không để hai dấu cách');
      expect(c2, '@Bob Lee '.length);
    });
  });
}
