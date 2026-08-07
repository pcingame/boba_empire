/// AdService thật dùng google_mobile_ads (rewarded ad). Chỉ main.dart import
/// file này để giữ phụ thuộc SDK ở rìa — tầng UI/test chỉ biết [AdService].
library;

import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_service.dart';

class RealAdService implements AdService {
  RealAdService() {
    _load(); // nạp sẵn để lần xem đầu không phải chờ.
  }

  RewardedAd? _ad;
  bool _loading = false;

  void _load() {
    if (_loading || _ad != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
        },
      ),
    );
  }

  @override
  Future<RewardOutcome> showRewardedAd() async {
    final ad = _ad;
    if (ad == null) {
      _load(); // chưa sẵn: bỏ qua lần này, nạp cho lần sau.
      return RewardOutcome.dismissed;
    }
    _ad = null; // rewarded ad chỉ dùng một lần.

    final completer = Completer<RewardOutcome>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _load(); // nạp lại cho lần kế.
        if (!completer.isCompleted) {
          completer.complete(
            earned ? RewardOutcome.earned : RewardOutcome.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _load();
        if (!completer.isCompleted) completer.complete(RewardOutcome.dismissed);
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    return completer.future;
  }
}
