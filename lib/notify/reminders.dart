/// Nhắc người chơi quay lại bằng thông báo cục bộ (không cần server đẩy).
///
/// Hai mốc, đặt lại mỗi lần app chuyển nền và xoá sạch khi mở lại:
///  1. Kho Xu offline đã đầy → không tích thêm nữa, quay lại nhận đi.
///  2. Sang ngày mới → điểm danh + vòng quay free + 3 nhiệm vụ ngày.
///
/// Quyền thông báo xin lúc app ĐANG Ở TRƯỚC (lần resume đầu tiên), không xin
/// lúc khởi động — màn mở app đã có sẵn ATT + form đồng ý quảng cáo.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Mốc "kho Xu offline đã đầy": [capSeconds] là trần offline THẬT của người
/// chơi (đã cộng cấp "Kho lạnh" + thưởng VIP).
DateTime offlineFullAt(DateTime now, int capSeconds) =>
    now.toUtc().add(Duration(seconds: capSeconds));

/// Mốc "ngày mới": game đổi ngày lúc nửa đêm UTC (xem `dayIndex` trong
/// core/daily.dart). Nếu mốc đó rơi vào đêm theo giờ máy (22:00-08:00) thì dời
/// tới 10:00 sáng — không ai muốn bị ping lúc 2 giờ sáng.
DateTime dailyResetAt(DateTime now) {
  final utc = now.toUtc();
  final midnight = DateTime.utc(utc.year, utc.month, utc.day)
      .add(const Duration(days: 1));
  final local = midnight.toLocal();
  if (local.hour < 22 && local.hour >= 8) return midnight;
  final morning = DateTime(local.year, local.month, local.day, 10);
  return (morning.isAfter(local) ? morning : morning.add(const Duration(days: 1)))
      .toUtc();
}

class Reminders {
  const Reminders._();

  static const int _idOfflineFull = 1;
  static const int _idDaily = 2;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<bool> _ensureInit() async {
    if (!_supported) return false;
    if (_inited) return true;
    tzdata.initializeTimeZones();
    // ponytail: chỉ đặt lịch theo MỐC TUYỆT ĐỐI (now + X, hoặc một mốc UTC đã
    // tính sẵn) nên để local = UTC là đủ và khỏi thêm dep dò múi giờ. Muốn kiểu
    // "8 giờ sáng giờ máy hằng ngày" thì mới cần flutter_timezone.
    tz.setLocalLocation(tz.UTC);
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _inited = true;
    return true;
  }

  /// Xin quyền thông báo. Gọi khi app đang hiện (resumed) — hệ điều hành chỉ
  /// hỏi người chơi một lần, các lần sau trả lại câu trả lời cũ, không hiện gì.
  static Future<bool> requestPermission() async {
    if (!await _ensureInit()) return false;
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Đặt lại toàn bộ lịch nhắc (gọi lúc app chuyển nền). Mốc đã qua thì bỏ.
  static Future<void> schedule({
    required DateTime now,
    required int offlineCapSeconds,
    required String offlineTitle,
    required String offlineBody,
    required String dailyTitle,
    required String dailyBody,
  }) async {
    if (!await _ensureInit()) return;
    await cancelAll();
    await _at(_idOfflineFull, offlineFullAt(now, offlineCapSeconds),
        offlineTitle, offlineBody);
    await _at(_idDaily, dailyResetAt(now), dailyTitle, dailyBody);
  }

  /// Xoá lịch (gọi khi người chơi đã mở app — nhắc nữa là phiền).
  static Future<void> cancelAll() async {
    if (!await _ensureInit()) return;
    await _plugin.cancelAll();
  }

  static Future<void> _at(
    int id,
    DateTime whenUtc,
    String title,
    String body,
  ) async {
    if (!whenUtc.isAfter(DateTime.now().toUtc())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(whenUtc, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Reminders',
          channelDescription: 'Nhắc quay lại quán',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Không dùng báo thức chính xác: tránh phải xin quyền
      // SCHEDULE_EXACT_ALARM trên Android 12+, lệch vài phút không sao.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
