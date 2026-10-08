/// Nhiệm vụ sự kiện theo dịp lễ (xem `festivals` trong accessories.dart).
/// Tiến độ cộng dồn CẢ dịp (không reset theo ngày), mirror từ [addDailyProgress]
/// nên không cần thêm hook ở game_controller. Hoàn thành → 💎 + điểm sự kiện;
/// điểm đổi món độc quyền của dịp (vào [GameState.ownedLimited], như Gói Lễ Hội).
/// Hàm thuần: thời gian bơm từ ngoài, chỉ mutate [GameState] ở hàm ghi MUTATE.
library;

import 'accessories.dart';
import 'balance.dart';
import 'daily_quests.dart' show DailyQuestKind;
import 'models.dart';

class EventQuest {
  const EventQuest(this.kind, this.target);
  final DailyQuestKind kind;
  final double target;
}

/// Bộ nhiệm vụ cố định mọi dịp (chỉ đổi theme/món thưởng).
const List<EventQuest> eventQuests = [
  EventQuest(DailyQuestKind.tap, 1500),
  EventQuest(DailyQuestKind.buy, 120),
  EventQuest(DailyQuestKind.cat, 6),
  EventQuest(DailyQuestKind.vip, 6),
];

/// Điểm đổi 1 món theo độ hiếm. Tổng điểm nhận được 4×25 = 100 < tổng giá cả bộ
/// (15+25+25+50 = 115): người chơi miễn phí phải CHỌN, muốn đủ bộ thì mua gói.
int eventItemCost(Accessory a) => switch (a.rarity) {
      AccessoryRarity.common || AccessoryRarity.rare => 15,
      AccessoryRarity.epic => 25,
      AccessoryRarity.legendary => 50,
    };

/// Vào dịp mới (hoặc hết dịp) thì xoá tiến độ cũ. MUTATE.
void rollEvent(GameState s, DateTime nowUtc) {
  final id = activeFestival(nowUtc)?.id ?? '';
  if (id == s.eventId) return;
  s.eventId = id;
  s.eventProgress.clear();
  s.eventClaimed.clear();
  s.eventPoints = 0;
}

/// Mirror tiến độ ngày vào sự kiện (gọi từ addDailyProgress). MUTATE.
void addEventProgress(GameState s, DailyQuestKind k, double n) {
  if (s.eventId.isEmpty) return;
  final v = (s.eventProgress[k.name] ?? 0) + n;
  if (v.isFinite) s.eventProgress[k.name] = v;
}

bool eventQuestDone(GameState s, EventQuest q) =>
    (s.eventProgress[q.kind.name] ?? 0) >= q.target;

bool eventQuestClaimed(GameState s, EventQuest q) =>
    s.eventClaimed.contains(q.kind.name);

/// Nhận thưởng nhiệm vụ [index]. Trả về 💎 nhận (0 nếu chưa xong/đã nhận/hết
/// dịp). MUTATE.
int claimEventQuest(GameState s, int index, DateTime nowUtc) {
  rollEvent(s, nowUtc);
  if (s.eventId.isEmpty || index < 0 || index >= eventQuests.length) return 0;
  final q = eventQuests[index];
  if (!eventQuestDone(s, q) || eventQuestClaimed(s, q)) return 0;
  s.eventClaimed.add(q.kind.name);
  s.eventPoints += Balance.eventQuestPoints;
  s.gems += Balance.eventQuestGems;
  return Balance.eventQuestGems;
}

/// Đổi điểm lấy món [itemId] của dịp đang diễn ra. Trả về false nếu không hợp lệ
/// (hết dịp, đã có, thiếu điểm). MUTATE.
bool redeemEventItem(GameState s, String itemId, DateTime nowUtc) {
  rollEvent(s, nowUtc);
  final f = activeFestival(nowUtc);
  if (f == null) return false;
  final item = f.items.where((a) => a.id == itemId).firstOrNull;
  if (item == null || s.ownedLimited.contains(itemId)) return false;
  final cost = eventItemCost(item);
  if (s.eventPoints < cost) return false;
  s.eventPoints -= cost;
  s.ownedLimited.add(itemId);
  return true;
}

/// Điểm xếp hạng sự kiện = chạm ly + 50 x (mèo Mưa vàng + khách VIP). CỐ Ý không
/// tính "Nâng cấp": một lần mua x100 cộng 100 lượt, nhà giàu sẽ bỏ xa mọi người
/// và server không có mức trần hợp lý để chặn gian lận. Trần server: xem
/// event_score_per_hour trong event_leaderboard_schema.sql.
int eventScore(GameState s) => eventScoreOf(s.eventProgress);

int eventScoreOf(Map<String, double> progress) {
  final v = (progress['tap'] ?? 0) +
      50 * ((progress['cat'] ?? 0) + (progress['vip'] ?? 0));
  return v.isFinite ? v.floor() : 0;
}

/// Số thứ chờ nhận (chấm đỏ banner): nhiệm vụ xong chưa nhận.
int eventClaimableCount(GameState s) => s.eventId.isEmpty
    ? 0
    : eventQuests.where((q) => eventQuestDone(s, q) && !eventQuestClaimed(s, q)).length;
