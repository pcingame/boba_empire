/// AdService thật dùng google_mobile_ads (rewarded ad). Chỉ main.dart import
/// file này để giữ phụ thuộc SDK ở rìa — tầng UI/test chỉ biết [AdService].
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_service.dart';

class RealAdService implements AdService {
  /// [ready] là Future init AdMob ([AdBootstrap.initialize]) đang chạy song song
  /// với `runApp` — mọi lần nạp quảng cáo phải chờ nó xong, vì `RewardedAd.load`
  /// trước khi SDK init sẽ thất bại.
  RealAdService({Future<void>? ready})
      : _ready = ready ?? Future<void>.value() {
    _load(); // nạp sẵn để lần xem đầu không phải chờ.
  }

  final Future<void> _ready;
  RewardedAd? _ad;
  bool _loading = false;

  Future<void> _load() async {
    if (_loading || _ad != null) return;
    _loading = true;
    await _ready;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          developer.log(
            'Rewarded ad failed to load: $error',
            name: 'AdService',
          );
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
      developer.log('Rewarded ad not ready when requested', name: 'AdService');
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
        developer.log(
          'Rewarded ad failed to show: $error',
          name: 'AdService',
        );
        ad.dispose();
        _load();
        if (!completer.isCompleted) completer.complete(RewardOutcome.dismissed);
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    return completer.future;
  }
}
