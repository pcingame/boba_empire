/// Điều phối luồng UI "Đồng bộ đám mây": nhập email → nhập mã xác nhận → (nếu
/// cloud đã có save khác) hỏi khôi phục hay giữ máy này → liên kết xong.
///
/// Giống cách `ArenaController` không đụng trực tiếp `GameState` — module
/// này cũng vậy, chỉ gọi qua 2 callback UI tự gán ([getLocalSave],
/// [onRestore]) để lấy/áp dữ liệu ván hiện tại, giữ tách biệt khỏi
/// `game_controller.dart`.
library;

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_save_repository.dart';

/// Thời gian chờ giữa 2 lần gửi mã (giây).
///
/// Không chỉ để chống bấm nhầm: mail OTP đang đi qua Gmail SMTP relay, mà
/// Gmail **defer (lỗi tạm 4xx)** mail tự động gửi dồn dập tới cùng một người
/// nhận — gặp thật 2026-09-26 với bounce "Quá trình gửi không hoàn tất, sẽ
/// thử lại sau 46 giờ", trong khi mã OTP hết hạn sau vài phút nên lần thử
/// lại đó vô dụng. Xem SETUP.md (mục SMTP) — cách sửa gốc là đổi sang
/// provider transactional thật, cái này chỉ giảm số mail trùng.
const int resendCodeCooldownSeconds = 60;

/// Số giây còn phải chờ mới được gửi lại mã (0 = gửi được ngay).
/// [lastSentMillis] = 0 nghĩa là chưa gửi lần nào.
int resendCooldownRemaining(int lastSentMillis, int nowMillis) {
  if (lastSentMillis <= 0) return 0;
  final elapsedSeconds = (nowMillis - lastSentMillis) / 1000;
  // Đồng hồ máy bị lùi (người chơi đổi giờ) → coi như hết hạn chờ, không để
  // nút bị khoá kẹt.
  if (elapsedSeconds < 0) return 0;
  final remaining = (resendCodeCooldownSeconds - elapsedSeconds).ceil();
  return remaining > 0 ? remaining : 0;
}

sealed class CloudSaveViewState {
  const CloudSaveViewState();
}

/// Chưa liên kết — hiện form nhập email.
class CloudSaveUnlinked extends CloudSaveViewState {
  const CloudSaveUnlinked();
}

class CloudSaveSendingCode extends CloudSaveViewState {
  const CloudSaveSendingCode();
}

class CloudSaveAwaitingCode extends CloudSaveViewState {
  const CloudSaveAwaitingCode(this.email);
  final String email;
}

class CloudSaveVerifying extends CloudSaveViewState {
  const CloudSaveVerifying(this.email);
  final String email;
}

/// Cloud đã có save (từ máy khác / lần liên kết trước) — hỏi người chơi
/// khôi phục (ghi đè máy này) hay giữ máy này (ghi đè lên cloud).
class CloudSaveConflict extends CloudSaveViewState {
  const CloudSaveConflict({
    required this.localLifetimeEarnings,
    required this.cloud,
  });
  final double localLifetimeEarnings;
  final CloudSaveResult cloud;
}

class CloudSaveLinked extends CloudSaveViewState {
  const CloudSaveLinked(this.email);
  final String email;
}

class CloudSaveError extends CloudSaveViewState {
  const CloudSaveError(this.message);
  final String message;
}

class CloudSaveController extends Notifier<CloudSaveViewState> {
  CloudSaveRepository? _repo;

  /// Mốc gửi mã thành công gần nhất (epoch ms). Giữ ở controller chứ không ở
  /// widget để đóng/mở lại dialog không reset được thời gian chờ.
  int _lastCodeSentAtMillis = 0;

  /// Đồng hồ (epoch ms) — test ghi đè để khỏi phải chờ thật 60 giây.
  @visibleForTesting
  int Function() clock = () => DateTime.now().millisecondsSinceEpoch;

  /// Số giây còn phải chờ mới được gửi lại mã (0 = gửi được ngay).
  int get resendCooldown =>
      resendCooldownRemaining(_lastCodeSentAtMillis, clock());

  /// UI gán trước khi gọi bất kỳ hành động nào (xem `cloud_save_dialog.dart`).
  Map<String, dynamic> Function()? getLocalSave;
  double Function()? getLocalLifetimeEarnings;
  void Function(Map<String, dynamic> json, int cloudVersion)? onRestore;

  /// true nếu GameController vừa phát hiện xung đột chưa xử lý ở lần lưu
  /// nền gần nhất (xem GameController.cloudConflictPending) — [build] không
  /// tự kiểm tra (đồng bộ, không await được); UI gọi [recheckConflict] sau
  /// frame đầu nếu cờ này true, giống cách các trang khác gọi `refresh()`.
  bool Function()? getLocalConflictPending;

  /// Báo cho GameController biết version cloud mới sau 1 lần push/pull
  /// thành công (xem GameController.applyCloudSyncVersion) — để lần lưu
  /// nền kế tiếp so sánh đúng mốc, không báo xung đột giả.
  void Function(int version)? onSyncVersionKnown;

  @override
  CloudSaveViewState build() {
    return _repository.isLinked
        ? CloudSaveLinked(_repository.linkedEmail!)
        : const CloudSaveUnlinked();
  }

  CloudSaveRepository get _repository =>
      _repo ??= CloudSaveRepository(Supabase.instance.client);

