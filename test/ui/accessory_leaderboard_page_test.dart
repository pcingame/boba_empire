/// Bảng xếp hạng Sưu tập: danh hiệu 3 bậc (hạng 1 "Vua Phụ Kiện", hạng 2-20
/// "Nhà Sưu Tầm" cho trường hợp test này) hiện đúng tới hạng 20, hạng 21 trở
/// đi không có. Controller giả — cùng khuôn `story_speedrun_tabs_test.dart`.
library;

import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/accessory_leaderboard_controller.dart';
import 'package:boba_empire/leaderboard/accessory_leaderboard_repository.dart';
import 'package:boba_empire/ui/accessory_leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _entries = [
  AccessoryLeaderboardEntry(
      userId: 'u1', nickname: 'HangNhat', ownedCount: 50, rank: 1),
  AccessoryLeaderboardEntry(
      userId: 'u20', nickname: 'HangHaiMuoi', ownedCount: 20, rank: 20),
  AccessoryLeaderboardEntry(
      userId: 'u21', nickname: 'HangHaiMot', ownedCount: 19, rank: 21),
];

class _Fake extends AccessoryLeaderboardController {
  @override
  AccessoryLeaderboardViewState build() => const AccessoryLeaderboardLoaded(
        entries: _entries,
        myUserId: 'someone-else',
        myOwnedCount: 0,
      );

  @override
  Future<void> refresh({bool silent = false}) async {}
}

Widget _app() => ProviderScope(
      overrides: [
        accessoryLeaderboardControllerProvider.overrideWith(_Fake.new),
      ],
      child: const MaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccessoryLeaderboardPage(),
      ),
    );

void main() {
  testWidgets(
      'hạng 1 có 🥇 Vua Phụ Kiện, hạng 20 có 🏅 Nhà Sưu Tầm, hạng 21 thì không',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('🥇 Vua Phụ Kiện'), findsOneWidget);
    expect(find.text('🏅 Nhà Sưu Tầm'), findsOneWidget);
    // Hạng 21 không có dòng danh hiệu nào (không tìm thấy text chứa nó).
    expect(find.textContaining('Vua Phụ Kiện'), findsOneWidget);
    expect(find.textContaining('Nhà Sưu Tầm'), findsOneWidget);
  });
}
