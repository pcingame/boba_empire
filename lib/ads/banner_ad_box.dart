/// Ô banner quảng cáo cho Hành trình Ghép 3.
///
/// Tự biến mất (SizedBox.shrink) khi: không phải Android/iOS, người chơi đã mua
/// "Gỡ quảng cáo" hoặc đang VIP (`GameSnapshot.adFree`), hoặc chưa cấu hình
/// unit id thật. Giữ SDK ở rìa như `real_ad_service.dart` — tầng UI chỉ cần
/// `const BannerAdBox()`.
///
/// KHÔNG đặt trong trận Đấu Trường: trận tính giờ 60 giây, chạm nhầm là thua.
library;

import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../state/game_providers.dart';
import 'ad_bootstrap.dart';
import 'ad_config.dart';

class BannerAdBox extends ConsumerStatefulWidget {
  const BannerAdBox({super.key});

  @override
  ConsumerState<BannerAdBox> createState() => _BannerAdBoxState();
}

class _BannerAdBoxState extends ConsumerState<BannerAdBox> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_requested) return;
    _requested = true;
    // PHẢI chờ SDK init xong. Gọi sớm hơn thì hàm đo cỡ banner bên dưới trả
    // null và cả ô banner biến mất im lặng cả phiên — đúng lỗi đã gặp khi mở
    // thẳng vào tab Ghép 3 lúc app vừa mở.
    await AdBootstrap.ready;
    if (!mounted) return;
    // Adaptive banner: cao theo bề ngang máy thay vì 320x50 cứng.
    final media = MediaQuery.of(context);
    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
      media.orientation,
      media.size.width.truncate(),
    );
    if (!mounted) return;
    if (size == null) {
      // Cho phép thử lại ở lần dựng sau thay vì tắt hẳn cả phiên.
      _requested = false;
      developer.log('Không đo được cỡ banner', name: 'AdService');
      return;
    }
    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // Ghi lại lý do: "no fill" (hết quảng cáo để trả) khác hẳn "SDK chưa
          // init" — không log thì banner im lặng biến mất mà không biết vì sao.
          developer.log('Banner failed to load: $error', name: 'AdService');
          // Không thử lại: thất bại thường là "chưa có quảng cáo để trả", tự
          // bấm lại liên tục chỉ bơm request rác vào tài khoản AdMob.
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final adFree = ref.watch(gameControllerProvider.select((s) => s.adFree));
    if (!_supported || adFree || AdConfig.bannerUnitId.isEmpty) {
      return const SizedBox.shrink();
    }
    _load();
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        // Đệm để banner không dính sát vùng chạm phía trên (chống chạm nhầm —
        // yêu cầu chính sách AdMob, không phải thẩm mỹ).
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
