/// Trừu tượng hoá quảng cáo thưởng (rewarded ad).
///
/// Tầng game chỉ phụ thuộc interface này, nên có thể phát triển/test toàn bộ
/// vòng kiếm tiền bằng [StubAdService] mà chưa cần SDK thật. Khi tích hợp
/// Admob, chỉ cần một implementation mới và override [adServiceProvider].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kết quả một lần xem quảng cáo thưởng.
enum RewardOutcome {
  /// Xem hết, được nhận thưởng.
  earned,

  /// Người chơi đóng sớm / không có quảng cáo — không nhận thưởng.
  dismissed,
}

/// Quảng cáo toàn màn hình đưa app vào paused/hidden rồi resumed — KHÔNG phải
/// người chơi rời game. Lifecycle handler hỏi [adBusy] để bỏ qua các sự kiện đó
/// (nếu không: popup "tiền offline", session_end giả, lưu/đồng bộ cloud thừa).
/// Giữ thêm 3s sau khi đóng vì sự kiện `resumed` có thể tới sau callback đóng.
int _adBusyUntilMillis = 0;
bool _adShowing = false;
bool get adBusy =>
    _adShowing || DateTime.now().millisecondsSinceEpoch < _adBusyUntilMillis;

void adShowStarted() => _adShowing = true;

void adShowEnded() {
  _adShowing = false;
  _adBusyUntilMillis = DateTime.now().millisecondsSinceEpoch + 3000;
}

abstract interface class AdService {
  /// Hiển thị quảng cáo thưởng, trả về kết quả.
  Future<RewardOutcome> showRewardedAd();
}

/// Bản giả lập cho lúc phát triển: luôn "xem xong, nhận thưởng" sau một nhịp
/// ngắn để mô phỏng thời gian tải quảng cáo.
class StubAdService implements AdService {
  const StubAdService();

  @override
  Future<RewardOutcome> showRewardedAd() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return RewardOutcome.earned;
  }
}

/// Mặc định dùng stub; override trong `main()` khi đã có Admob thật.
final adServiceProvider = Provider<AdService>((ref) => const StubAdService());
