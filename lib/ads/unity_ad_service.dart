/// Quảng cáo Android qua Unity Ads (iOS vẫn dùng AdMob, xem main.dart).
/// Chỉ main.dart và banner_ad_box.dart import file này.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'ad_config.dart';
import 'ad_service.dart';

/// Future init SDK — gán vào `AdBootstrap.ready` để banner chờ đúng như AdMob.
/// Init lỗi vẫn hoàn tất Future (không treo nút xem quảng cáo), chỉ ghi log.
/// Bản debug chạy chế độ thử của Unity: không tính là traffic thật.
Future<void> initUnityAds() {
  final done = Completer<void>();
  UnityAds.init(
    gameId: AdConfig.unityGameId,
    testMode: !kReleaseMode,
    onComplete: () {
      if (!done.isCompleted) done.complete();
    },
    onFailed: (error, message) {
      developer.log('Unity Ads init failed: $error $message', name: 'AdService');
      if (!done.isCompleted) done.complete();
    },
  );
  return done.future;
}

class UnityAdService implements AdService {
  UnityAdService({required Future<void> ready, this.onUnavailable})
      : _ready = ready {
    ready.then((_) => _load()); // nạp sẵn.
  }

  final Future<void> _ready;

  /// Gọi khi người chơi bấm xem mà quảng cáo chưa nạp xong.
  final void Function()? onUnavailable;
  Completer<RewardOutcome>? _showing;
  bool _loaded = false;

  void _load() {
    _loaded = false;
    UnityAds.load(
      placementId: AdConfig.unityRewardedId,
      onComplete: (_) => _loaded = true,
      onFailed: (_, error, message) => developer.log(
        'Rewarded ad failed to load: $error $message',
        name: 'AdService',
      ),
    );
  }

  void _finish(RewardOutcome outcome) {
    adShowEnded();
    _load(); // Unity không tự nạp lại: phải gọi load cho lần kế.
    final c = _showing;
    _showing = null;
    if (c != null && !c.isCompleted) c.complete(outcome);
  }

  @override
  Future<RewardOutcome> showRewardedAd() async {
    await _ready;
    if (_showing != null || !_loaded) {
      if (_showing == null) _load();
      onUnavailable?.call();
      return RewardOutcome.dismissed;
    }
    final completer = _showing = Completer<RewardOutcome>();
    adShowStarted();
    UnityAds.showVideoAd(
      placementId: AdConfig.unityRewardedId,
      // onComplete = xem hết; onSkipped = bỏ giữa chừng → không thưởng.
      onComplete: (_) => _finish(RewardOutcome.earned),
      onSkipped: (_) => _finish(RewardOutcome.dismissed),
      onFailed: (_, error, message) {
        developer.log('Rewarded ad failed to show: $error $message',
            name: 'AdService');
        _finish(RewardOutcome.dismissed);
      },
    );
    return completer.future;
  }
}
