/// Cốt truyện "Đế Chế Trà Sữa" — 18 chương gắn vào các mốc SẴN CÓ (giai đoạn,
/// prestige, hạ đối thủ). Hàm thuần + vài hàm mutate nhỏ (giống [quests.dart]:
/// `claimQuest`). Prose nằm ở [story_content.dart], không ở ARB.
///
/// Chương 9-18 (2026-09-12, mở rộng thế giới): tiếp nối sau "Đế chế toàn cầu"
/// (giai đoạn 6) với hồi truyện IPO/tập đoàn đa ngành + đối thủ mới "Vy -
/// Golden Orb" (thuần narrative, KHÔNG có cơ chế sự kiện đối thủ song song
/// như Hải — xem ghi chú ở [rivalDefeatable] trong rival.dart, cơ chế đó vẫn
/// chỉ gắn với giai đoạn 1-6/Hải).
library;

import 'models.dart';

/// Điều kiện kích hoạt một chương.
enum StoryTrigger { gameStart, stage, firstPrestige, rivalDefeated }

/// Trục nào của lựa chọn nhánh (A = Chương 6, B = Chương 8, C = Chương 13,
/// D = Chương 18).
enum StoryChoiceAxis { a, b, c, d }

/// Một điểm rẽ nhánh: ghi [optionA] hoặc [optionB] vào [axis]. Mỗi lựa chọn
/// cộng một perk nhỏ vĩnh viễn (xem [economy.storyChoiceTapMultiplier] /
/// [economy.storyChoiceIncomeMultiplier]).
class StoryChoiceSpec {
  const StoryChoiceSpec(this.axis, this.optionA, this.optionB);

  final StoryChoiceAxis axis;
  final String optionA;
  final String optionB;
}

class StoryChapter {
  const StoryChapter({
    required this.id,
    required this.emoji,
    required this.trigger,
    this.stageValue = 0,
    this.choice,
  });

  /// 1..18 — cũng là số hiển thị "Chương {id}".
  final int id;

  /// Biểu tượng nhân vật/bối cảnh (không phụ thuộc ngôn ngữ).
  final String emoji;

  final StoryTrigger trigger;

  /// Với [StoryTrigger.stage]: giai đoạn tối thiểu để mở chương.
  final int stageValue;

  /// Khác null ⇒ chương kết bằng một lựa chọn nhánh (dialog modal, không đóng
  /// được tới khi chọn).
  final StoryChoiceSpec? choice;
}

/// Chương giới thiệu đối thủ — từ chương này trở đi đối thủ "hoạt động".
const int rivalIntroChapter = 3;

const List<StoryChapter> storyChapters = [
  StoryChapter(id: 1, emoji: '👵', trigger: StoryTrigger.gameStart),
  StoryChapter(id: 2, emoji: '🧋', trigger: StoryTrigger.stage, stageValue: 2),
  StoryChapter(id: 3, emoji: '😼', trigger: StoryTrigger.stage, stageValue: 3),
  StoryChapter(id: 4, emoji: '⭐', trigger: StoryTrigger.firstPrestige),
  StoryChapter(id: 5, emoji: '😼', trigger: StoryTrigger.stage, stageValue: 4),
  StoryChapter(
    id: 6,
    emoji: '🤔',
    trigger: StoryTrigger.stage,
    stageValue: 5,
    choice: StoryChoiceSpec(StoryChoiceAxis.a, 'craft', 'scale'),
  ),
  StoryChapter(id: 7, emoji: '🌍', trigger: StoryTrigger.stage, stageValue: 6),
  StoryChapter(
    id: 8,
    emoji: '🏆',
    trigger: StoryTrigger.rivalDefeated,
    choice: StoryChoiceSpec(StoryChoiceAxis.b, 'acquire', 'identity'),
  ),
  // --- Mở rộng thế giới (2026-09-12): giai đoạn 7-12, đối thủ mới "Vy". ---
  StoryChapter(id: 9, emoji: '📈', trigger: StoryTrigger.stage, stageValue: 7),
  StoryChapter(id: 10, emoji: '🏢', trigger: StoryTrigger.stage, stageValue: 8),
  StoryChapter(id: 11, emoji: '💼', trigger: StoryTrigger.stage, stageValue: 8),
  StoryChapter(id: 12, emoji: '⚔️', trigger: StoryTrigger.stage, stageValue: 9),
  StoryChapter(
    id: 13,
    emoji: '🧭',
    trigger: StoryTrigger.stage,
    stageValue: 9,
    choice: StoryChoiceSpec(StoryChoiceAxis.c, 'independent', 'merger'),
  ),
  StoryChapter(id: 14, emoji: '🌾', trigger: StoryTrigger.stage, stageValue: 10),
  StoryChapter(id: 15, emoji: '🌐', trigger: StoryTrigger.stage, stageValue: 10),
  StoryChapter(id: 16, emoji: '🤖', trigger: StoryTrigger.stage, stageValue: 11),
  StoryChapter(id: 17, emoji: '🤝', trigger: StoryTrigger.stage, stageValue: 12),
  StoryChapter(
    id: 18,
    emoji: '👑',
    trigger: StoryTrigger.stage,
    stageValue: 12,
    choice: StoryChoiceSpec(StoryChoiceAxis.d, 'soul', 'global'),
  ),
];

