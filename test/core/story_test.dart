import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/story.dart';
import 'package:boba_empire/core/story_content.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _fresh() => GameState.newGame(nowMillis: 0);

void main() {
  group('pendingChapterId', () {
    test('ván mới → Chương 1', () {
      expect(pendingChapterId(_fresh()), 1);
    });

    test('null khi chưa tới mốc kế', () {
      final s = _fresh()..storyChapter = 1; // đã xem Ch.1, chưa tới stage 2
      expect(pendingChapterId(s), isNull);
    });

    test('mở tuần tự theo giai đoạn', () {
      final s = _fresh()..storyChapter = 1;
      s.stage = 2;
      expect(pendingChapterId(s), 2);
      s.storyChapter = 2;
      s.stage = 3;
      expect(pendingChapterId(s), 3);
    });

    test('không nhảy cóc: kẹt ở Chương 4 (prestige) dù đã tới stage 4', () {
      final s = _fresh()
        ..storyChapter = 3
        ..stage = 4; // Ch.4 cần prestige, Ch.5 cần stage 4
      expect(pendingChapterId(s), isNull); // dừng ở Ch.4 chưa thoả
      s.prestigeStars = 1;
      expect(pendingChapterId(s), 4);
    });

    test('Chương 4 có cửa thoát: tới giai đoạn cuối dù chưa prestige', () {
      final s = _fresh()
        ..storyChapter = 3
        ..stage = 6; // whale mở giai đoạn bằng 💎, chưa prestige
      expect(pendingChapterId(s), 4);
    });

    test('chương lựa chọn re-show tới khi chọn', () {
      final s = _fresh()
        ..storyChapter = 6 // đã "xem" Ch.6 nhưng chưa chọn
        ..stage = 5;
      expect(pendingChapterId(s), 6);
      s.storyChoiceA = 'craft';
      expect(pendingChapterId(s), isNull); // Ch.7 cần stage 6
    });

    test('Chương 8 chờ hạ đối thủ', () {
      final s = _fresh()
        ..storyChapter = 7
        ..stage = 6;
      expect(pendingChapterId(s), isNull);
      s.rivalDefeated = true;
      expect(pendingChapterId(s), 8);
    });

    test(
        'Chương 9-18 (mở rộng thế giới) mở tuần tự theo giai đoạn 7..12 — '
        'chọn xong cả 2 trục C/D thì hết truyện', () {
      final s = _fresh()
        ..storyChapter = 8
        ..storyChoiceB = 'acquire' // Ch.8 đã chọn xong từ trước
        ..stage = 12; // mở hết mọi mốc stage luôn, chỉ còn phải lần lượt xem
      for (final id in [9, 10, 11, 12]) {
        expect(pendingChapterId(s), id);
        markChapterSeen(s, id);
      }
      expect(pendingChapterId(s), 13); // chương lựa chọn — kẹt tới khi chọn
      s.storyChoiceC = 'independent';
      markChapterSeen(s, 13);
      for (final id in [14, 15, 16, 17]) {
        expect(pendingChapterId(s), id);
        markChapterSeen(s, id);
      }
      expect(pendingChapterId(s), 18); // chương lựa chọn cuối
      s.storyChoiceD = 'global';
      markChapterSeen(s, 18);
      expect(pendingChapterId(s), isNull); // hết truyện
    });

    test('chương lựa chọn 13/18 re-show tới khi chọn', () {
      final s = _fresh()
        ..storyChapter = 13 // đã "xem" Ch.13 nhưng chưa chọn
        ..stage = 12;
      expect(pendingChapterId(s), 13);
      s.storyChoiceC = 'merger';
      expect(pendingChapterId(s), 14); // Ch.14 cần stage 10, đã thoả

      s.storyChapter = 18;
      expect(pendingChapterId(s), 18);
      s.storyChoiceD = 'soul';
      expect(pendingChapterId(s), isNull); // Ch.18 là chương cuối
    });
  });

  group('applyStoryChoice', () {
    test('ghi đúng trục A và khoá không cho chọn lại', () {
      final s = _fresh()..storyChapter = 6;
      expect(applyStoryChoice(s, 6, 'scale'), isTrue);
      expect(s.storyChoiceA, 'scale');
      expect(applyStoryChoice(s, 6, 'craft'), isFalse); // đã chọn
      expect(s.storyChoiceA, 'scale');
    });

    test('key sai → false', () {
      final s = _fresh();
      expect(applyStoryChoice(s, 6, 'bogus'), isFalse);
      expect(s.storyChoiceA, isNull);
    });

    test('chương không có lựa chọn → false', () {
      expect(applyStoryChoice(_fresh(), 2, 'craft'), isFalse);
    });

    test('trục B độc lập với trục A', () {
      final s = _fresh()
        ..storyChapter = 8
        ..storyChoiceA = 'craft';
      expect(applyStoryChoice(s, 8, 'acquire'), isTrue);
      expect(s.storyChoiceB, 'acquire');
      expect(s.storyChoiceA, 'craft');
    });

    test('trục C (Chương 13) và D (Chương 18) ghi đúng, độc lập A/B', () {
      final s = _fresh()
        ..storyChapter = 18
        ..storyChoiceA = 'craft'
        ..storyChoiceB = 'acquire';
      expect(applyStoryChoice(s, 13, 'merger'), isTrue);
      expect(s.storyChoiceC, 'merger');
      expect(applyStoryChoice(s, 13, 'independent'), isFalse); // đã chọn
      expect(s.storyChoiceC, 'merger');

      expect(applyStoryChoice(s, 18, 'soul'), isTrue);
      expect(s.storyChoiceD, 'soul');
      expect(s.storyChoiceA, 'craft'); // không đụng các trục khác
      expect(s.storyChoiceB, 'acquire');
    });
  });

  test('rivalActive: Chương 3+ và chưa bị hạ', () {
    final s = _fresh();
    expect(rivalActive(s), isFalse);
    s.storyChapter = 3;
    expect(rivalActive(s), isTrue);
    s.rivalDefeated = true;
    expect(rivalActive(s), isFalse);
  });

  test('markChapterSeen chỉ tăng, không lùi', () {
    final s = _fresh()..storyChapter = 5;
    markChapterSeen(s, 3);
    expect(s.storyChapter, 5);
    markChapterSeen(s, 6);
    expect(s.storyChapter, 6);
  });

  test('mọi chương (1..18) có prose vi + en, không thiếu/lệch id', () {
    expect(storyChapters.map((c) => c.id).toList(),
        List.generate(18, (i) => i + 1));
    for (final c in storyChapters) {
      for (final locale in ['vi', 'en']) {
        final text = storyText(c.id, locale);
        expect(text.title, isNotEmpty, reason: 'Chương ${c.id} [$locale]');
        expect(text.body, isNotEmpty, reason: 'Chương ${c.id} [$locale]');
        expect(text.speaker, isNotEmpty, reason: 'Chương ${c.id} [$locale]');
        if (c.choice != null) {
          expect(text.optionA, isNotEmpty, reason: 'Chương ${c.id} [$locale]');
          expect(text.optionADesc, isNotEmpty,
              reason: 'Chương ${c.id} [$locale]');
          expect(text.optionB, isNotEmpty, reason: 'Chương ${c.id} [$locale]');
          expect(text.optionBDesc, isNotEmpty,
              reason: 'Chương ${c.id} [$locale]');
        }
      }
    }
  });
}
