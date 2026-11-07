/// Kiểm chứng ĐÚNG giả định của hướng dẫn force update: thẻ `[:mav: 1.0.6]` trong
/// mô tả bản live trên App Store (và thẻ Play) chặn bản cũ — hộp cập nhật mất nút
/// "Để sau/Bỏ qua" — còn bản mới nhất / mô tả không có thẻ thì không bị chặn.
/// Dùng chính `upgrader` (parse JSON iTunes thật) với HTTP giả, không chạm mạng.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'package:boba_empire/main.dart' show androidAppcastUrl, handleUpdateTap;

String _itunes(String description) => jsonEncode({
      'resultCount': 1,
      'results': [
        {
          'version': '1.0.6',
          'description': description,
          'releaseNotes': 'Bộ sưu tập & Chợ phụ kiện',
          'trackViewUrl': 'https://apps.apple.com/app/id1',
          'bundleId': 'com.pcingame.bobaempire',
        },
      ],
    });

PackageInfo _installed(String v) => PackageInfo(
      appName: 'Boba Empire',
      packageName: 'com.pcingame.bobaempire',
      version: v,
      buildNumber: '10',
    );

Future<Upgrader> _upgrader(
    WidgetTester t, String description, String installed) async {
  SharedPreferences.setMockInitialValues({});
  // Tạo + khởi tạo NGOÀI FakeAsync: Upgrader dùng Future/Timer thật.
  return (await t.runAsync(() async {
    final client = MockClient((_) async => http.Response(
        _itunes(description), 200,
        headers: {'content-type': 'application/json; charset=utf-8'}));
    final u = Upgrader(
      client: client,
      countryCode: 'VN',
      languageCode: 'vi',
      // Giả lập iOS (nhánh App Store) để test không phụ thuộc máy chạy (macOS cục bộ, Linux trên CI).
      upgraderOS: MockUpgraderOS(os: 'ios', ios: true),
    );
    u.installPackageInfo(packageInfo: _installed(installed));
    await u.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return u;
  }))!;
}

