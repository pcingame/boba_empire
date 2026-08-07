import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  // Game chạy dọc; surface test mặc định (800x600 ngang) làm shop tràn.
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BobaEmpireApp(),
    ),
  );
}

void main() {
  testWidgets('màn hình chính hiển thị nút pha trà và shop', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Chạm pha trà'), findsOneWidget);
    expect(find.text('Trà đen'), findsOneWidget);
    expect(find.textContaining('Xu'), findsWidgets);

    // Tháo widget để container Riverpod dispose → hủy timer, tránh timer treo.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('chạm pha trà làm tiền tăng', (tester) async {
    await _pumpApp(tester);

    expect(find.text('0 Xu'), findsOneWidget);
    await tester.tap(find.text('Chạm pha trà'));
    await tester.pump(); // frame cho cú chạm
    await tester.pump(const Duration(milliseconds: 600)); // đợi counter chạy xong
    expect(find.text('1 Xu'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
