/// Ghi sự kiện ẩn danh (cùng bảng `analytics_events` với session/phễu — xem
/// lib/data/analytics_repository.dart) để biết tính năng nào thật sự được dùng. Best-effort: chưa
/// có Supabase (test/web) hoặc lỗi mạng thì bỏ qua im lặng. Không nickname, email hay tiền.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/analytics_repository.dart';
import '../state/game_providers.dart';

typedef AnalyticsLogger =
    void Function(String name, [Map<String, Object>? params]);

final analyticsProvider = Provider<AnalyticsLogger>((ref) {
  AnalyticsRepository? repo;
  return (name, [params]) {
    try {
      repo ??= AnalyticsRepository(
          Supabase.instance.client, ref.read(sharedPreferencesProvider));
    } catch (_) {
      return;
    }
    unawaited(repo!.log(name, params ?? const {}));
  };
});

/// Ghi sự kiện từ chỗ chỉ có [BuildContext] (hàm `showXxx` mở hộp thoại).
void trackEvent(
  BuildContext context,
  String name, [
  Map<String, Object>? params,
]) => ProviderScope.containerOf(context, listen: false).read(analyticsProvider)(
  name,
  params,
);
