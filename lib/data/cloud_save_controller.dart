/// Điều phối luồng UI "Đồng bộ đám mây": nhập email → nhập mã 6 số → (nếu
/// cloud đã có save khác) hỏi khôi phục hay giữ máy này → liên kết xong.
///
/// Giống cách `ArenaController` không đụng trực tiếp `GameState` — module
/// này cũng vậy, chỉ gọi qua 2 callback UI tự gán ([getLocalSave],
/// [onRestore]) để lấy/áp dữ liệu ván hiện tại, giữ tách biệt khỏi
/// `game_controller.dart`.
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_save_repository.dart';

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

  /// UI gán trước khi gọi bất kỳ hành động nào (xem `cloud_save_dialog.dart`).
  Map<String, dynamic> Function()? getLocalSave;
  double Function()? getLocalLifetimeEarnings;
  void Function(Map<String, dynamic> json)? onRestore;

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
      state = CloudSaveAwaitingCode(email);
    } catch (e) {
      _fail(e);
    }
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
    onRestore?.call(current.cloud.data);
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
        await _repository.push(save);
      } catch (e) {
        // Không chặn liên kết chỉ vì 1 lần push đầu lỗi mạng — saveNow() ở
        // GameController sẽ tự đẩy lại trong lần lưu kế tiếp.
        developer.log('push đầu tiên lỗi, sẽ tự thử lại lần lưu sau: $e',
            name: 'CloudSave');
      }
    }
    state = CloudSaveLinked(_repository.linkedEmail!);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const CloudSaveUnlinked();
  }

  void backToUnlinked() {
    state = const CloudSaveUnlinked();
  }

  void _fail(Object error) {
    developer.log('$error', name: 'CloudSave');
    state = const CloudSaveError('Có lỗi xảy ra, thử lại sau nhé.');
  }
}

final cloudSaveControllerProvider =
    NotifierProvider<CloudSaveController, CloudSaveViewState>(
        CloudSaveController.new);
