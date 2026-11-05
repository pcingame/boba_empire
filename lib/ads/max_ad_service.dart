/// Quảng cáo Android qua AppLovin MAX (iOS vẫn dùng AdMob, xem main.dart).
/// Chỉ main.dart và banner_ad_box.dart import file này.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:applovin_max/applovin_max.dart';

import 'ad_config.dart';
import 'ad_service.dart';

/// Future init SDK — gán vào `AdBootstrap.ready` để banner chờ đúng như AdMob.
Future<void> initMaxAds() => AppLovinMAX.initialize(AdConfig.maxSdkKey);

class MaxAdService implements AdService {
  MaxAdService({required Future<void> ready, this.onUnavailable})
      : _ready = ready {
    ready.then((_) {
      AppLovinMAX.setRewardedAdListener(RewardedAdListener(
        onAdLoadedCallback: (_) {},
        onAdLoadFailedCallback: (id, error) => developer.log(
          'Rewarded ad failed to load: ${error.message}',
          name: 'AdService',
        ),
        onAdDisplayedCallback: (_) {},
        onAdDisplayFailedCallback: (ad, error) {
          developer.log('Rewarded ad failed to show: ${error.message}',
              name: 'AdService');
          _finish(RewardOutcome.dismissed);
        },
        onAdClickedCallback: (_) {},
        onAdHiddenCallback: (_) => _finish(
          _earned ? RewardOutcome.earned : RewardOutcome.dismissed,
        ),
        onAdReceivedRewardCallback: (ad, reward) => _earned = true,
      ));
      AppLovinMAX.loadRewardedAd(AdConfig.maxRewardedUnitId); // nạp sẵn.
    });
  }

  final Future<void> _ready;

  /// Gọi khi người chơi bấm xem mà quảng cáo chưa nạp xong.
  final void Function()? onUnavailable;
  Completer<RewardOutcome>? _showing;
  bool _earned = false;

  void _finish(RewardOutcome outcome) {
    adShowEnded();
    // MAX không tự nạp lại: phải gọi load cho lần kế.
    AppLovinMAX.loadRewardedAd(AdConfig.maxRewardedUnitId);
    final c = _showing;
    _showing = null;
    if (c != null && !c.isCompleted) c.complete(outcome);
  }

  @override
  Future<RewardOutcome> showRewardedAd() async {
    await _ready;
    final id = AdConfig.maxRewardedUnitId;
    if (_showing != null || await AppLovinMAX.isRewardedAdReady(id) != true) {
      AppLovinMAX.loadRewardedAd(id);
      onUnavailable?.call();
      return RewardOutcome.dismissed;
    }
    _earned = false;
    final completer = _showing = Completer<RewardOutcome>();
    adShowStarted();
    AppLovinMAX.showRewardedAd(id);
    return completer.future;
  }
}