void main() {
  const tagged = 'Đế Chế Trà Sữa.\n\n[:mav: 1.0.6]';

  testWidgets('bản cũ 1.0.5 + mô tả có thẻ [:mav: 1.0.6] → BỊ CHẶN', (t) async {
    final u = await _upgrader(t, tagged, '1.0.5');
    expect(u.belowMinAppVersion(), isTrue);
    expect(u.blocked(), isTrue);
    expect(u.isUpdateAvailable(), isTrue);
  });

  testWidgets('đã ở 1.0.6 + có thẻ → không bị chặn, không có bản mới', (t) async {
    final u = await _upgrader(t, tagged, '1.0.6');
    expect(u.blocked(), isFalse);
    expect(u.isUpdateAvailable(), isFalse);
  });

  testWidgets('bản cũ + KHÔNG có thẻ → có bản mới nhưng KHÔNG bị chặn',
      (t) async {
    final u = await _upgrader(t, 'Đế Chế Trà Sữa.', '1.0.5');
    expect(u.isUpdateAvailable(), isTrue);
    expect(u.blocked(), isFalse);
  });

  testWidgets('bản rất cũ 1.0.3 cũng bị chặn bởi thẻ', (t) async {
    final u = await _upgrader(t, tagged, '1.0.3');
    expect(u.blocked(), isTrue);
  });

  testWidgets('hộp: bị chặn → không có "Để sau/Bỏ qua", không đóng được bằng chạm ngoài',
      (t) async {
    final u = await _upgrader(t, tagged, '1.0.5');
    await t.pumpWidget(MaterialApp(
      home: UpgradeAlert(upgrader: u, child: const Scaffold(body: Text('home'))),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('CẬP NHẬT'), findsOneWidget);
    expect(find.text('ĐỂ SAU'), findsNothing);
    expect(find.text('BỎ QUA'), findsNothing);
    // Chạm ra ngoài hộp: vẫn còn.
    await t.tapAt(const Offset(2, 2));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('CẬP NHẬT'), findsOneWidget);
  });

  testWidgets('hộp: không bị chặn → có nút Later/Ignore như cũ', (t) async {
    final u = await _upgrader(t, 'Đế Chế Trà Sữa.', '1.0.5');
    await t.pumpWidget(MaterialApp(
      home: UpgradeAlert(upgrader: u, child: const Scaffold(body: Text('home'))),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('CẬP NHẬT'), findsOneWidget);
    expect(find.text('ĐỂ SAU'), findsOneWidget);
    expect(find.text('BỎ QUA'), findsOneWidget);
  });

  // Android (APK tự phát hành): đọc docs/appcast.xml THẬT qua URL của app.
  // [respond] thay phản hồi máy chủ (mặc định: file thật, 200) để thử lỗi mạng / file hỏng.
  Future<Upgrader> androidUpgrader(WidgetTester t, String installed,
      {Future<http.Response> Function()? respond}) async {
    SharedPreferences.setMockInitialValues({});
    final xml = File('docs/appcast.xml').readAsStringSync();
    return (await t.runAsync(() async {
      final client = MockClient((req) async {
        if (req.url.toString() != androidAppcastUrl) return http.Response('', 404);
        if (respond != null) return respond();
        return http.Response(xml, 200, headers: {'content-type': 'application/xml; charset=utf-8'});
      });
      final u = Upgrader(
        client: client,
        upgraderOS: MockUpgraderOS(os: 'android', android: true),
        countryCode: 'VN',
        languageCode: 'vi',
        storeController: UpgraderStoreController(
          onAndroid: () => UpgraderAppcastStore(appcastURL: androidAppcastUrl),
        ),
      );
      u.installPackageInfo(packageInfo: PackageInfo(
          appName: 'Boba Empire', packageName: 'com.game.pc.boba', version: installed, buildNumber: '1'));
      await u.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return u;
    }))!;
  }

  testWidgets('Android appcast: bản cũ hơn appcast → có bản mới, nút mở trang tải', (t) async {
    final u = await androidUpgrader(t, '1.0.0');
    expect(u.isUpdateAvailable(), isTrue);
    expect(u.currentAppStoreListingURL, 'https://bobaempiregame.com/android.html');
    expect(u.blocked(), isFalse);
  });

  testWidgets('Android appcast: đã ở bản trong appcast → không hỏi', (t) async {
    final xml = File('docs/appcast.xml').readAsStringSync();
    final v = RegExp(r'sparkle:version="([^"]+)"').firstMatch(xml)!.group(1)!;
    final u = await androidUpgrader(t, v);
    expect(u.isUpdateAvailable(), isFalse);
  });

  String appcastWith(String item) => '<?xml version="1.0" encoding="utf-8"?>'
      '<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">'
      '<channel>$item</channel></rss>';
  Future<http.Response> ok(String body) async => http.Response(body, 200,
      headers: {'content-type': 'application/xml; charset=utf-8'});

  testWidgets('Android appcast: máy chủ 404 → không hỏi, không crash', (t) async {
    final u = await androidUpgrader(t, '1.0.0', respond: () async => http.Response('', 404));
    expect(u.isUpdateAvailable(), isFalse);
  });

  testWidgets('Android appcast: mất mạng → không hỏi, không crash', (t) async {
    final u = await androidUpgrader(t, '1.0.0',
        respond: () async => throw const SocketException('offline'));
    expect(u.isUpdateAvailable(), isFalse);
  });

  testWidgets('Android appcast: XML hỏng → không hỏi, không crash', (t) async {
    final u = await androidUpgrader(t, '1.0.0', respond: () => ok('<rss><channel><item>'));
    expect(u.isUpdateAvailable(), isFalse);
  });

  testWidgets('Android appcast: chỉ có bản iOS → Android bỏ qua', (t) async {
    final u = await androidUpgrader(t, '1.0.0', respond: () => ok(appcastWith(
        '<item><enclosure url="https://x" sparkle:version="9.0.0" sparkle:os="ios"/></item>')));
    expect(u.isUpdateAvailable(), isFalse);
  });

  testWidgets('Android appcast: nhiều bản → chọn bản cao nhất', (t) async {
    final u = await androidUpgrader(t, '1.0.0', respond: () => ok(appcastWith(
        '<item><enclosure url="https://a" sparkle:version="1.0.15" sparkle:os="android"/></item>'
        '<item><enclosure url="https://b" sparkle:version="1.0.20" sparkle:os="android"/></item>')));
    expect(u.currentAppStoreVersion, '1.0.20');
    expect(u.currentAppStoreListingURL, 'https://b');
  });

  testWidgets('Android appcast: criticalUpdate → bị chặn, hộp không có "Để sau"', (t) async {
    final u = await androidUpgrader(t, '1.0.14', respond: () => ok(appcastWith(
        '<item><sparkle:tags><sparkle:criticalUpdate/></sparkle:tags>'
        '<enclosure url="https://bobaempiregame.com/android.html" sparkle:version="1.0.15" sparkle:os="android"/></item>')));
    expect(u.isUpdateAvailable(), isTrue);
    expect(u.blocked(), isTrue);
    await t.pumpWidget(MaterialApp(
      home: UpgradeAlert(upgrader: u, child: const Scaffold(body: Text('home'))),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('CẬP NHẬT'), findsOneWidget);
    expect(find.text('ĐỂ SAU'), findsNothing);
  });

  testWidgets('Android appcast: bản thường → hộp có Cập nhật + Để sau', (t) async {
    final u = await androidUpgrader(t, '1.0.0');
    await t.pumpWidget(MaterialApp(
      home: UpgradeAlert(upgrader: u, child: const Scaffold(body: Text('home'))),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('CẬP NHẬT'), findsOneWidget);
    expect(find.text('ĐỂ SAU'), findsOneWidget);
  });

  // Lỗi đã gặp trên máy thật: upgrader mở link Android bằng chế độ "không phải trình duyệt" → trang
  // tải không mở. Nút Cập nhật phải tự mở android.html bằng trình duyệt và chặn bước mở của upgrader.
  testWidgets('Android: bấm Cập nhật → tự mở trang tải, chặn upgrader', (t) async {
    final u = await androidUpgrader(t, '1.0.0');
    final opened = <Uri>[];
    expect(handleUpdateTap(u, android: true, open: opened.add), isFalse);
    expect(opened, [Uri.parse('https://bobaempiregame.com/android.html')]);
  });

  testWidgets('iOS: bấm Cập nhật → để upgrader mở App Store như cũ', (t) async {
    final u = await androidUpgrader(t, '1.0.0');
    final opened = <Uri>[];
    expect(handleUpdateTap(u, android: false, open: opened.add), isTrue);
    expect(opened, isEmpty);
  });
}
