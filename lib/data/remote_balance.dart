/// Ghi đè vài nút vặn cân bằng bằng Firebase Remote Config, để tune game mà
/// KHÔNG phải nộp bản mới lên store (chờ duyệt iOS vài ngày là quá chậm cho
/// một vòng tune số).
///
/// Tên key trên console = đúng tên field trong [Balance], khỏi phải tra bảng.
/// Mỗi nút có khoảng hợp lệ: gõ nhầm trên console (số 0, số âm, thừa chữ số)
/// sẽ bị BỎ QUA chứ không phá save người chơi — `milestoneStep = 0` chẳng hạn
/// là chia cho 0 trong `economy.dart` → Infinity/NaN, đúng lớp bug đã từng làm
/// Xu âm.
library;

import 'dart:developer' as developer;

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../core/balance.dart';

/// Một nút vặn: đọc giá trị hiện tại, ghi giá trị mới, và khoảng hợp lệ.
typedef _Knob = ({
  double Function() read,
  void Function(double v) write,
  double min,
  double max,
});

class RemoteBalance {
  const RemoteBalance._();

  static final Map<String, _Knob> _knobs = {
    // Kinh tế lõi — xem GAME_DESIGN §5 trước khi vặn.
    'bonusPerStar': (
      read: () => Balance.bonusPerStar,
      write: (v) => Balance.bonusPerStar = v,
      min: 0.0001,
      max: 1,
    ),
    'prestigeK': (
      read: () => Balance.prestigeK,
      write: (v) => Balance.prestigeK = v,
      // Trần 0.05: trigger chống gian lận của bảng xếp hạng
      // (leaderboard_schema.sql) chặn sao > floor(0.05·√lifetime). Vặn cao hơn
      // là mọi người chơi bị server từ chối.
      min: 0.001,
      max: 0.05,
    ),
    'milestoneStep': (
      read: () => Balance.milestoneStep.toDouble(),
      write: (v) => Balance.milestoneStep = v.round(),
      min: 5,
      max: 500,
    ),
    'milestoneFactor': (
      read: () => Balance.milestoneFactor,
      write: (v) => Balance.milestoneFactor = v,
      min: 1.1,
      max: 5,
    ),
    'milestoneGlobalBonus': (
      read: () => Balance.milestoneGlobalBonus,
      write: (v) => Balance.milestoneGlobalBonus = v,
      min: 0,
      max: 1,
    ),
    // Giữ chân / nhịp quay lại.
    'maxOfflineSeconds': (
      read: () => Balance.maxOfflineSeconds.toDouble(),
      write: (v) => Balance.maxOfflineSeconds = v.round(),
      min: 60 * 30,
      max: 7 * 24 * 60 * 60,
    ),
    'catSpawnMinMs': (
      read: () => Balance.catSpawnMinMs.toDouble(),
      write: (v) => Balance.catSpawnMinMs = v.round(),
      min: 10 * 1000,
      max: 60 * 60 * 1000,
    ),
    'catSpawnMaxMs': (
      read: () => Balance.catSpawnMaxMs.toDouble(),
      write: (v) => Balance.catSpawnMaxMs = v.round(),
      min: 10 * 1000,
      max: 60 * 60 * 1000,
    ),
    'vipSpawnMinMs': (
      read: () => Balance.vipSpawnMinMs.toDouble(),
      write: (v) => Balance.vipSpawnMinMs = v.round(),
      min: 10 * 1000,
      max: 60 * 60 * 1000,
    ),
    'vipSpawnMaxMs': (
      read: () => Balance.vipSpawnMaxMs.toDouble(),
      write: (v) => Balance.vipSpawnMaxMs = v.round(),
      min: 10 * 1000,
      max: 60 * 60 * 1000,
    ),
    // Nguồn 💎 — theo dõi lạm phát 💎 (GAME_DESIGN §19).
    'dailyQuestRewardGems': (
      read: () => Balance.dailyQuestRewardGems.toDouble(),
      write: (v) => Balance.dailyQuestRewardGems = v.round(),
      min: 0,
      max: 200,
    ),
    'dailyQuestBonusGems': (
      read: () => Balance.dailyQuestBonusGems.toDouble(),
      write: (v) => Balance.dailyQuestBonusGems = v.round(),
      min: 0,
      max: 500,
    ),
  };

  /// Giá trị đang biên dịch trong app — dùng làm default của Remote Config để
  /// chưa fetch được (offline, lần chạy đầu) vẫn đúng như bản đã test.
  static Map<String, Object> defaults() =>
      {for (final e in _knobs.entries) e.key: e.value.read()};

  /// Áp các giá trị đọc từ Remote Config. Key lạ hoặc ngoài khoảng hợp lệ bị bỏ
  /// qua (giữ giá trị biên dịch sẵn). Trả về số nút đã đổi.
  static int applyValues(Map<String, num> values) {
    var applied = 0;
    for (final entry in values.entries) {
      final knob = _knobs[entry.key];
      if (knob == null) continue;
      final v = entry.value.toDouble();
      if (!v.isFinite || v < knob.min || v > knob.max) {
        developer.log(
          'Bỏ qua ${entry.key}=$v (ngoài khoảng ${knob.min}..${knob.max})',
          name: 'RemoteBalance',
        );
        continue;
      }
      if (v == knob.read()) continue;
      knob.write(v);
      applied++;
    }
    return applied;
  }

  /// Gọi một lần ở `main()`, KHÔNG await — mạng chậm không được chặn frame đầu.
  /// Áp giá trị cache của phiên trước ngay, rồi áp tiếp bản mới khi fetch xong.
  static Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await rc.setDefaults(defaults());
      _applyFrom(rc); // bản đã activate từ phiên trước
      await rc.fetchAndActivate();
      _applyFrom(rc); // bản vừa tải về, áp luôn cho phiên này
    } catch (e) {
      // Không có mạng / chưa bật Remote Config trên console → giữ số biên dịch.
      developer.log('Không nạp được Remote Config: $e', name: 'RemoteBalance');
    }
  }

  static void _applyFrom(FirebaseRemoteConfig rc) {
    applyValues({for (final k in _knobs.keys) k: rc.getDouble(k)});
  }
}
