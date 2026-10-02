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

  test('mọi chương (1..36) có prose vi + en, không thiếu/lệch id', () {
    expect(storyChapters.map((c) => c.id).toList(),
        List.generate(36, (i) => i + 1));
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

  group('Chương 19-28 (mở rộng thế giới đợt 2, giai đoạn 13-18)', () {
    test('chương kết của tuyến gốc vẫn là 18, không trượt theo chương mới', () {
      // Bảng xếp hạng tốc độ cốt truyện dựa vào mốc này (storyCompleteSeconds).
      expect(storyFinaleChapterId, 18);
      expect(storyExtendedFinaleChapterId, 28);
    });

    test('mở tuần tự theo giai đoạn 13..18, kẹt ở 23 và 28 tới khi chọn', () {
      final s = _fresh()
        ..storyChapter = 18
        ..storyChoiceD = 'soul'
        ..stage = 12;
      expect(pendingChapterId(s), isNull); // chưa tới GĐ13 → chưa có chương mới
      s.stage = 18; // mở hết mốc stage, chỉ còn phải lần lượt xem
      for (final id in [19, 20, 21, 22]) {
        expect(pendingChapterId(s), id);
        markChapterSeen(s, id);
      }
      expect(pendingChapterId(s), 23);
      markChapterSeen(s, 23);
      expect(pendingChapterId(s), 23); // đã xem nhưng chưa chọn → re-show
      s.storyChoiceE = 'export';
      for (final id in [24, 25, 26, 27]) {
        expect(pendingChapterId(s), id);
        markChapterSeen(s, id);
      }
      expect(pendingChapterId(s), 28);
      markChapterSeen(s, 28);
      expect(pendingChapterId(s), 28);
      s.storyChoiceF = 'people';
      expect(pendingChapterId(s), isNull); // hết truyện
    });

    test('chương theo đúng ngưỡng giai đoạn', () {
      final s = _fresh()
        ..storyChapter = 20
        ..stage = 13;
      expect(pendingChapterId(s), isNull); // Ch.21 cần GĐ14
      s.stage = 14;
      expect(pendingChapterId(s), 21);
    });

    test('trục E (Chương 23) và F (Chương 28) ghi đúng, độc lập A-D', () {
      final s = _fresh()
        ..storyChapter = 28
        ..storyChoiceA = 'craft'
        ..storyChoiceD = 'soul';
      expect(applyStoryChoice(s, 23, 'export'), isTrue);
      expect(s.storyChoiceE, 'export');
      expect(applyStoryChoice(s, 23, 'heritage'), isFalse); // đã chọn
      expect(s.storyChoiceE, 'export');
      expect(applyStoryChoice(s, 28, 'recipe'), isTrue);
      expect(s.storyChoiceF, 'recipe');
      expect(s.storyChoiceA, 'craft');
      expect(s.storyChoiceD, 'soul');
      expect(applyStoryChoice(s, 28, 'bogus'), isFalse);
    });
  });

  group('Chương 29-36 (Hồi 3, Kỷ Nguyên + Trân Châu Rơi)', () {
    test('chương kết Hồi 3 là 36', () {
      expect(storyThirdActFinaleChapterId, 36);
      expect(storyChapters.last.id, 36);
    });

    test('mở tuần tự theo Kỷ Nguyên/màn Trân Châu Rơi, kẹt tới khi thoả', () {
      final s = _fresh()
        ..storyChapter = 28
        ..storyChoiceF = 'recipe';
      expect(pendingChapterId(s), isNull); // chưa Kỷ Nguyên lần nào
      s.ascensionCount = 1;
      expect(pendingChapterId(s), 29);
      markChapterSeen(s, 29);
      expect(pendingChapterId(s), isNull); // Ch.30 cần qua màn 10
      s.m3Stars.addAll(List.filled(12, 1)); // đã qua tới màn 12
      expect(pendingChapterId(s), 30);
      markChapterSeen(s, 30);
      expect(pendingChapterId(s), isNull); // Ch.31 cần Kỷ Nguyên lần 2
      s.ascensionCount = 2;
      expect(pendingChapterId(s), 31);
      markChapterSeen(s, 31);
      expect(pendingChapterId(s), isNull); // Ch.32 cần qua màn 25
      s.m3Stars.addAll(List.filled(15, 1)); // giờ dài 27
      expect(pendingChapterId(s), 32);
      markChapterSeen(s, 32);
      expect(pendingChapterId(s), isNull); // Ch.33 cần Kỷ Nguyên lần 3
      s.ascensionCount = 3;
      expect(pendingChapterId(s), 33);
      markChapterSeen(s, 33);
      expect(pendingChapterId(s), isNull); // Ch.34 cần qua màn 40, mới tới 27
      s.m3Stars.addAll(List.filled(15, 1)); // giờ dài 42
      expect(pendingChapterId(s), 34);
      markChapterSeen(s, 34);
      expect(pendingChapterId(s), isNull); // Ch.35 cần qua màn 55, mới tới 42
      s.m3Stars.addAll(List.filled(15, 1)); // giờ dài 57
      expect(pendingChapterId(s), 35);
      markChapterSeen(s, 35);
      expect(pendingChapterId(s), isNull); // Ch.36 cần Kỷ Nguyên lần 4
      s.ascensionCount = 4;
      expect(pendingChapterId(s), 36);
    });

    test('qua màn nhưng 0 sao (chưa thật sự qua) không tính', () {
      final s = _fresh()
        ..storyChapter = 29
        ..ascensionCount = 1;
      s.m3Stars.addAll(List.filled(10, 0)); // chạm màn 10 nhưng chưa được sao nào
      expect(pendingChapterId(s), isNull);
      s.m3Stars[9] = 1;
      expect(pendingChapterId(s), 30);
    });

    test('Chương 36 re-show tới khi chọn trục G, độc lập A-F', () {
      final s = _fresh()
        ..storyChapter = 36
        ..storyChoiceA = 'craft'
        ..ascensionCount = 4;
      expect(pendingChapterId(s), 36);
      expect(applyStoryChoice(s, 36, 'open'), isTrue);
      expect(s.storyChoiceG, 'open');
      expect(s.storyChoiceA, 'craft');
      expect(applyStoryChoice(s, 36, 'secret'), isFalse); // đã chọn
      expect(pendingChapterId(s), isNull); // hết truyện
    });

    test('m3Stars ngắn hơn ngưỡng đúng 1 (off-by-one) không crash, không mở',
        () {
      final s = _fresh()
        ..storyChapter = 29
        ..ascensionCount = 1;
      // Ch.30 cần qua màn 10 (index 9). Danh sách dài 9 (index 0..8) — truy
      // cập index 9 sẽ némRangeError nếu thiếu check độ dài trước &&.
      s.m3Stars.addAll(List.filled(9, 1));
      expect(pendingChapterId(s), isNull);
      s.m3Stars.add(1); // giờ dài 10, index 9 hợp lệ
      expect(pendingChapterId(s), 30);
    });

    test('m3Stars rỗng ở chương cần qua màn: không crash, không mở', () {
      final s = _fresh()
        ..storyChapter = 29
        ..ascensionCount = 1;
      expect(s.m3Stars, isEmpty);
      expect(pendingChapterId(s), isNull);
    });
  });

  group('chapterById: id ngoài phạm vi không crash (VD save từ bản khác)', () {
    test('id = 0, âm, hoặc vượt chương cuối (37, rất lớn) -> rơi về Chương 1',
        () {
      for (final id in [0, -1, -9999, 37, 9999]) {
        expect(chapterById(id).id, 1, reason: 'id=$id');
      }
    });

    test('storyChapter lưu id vượt chương cuối (save từ bản mới hơn, mở '
        'bằng bản cũ): pendingChapterId không crash, coi như hết truyện', () {
      final s = _fresh()..storyChapter = 999;
      expect(() => pendingChapterId(s), returnsNormally);
      expect(pendingChapterId(s), isNull);
    });
  });

  group('storyUnlockProgress / storyTriggerMet (gợi ý mở khoá ở Nhật ký)', () {
    StoryChapter ch(int id) => chapterById(id);

    test('theo giai đoạn: đang có/cần, kẹp ở đích', () {
      // Chương 7 cần giai đoạn 6.
      expect(
          storyUnlockProgress(ch(7), stage: 4, ascensionCount: 0, m3Stars: []),
          (current: 4, target: 6));
      expect(
          storyUnlockProgress(ch(7), stage: 9, ascensionCount: 0, m3Stars: []),
          (current: 6, target: 6)); // không vượt 100%
    });

    test('Kỷ Nguyên và Trân Châu Rơi', () {
      expect(
          storyUnlockProgress(ch(31), stage: 18, ascensionCount: 1, m3Stars: []),
          (current: 1, target: 2));
      // Chương 30 cần qua màn m (xem story.dart); 3 màn đã qua (≥1★) -> current 3.
      final c30 = ch(30);
      final p = storyUnlockProgress(c30,
          stage: 18, ascensionCount: 1, m3Stars: [3, 1, 2, 0, 0]);
      expect(p!.current, 3);
      expect(p.target, c30.value);
    });

    test('điều kiện không đo bằng số -> null', () {
      expect(
          storyUnlockProgress(ch(4), stage: 1, ascensionCount: 0, m3Stars: []),
          isNull); // Nhượng quyền lần đầu
      expect(
          storyUnlockProgress(ch(8), stage: 1, ascensionCount: 0, m3Stars: []),
          isNull); // hạ đối thủ
    });

    test('storyTriggerMet khớp pendingChapterId (cùng một nguồn sự thật)', () {
      final s = GameState.newGame(nowMillis: 0)
        ..storyChapter = 1
        ..stage = 2;
      expect(
          storyTriggerMet(ch(2),
              stage: s.stage,
              hasPrestiged: false,
              rivalDefeated: false,
              ascensionCount: 0,
              m3Stars: s.m3Stars),
          isTrue);
      expect(pendingChapterId(s), 2);
      s.stage = 1;
      expect(pendingChapterId(s), isNull);
    });
  });
}