  Future<void> sendCode(String email) async {
    state = const CloudSaveSendingCode();
    try {
      await _repository.sendCode(email);
      // Chỉ tính giờ chờ khi gửi THÀNH CÔNG — gửi lỗi thì không bắt đợi.
      _lastCodeSentAtMillis = clock();
      state = CloudSaveAwaitingCode(email);
    } catch (e) {
      _fail(e);
    }
  }

  /// Gửi lại mã (nút ở màn nhập mã). No-op nếu còn thời gian chờ — UI đã khoá
  /// nút rồi, đây là chốt chặn thứ hai.
  Future<void> resendCode(String email) async {
    if (resendCooldown > 0) return;
    await sendCode(email);
  }

  Future<void> verifyCode(String email, String code) async {
    state = CloudSaveVerifying(email);
    try {
      await _repository.verifyCode(email, code);
      await _afterLinked();
    } catch (e) {
      _fail(e);
    }
  }

  /// Sau khi xác thực mã thành công: có save cloud khác thì hỏi, không thì
  /// đẩy luôn save máy này lên (lần liên kết đầu).
  Future<void> _afterLinked() async {
    final cloud = await _repository.pull();
    final localLifetime = getLocalLifetimeEarnings?.call() ?? 0;
    if (cloud != null && _looksDifferent(cloud, localLifetime)) {
      state = CloudSaveConflict(localLifetimeEarnings: localLifetime, cloud: cloud);
      return;
    }
    await _pushLocal();
  }

  /// So le rõ ràng mới hỏi — chênh lệch quá nhỏ (VD vài Xu do lệch nhịp lưu)
  /// thì khỏi làm phiền người chơi bằng 1 hộp thoại không cần thiết.
  bool _looksDifferent(CloudSaveResult cloud, double localLifetime) {
    final cloudLifetime = (cloud.data['lifetimeEarnings'] as num?)?.toDouble() ?? 0;
    if (localLifetime == 0 && cloudLifetime == 0) return false;
    final diff = (cloudLifetime - localLifetime).abs();
    final base = cloudLifetime > localLifetime ? cloudLifetime : localLifetime;
    return base == 0 ? diff > 0 : diff / base > 0.01;
  }

  /// Người chơi chọn "Khôi phục từ cloud" ở hộp thoại xung đột.
  void restoreFromCloud() {
    final current = state;
    if (current is! CloudSaveConflict) return;
    onRestore?.call(current.cloud.data, current.cloud.version);
    state = CloudSaveLinked(_repository.linkedEmail!);
  }

  /// Người chơi chọn "Giữ máy này" — ghi đè save cloud bằng save local.
  Future<void> keepLocal() async {
    final current = state;
    if (current is! CloudSaveConflict) return;
    await _pushLocal();
  }

  Future<void> _pushLocal() async {
    final save = getLocalSave?.call();
    if (save != null) {
      try {
        final version = await _repository.push(save);
        onSyncVersionKnown?.call(version);
      } catch (e) {
        // Không chặn liên kết chỉ vì 1 lần push đầu lỗi mạng — saveNow() ở
        // GameController sẽ tự đẩy lại trong lần lưu kế tiếp.
        developer.log('push đầu tiên lỗi, sẽ tự thử lại lần lưu sau: $e',
            name: 'CloudSave');
      }
    }
    state = CloudSaveLinked(_repository.linkedEmail!);
  }

  /// UI gọi khi mở dialog VÀ [getLocalConflictPending] báo true — nghĩa là
  /// lần lưu nền gần nhất phát hiện version cloud đã đổi (máy khác vừa lưu)
  /// nhưng chưa được xử lý. Tải lại cloud, so sánh — nếu thật sự khác biệt
  /// thì hỏi lại (tái dùng đúng `CloudSaveConflict` như lúc liên kết lần
  /// đầu); nếu hoá ra không khác biệt đáng kể (VD race hiếm giữa 2 lần lưu
  /// gần nhau) thì âm thầm đồng bộ lại version, không làm phiền.
  Future<void> recheckConflict() async {
    final cloud = await _repository.pull();
    final localLifetime = getLocalLifetimeEarnings?.call() ?? 0;
    if (cloud != null && _looksDifferent(cloud, localLifetime)) {
      state = CloudSaveConflict(localLifetimeEarnings: localLifetime, cloud: cloud);
      return;
    }
    if (cloud != null) onSyncVersionKnown?.call(cloud.version);
    state = CloudSaveLinked(_repository.linkedEmail!);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const CloudSaveUnlinked();
  }

  /// Có thể bị gọi sau khi phiên Supabase ĐÃ chuyển thành tài khoản thật
  /// (verifyCode thành công) nhưng bước sau đó (`_afterLinked`) lỗi mạng —
  /// phải kiểm tra lại trạng thái thật, không được ép về Unlinked mù.
  void backToUnlinked() {
    state = _repository.isLinked
        ? CloudSaveLinked(_repository.linkedEmail!)
        : const CloudSaveUnlinked();
  }

  void _fail(Object error) {
    developer.log('$error', name: 'CloudSave');
    state = const CloudSaveError('Có lỗi xảy ra, thử lại sau nhé.');
  }
}

final cloudSaveControllerProvider =
    NotifierProvider<CloudSaveController, CloudSaveViewState>(
        CloudSaveController.new);
