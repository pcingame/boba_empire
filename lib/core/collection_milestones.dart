/// Mốc 80/100/120 thêm khi danh mục lên 120 món, 140/160 khi lên 160 (2026-10-06).
/// Mốc sưu tập: đủ [count] món khác nhau thì nhận [coins] Xu Chợ (một lần) +
/// danh hiệu. Server tự đếm và chặn nhận lặp — xem claim_collection_milestone
/// trong supabase/accessory_market_schema.sql (PHẢI khớp bảng thưởng ở đó).
library;

import 'models.dart';

class CollectionMilestone {
  const CollectionMilestone(this.count, this.coins);
  final int count;
  final int coins;
}

const collectionMilestones = [
  CollectionMilestone(10, 20),
  CollectionMilestone(25, 50),
  CollectionMilestone(40, 100),
  CollectionMilestone(50, 200),
  CollectionMilestone(80, 300),
  CollectionMilestone(100, 500),
  CollectionMilestone(120, 800),
  CollectionMilestone(140, 1100),
  CollectionMilestone(160, 1500),
];

bool milestoneReached(GameState s, CollectionMilestone m) =>
    s.ownedAccessories.length >= m.count;

bool milestoneClaimed(GameState s, CollectionMilestone m) =>
    s.collectionMilestonesClaimed.contains(m.count);

/// Số mốc đã đạt mà chưa nhận.
int milestonesClaimable(GameState s) => collectionMilestones
    .where((m) => milestoneReached(s, m) && !milestoneClaimed(s, m))
    .length;

/// Mốc cao nhất đã nhận (danh hiệu hiện tại), null nếu chưa nhận mốc nào.
CollectionMilestone? highestClaimedMilestone(GameState s) {
  CollectionMilestone? best;
  for (final m in collectionMilestones) {
    if (milestoneClaimed(s, m)) best = m;
  }
  return best;
}
