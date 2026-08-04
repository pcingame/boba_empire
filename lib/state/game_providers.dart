/// Các provider Riverpod cho tầng state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_storage.dart';
import 'game_controller.dart';
import 'game_snapshot.dart';

/// Bơm instance SharedPreferences đã khởi tạo. Phải override trong `main()`
/// (và trong test) — mặc định ném lỗi để không ai quên.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

/// Nguồn thời gian (epoch ms). Tách ra để test bơm được thời gian cố định.
final clockProvider = Provider<int Function()>(
  (ref) => () => DateTime.now().millisecondsSinceEpoch,
);

final gameStorageProvider = Provider<GameStorage>(
  (ref) => GameStorage(ref.watch(sharedPreferencesProvider)),
);

final gameControllerProvider =
    NotifierProvider<GameController, GameSnapshot>(GameController.new);
