/// Regression cho lớp bug tràn số ở danh sách Bảng xếp hạng: 1 hàng có
/// prestige_stars/lifetime_earnings cực lớn (khớp gần đúng save whale thật
/// gặp trên máy: ~16,6 tỷ Sao) không được làm tràn RenderFlex — xem
/// shop-tile-overflow-pattern memory. Bug thật: `Text(l10n.leaderboardStars(
/// entry.prestigeStars))`/`Text(formatNumber(entry.lifetimeEarnings))` là
/// con của `Row` không có `Flexible`, sizes theo nội dung không giới hạn.
library;

import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/leaderboard_controller.dart';
import 'package:boba_empire/leaderboard/leaderboard_repository.dart';
import 'package:boba_empire/ui/leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controller giả: giữ nguyên state đã seed, không chạm Supabase.instance
/// (refresh()/submitNickname() thật sẽ gọi mạng, không có trong test).
class _FakeLeaderboardController extends LeaderboardController {
  _FakeLeaderboardController(this._seed);
  final LeaderboardViewState _seed;

  @override
  LeaderboardViewState build() => _seed;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> submitNickname(String nickname) async {}
}

void main() {
  testWidgets(
      'hàng whale (~16,6 tỷ Sao, Xu cả đời cực lớn) không tràn RenderFlex',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const entries = [
      LeaderboardEntry(
        userId: 'me',
        nickname: 'WhaleTest',
        lifetimeEarnings: 1.108e24,
        prestigeStars: 16640428646,
        stage: 5,
        rank: 1,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaderboardControllerProvider.overrideWith(
            () => _FakeLeaderboardController(
              const LeaderboardLoaded(
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
          home: LeaderboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle(); // ném FlutterError nếu RenderFlex tràn

    expect(find.textContaining('WhaleTest'), findsOneWidget);
  });
}
