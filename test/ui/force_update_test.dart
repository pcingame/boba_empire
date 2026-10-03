/// Kiểm chứng ĐÚNG giả định của hướng dẫn force update: thẻ `[:mav: 1.0.6]` trong
/// mô tả bản live trên App Store (và thẻ Play) chặn bản cũ — hộp cập nhật mất nút
/// "Để sau/Bỏ qua" — còn bản mới nhất / mô tả không có thẻ thì không bị chặn.
/// Dùng chính `upgrader` (parse JSON iTunes thật) với HTTP giả, không chạm mạng.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

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
      // Máy chạy test là macOS: ép mọi nền tảng về nhánh App Store.
      storeController: UpgraderStoreController(
        onAndroid: () => UpgraderAppStore(),
        oniOS: () => UpgraderAppStore(),
        onMacOS: () => UpgraderAppStore(),
      ),
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
}
