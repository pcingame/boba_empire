/// Linh vật quán: nhận nuôi bằng 💎, nâng bằng Xu, nhặt Xu tích luỹ (tối đa [petStoreHours] giờ). Số liệu ước lượng.
library;

import 'dart:math';

const int petMaxLevel = 10;
const int petAdoptGems = 20;
const int petStoreHours = 2;
const double petRatePerLevel = 0.02;
const List<String> petEmoji = ['🐣', '🐥', '🐤', '🐱', '🐶', '🦊', '🐯', '🦁', '🦄', '🐉'];

String petEmojiOf(int level) => petEmoji[(level - 1).clamp(0, petMaxLevel - 1)];

/// Xu để nâng từ [level] (≥1) lên cấp kế: 10 phút thu nhập (sàn 1000) × 2^(level-1).
double petLevelCost(int level, double income) =>
    max(1000.0, (income.isFinite ? income : 0) * 600) * pow(2, level - 1).toDouble();

/// Giây tích luỹ được nhặt: [sinceMillis] đến [nowMillis], trần [petStoreHours] giờ.
double petPendingSeconds(int sinceMillis, int nowMillis) =>
    ((nowMillis - sinceMillis) / 1000).clamp(0, petStoreHours * 3600).toDouble();

/// Xu nhặt được = giây × thu nhập × tỉ lệ theo cấp.
double petPendingXu(int level, int sinceMillis, int nowMillis, double income) =>
    level <= 0 || !income.isFinite ? 0 : petPendingSeconds(sinceMillis, nowMillis) * income * petRatePerLevel * level;
