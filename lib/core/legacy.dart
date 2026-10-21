/// Di sản — endgame sau Kỷ Nguyên 4: hai perk KHÔNG trần cứng (trần 60 cấp chỉ để tránh tràn số), mua bằng ⏳ Điểm Kỷ Nguyên
/// còn dư. Giá nhân 1.6 mỗi cấp trong khi ⏳ chỉ tăng theo √lifetime ⇒ tiến triển chậm dần nhưng không bao giờ hết việc.
/// Giữ qua Kỷ Nguyên. Số liệu ước lượng, chưa playtest.
library;

import 'dart:math';

const int legacyMinAscensions = 4;
const int legacyMaxLevel = 60;
const double legacyPerLevel = 0.03;

bool legacyUnlocked(int ascensionCount) => ascensionCount >= legacyMinAscensions;

/// ⏳ để nâng từ [level] lên cấp kế.
int legacyCost(int level) => (6 * pow(1.6, level)).round();

/// Tổng ⏳ đã tiêu cho một perk đạt [level].
int legacySpent(int level) {
  var total = 0;
  for (var l = 0; l < level.clamp(0, legacyMaxLevel); l++) {
    total += legacyCost(l);
  }
  return total;
}

double legacyMultiplier(int level) => 1 + level.clamp(0, legacyMaxLevel) * legacyPerLevel;
