/// Regression cho lớp bug tràn số ở danh sách Bảng xếp hạng PK (cùng lớp bug
/// với leaderboard_overflow_test.dart — xem shop-tile-overflow-pattern
/// memory): 1 hàng có tên dài + số trận thắng/thua cực lớn không được làm
/// tràn RenderFlex.
library;

import 'package:boba_empire/arena/arena_leaderboard_controller.dart';
import 'package:boba_empire/arena/arena_leaderboard_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/ui/arena_leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controller giả: giữ nguyên state đã seed, không chạm Supabase.instance
/// (refresh()/submitNickname() thật sẽ gọi mạng, không có trong test).
class _FakeArenaLeaderboardController extends ArenaLeaderboardController {
  _FakeArenaLeaderboardController(this._seed);
  final ArenaLeaderboardViewState _seed;

  @override
  ArenaLeaderboardViewState build() => _seed;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> submitNickname(String nickname) async {}
}

void main() {
  testWidgets('hàng tên dài + số trận cực lớn không tràn RenderFlex',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const entries = [
      ArenaLeaderboardEntry(
        userId: 'me',
        nickname: 'NguoiChoiTenRatRatRatDaiVuotKhungHinh',
        wins: 999999999,
        losses: 888888888,
        matches: 1888888887,
        rank: 1,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          arenaLeaderboardControllerProvider.overrideWith(
            () => _FakeArenaLeaderboardController(
              const ArenaLeaderboardLoaded(
                entries: entries,
                myRank: 1,
                myUserId: 'me',
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ArenaLeaderboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle(); // ném FlutterError nếu RenderFlex tràn

    expect(find.textContaining('NguoiChoiTenRatRatRatDaiVuotKhungHinh'),
        findsOneWidget);
  });
}
