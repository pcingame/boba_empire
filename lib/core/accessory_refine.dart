/// Tinh luyện phụ kiện: mỗi cấp +25% điểm của món trong bộ trang bị, giá = bản dư của chính món đó + 🧪.
/// KHÔNG nâng trần họ nào (xem PROPOSAL_ACCESSORY_REFINE.md). Hàm thuần trên [GameState].
library;

import 'accessories.dart';
import 'balance.dart';
import 'models.dart';

int refineLevel(Map<String, int> levels, String id) =>
    (levels[id] ?? 0).clamp(0, Balance.refineMaxLevel);

/// Hệ số nhân điểm của món [id]: 1 + cấp × [Balance.refinePerLevel] ∈ [1, 1.75].
double refineMultiplier(Map<String, int> levels, String id) =>
    1 + refineLevel(levels, id) * Balance.refinePerLevel;

/// Giá lên cấp kế từ [level] hiện có; null nếu đã đầy.
({int spares, int essence})? refineNextCost(int level) =>
    level < 0 || level >= Balance.refineMaxLevel
        ? null
        : (spares: Balance.refineSpares[level], essence: Balance.refineEssence[level]);

enum RefineResult { ok, unknown, notOwned, maxed, notEnoughSpares, notEnoughEssence }

/// Nâng một cấp cho [id]. Chỉ tiêu bản DƯ còn trong kho ([GameState.accessorySpares]) — bản đang rao ở Chợ
/// đã bị trừ khỏi đó nên không bị đụng. Không đổi gì nếu thất bại. MUTATE khi thành công.
RefineResult tryRefine(GameState s, String id) {
  if (accessoryOrNull(id) == null) return RefineResult.unknown;
  if (!s.ownedAccessories.contains(id) && !s.ownedLimited.contains(id)) return RefineResult.notOwned;
  final cost = refineNextCost(refineLevel(s.refineLevels, id));
  if (cost == null) return RefineResult.maxed;
  if ((s.accessorySpares[id] ?? 0) < cost.spares) return RefineResult.notEnoughSpares;
  if (s.essence < cost.essence) return RefineResult.notEnoughEssence;
  final left = (s.accessorySpares[id] ?? 0) - cost.spares;
  if (left > 0) {
    s.accessorySpares[id] = left;
  } else {
    s.accessorySpares.remove(id);
  }
  s.essence -= cost.essence;
  s.refineLevels[id] = refineLevel(s.refineLevels, id) + 1;
  return RefineResult.ok;
}

/// Tổng 🧪 đã đổ vào các cấp tinh luyện (cộng dồn giá các cấp đã đạt) — thước đo tiến độ để so hai save.
int refineEssenceSpent(Map<String, int> levels) {
  var total = 0;
  for (final v in levels.values) {
    final l = v.clamp(0, Balance.refineMaxLevel);
    for (var i = 0; i < l; i++) {
      total += Balance.refineEssence[i];
    }
  }
  return total;
}

/// Chuỗi so sánh được theo giá trị (để `select` của Riverpod không dựng lại mỗi giây vì Map mới).
String refineSignature(Map<String, int> levels) {
  final keys = levels.keys.toList()..sort();
  return [for (final k in keys) if ((levels[k] ?? 0) > 0) '$k=${levels[k]}'].join(',');
}

Map<String, int> refineFromSignature(String sig) => {
      for (final part in sig.split(','))
        if (part.contains('='))
          part.substring(0, part.indexOf('=')): int.tryParse(part.substring(part.indexOf('=') + 1)) ?? 0,
    };