StoryChapter chapterById(int id) =>
    storyChapters.firstWhere((c) => c.id == id);

bool _triggerMet(StoryChapter c, GameState s) => switch (c.trigger) {
      StoryTrigger.gameStart => true,
      StoryTrigger.stage => s.stage >= c.stageValue,
      // Bình thường Chương 4 mở ở lần prestige đầu; nhưng nếu ai đó lên tới giai
      // đoạn cuối bằng "mở giai đoạn tức thì" (💎) mà chưa prestige lần nào thì
      // vẫn mở để chuỗi truyện không kẹt.
      StoryTrigger.firstPrestige => s.prestigeStars > 0 || s.stage >= 6,
      StoryTrigger.rivalDefeated => s.rivalDefeated,
    };

String? _choiceValue(GameState s, StoryChoiceAxis axis) => switch (axis) {
      StoryChoiceAxis.a => s.storyChoiceA,
      StoryChoiceAxis.b => s.storyChoiceB,
      StoryChoiceAxis.c => s.storyChoiceC,
      StoryChoiceAxis.d => s.storyChoiceD,
    };

/// Chương cần hiển thị ngay bây giờ, hoặc null nếu không có.
///
/// - Nếu chương hiện tại là chương-lựa-chọn mà người chơi CHƯA chọn → trả lại
///   chính nó (re-show tới khi chọn — chống kẹt nửa vời khi kill app giữa dialog).
/// - Ngược lại: chương kế tiếp theo thứ tự có điều kiện đã thoả. Chương phải mở
///   TUẦN TỰ — gặp chương chưa thoả điều kiện thì dừng (không nhảy cóc).
int? pendingChapterId(GameState s) {
  if (s.storyChapter >= 1) {
    final cur = chapterById(s.storyChapter);
    if (cur.choice != null && _choiceValue(s, cur.choice!.axis) == null) {
      return cur.id;
    }
  }
  for (final c in storyChapters) {
    if (c.id <= s.storyChapter) continue;
    if (_triggerMet(c, s)) return c.id;
    break;
  }
  return null;
}

/// Đối thủ đã "vào truyện" chưa (Chương 3 trở đi và chưa bị hạ).
bool rivalActive(GameState s) =>
    s.storyChapter >= rivalIntroChapter && !s.rivalDefeated;

/// Đánh dấu đã xem chương [id] (chỉ tăng con trỏ). MUTATE.
void markChapterSeen(GameState s, int id) {
  if (id > s.storyChapter) s.storyChapter = id;
}

/// Ghi lựa chọn nhánh cho [chapterId]. Trả về true nếu vừa ghi (false nếu chương
/// không có lựa chọn, key sai, hoặc đã chọn rồi). MUTATE.
bool applyStoryChoice(GameState s, int chapterId, String optionKey) {
  final choice = chapterById(chapterId).choice;
  if (choice == null) return false;
  if (optionKey != choice.optionA && optionKey != choice.optionB) return false;
  switch (choice.axis) {
    case StoryChoiceAxis.a:
      if (s.storyChoiceA != null) return false;
      s.storyChoiceA = optionKey;
    case StoryChoiceAxis.b:
      if (s.storyChoiceB != null) return false;
      s.storyChoiceB = optionKey;
    case StoryChoiceAxis.c:
      if (s.storyChoiceC != null) return false;
      s.storyChoiceC = optionKey;
    case StoryChoiceAxis.d:
      if (s.storyChoiceD != null) return false;
      s.storyChoiceD = optionKey;
  }
  return true;
}
