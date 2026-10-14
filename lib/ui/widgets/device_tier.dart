import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'effects_quality.dart';

/// Mức khởi điểm theo cấu hình Android (thuần, test được): máy "low RAM" hoặc RAM < 3GB hoặc
/// Android < 8 → Thấp; RAM < 6GB hoặc Android < 10 → Vừa; còn lại Cao.
EffectsQuality classifyAndroid({
  required bool isLowRam,
  required int ramMb,
  required int sdkInt,
}) {
  if (isLowRam || ramMb < 3000 || sdkInt < 26) return EffectsQuality.low;
  if (ramMb < 6000 || sdkInt < 29) return EffectsQuality.medium;
  return EffectsQuality.high;
}

/// Mức khởi điểm theo mã máy iOS, ví dụ "iPhone12,1" (thuần). iPhone đời 10 trở xuống
/// (A11 và cũ hơn) → Thấp; đời 10–11 → Vừa; đời 12+ (A13 trở lên) → Cao. iPad và mã lạ → Cao
/// (iPad rất ít khi yếu; mã lạ thường là máy mới hơn bảng này).
EffectsQuality classifyIos(String machine) {
  final m = RegExp(r'^iPhone(\d+),').firstMatch(machine);
  if (m == null) return EffectsQuality.high;
  final gen = int.parse(m.group(1)!);
  if (gen < 10) return EffectsQuality.low;
  if (gen < 12) return EffectsQuality.medium;
  return EffectsQuality.high;
}

/// Đọc cấu hình máy để chọn mức khởi điểm. Mọi lỗi/nền tảng lạ → null (dùng mặc định).
Future<EffectsQuality?> detectDeviceTier() async {
  if (kIsWeb) return null;
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      if (!a.isPhysicalDevice) return EffectsQuality.high;
      return classifyAndroid(
          isLowRam: a.isLowRamDevice, ramMb: a.physicalRamSize, sdkInt: a.version.sdkInt);
    }
    if (Platform.isIOS) {
      final i = await info.iosInfo;
      return i.isPhysicalDevice ? classifyIos(i.utsname.machine) : EffectsQuality.high;
    }
  } catch (_) {}
  return null;
}
