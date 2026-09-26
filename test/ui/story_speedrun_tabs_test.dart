/// Trang Bảng xếp hạng tốc độ có 2 tab (Hồi 1 = tới Chương 18, Hồi 2 = tới
/// Chương 28), mỗi tab một controller/bảng riêng.
library;

import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/story_speedrun_controller.dart';
import 'package:boba_empire/leaderboard/story_speedrun_repository.dart';
import 'package:boba_empire/ui/story_speedrun_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controller giả: giữ nguyên state đã seed, không chạm Supabase.instance.
class _Fake extends StorySpeedrunController {
  _Fake(this._seed, SpeedrunBoard board) : super(board);
  final StorySpeedrunViewState _seed;

  @override
  StorySpeedrunViewState build() => _seed;

  @override
  Future<void> refresh({bool silent = false}) async {}

  @override
  Future<void> submitNickname(String nickname) async {}
}

const _mainEntry = StorySpeedrunEntry(
  userId: 'a',
  nickname: 'NguoiHoiMot',
  completeSeconds: 3600,
  rank: 1,
);

const _extEntry = StorySpeedrunEntry(
  userId: 'b',
  nickname: 'NguoiChoiTenRatRatRatDaiHoiHai',
  completeSeconds: 99 * 86400 + 5 * 3600,
  rank: 1,
);

Widget _app(Locale locale) => ProviderScope(
      overrides: [
        storySpeedrunControllerProvider.overrideWith(
          () => _Fake(
            const StorySpeedrunLoaded(entries: [_mainEntry], myUserId: 'me', hasCompleted: true),
            SpeedrunBoard.main,
          ),
        ),
        storySpeedrunExtControllerProvider.overrideWith(
          () => _Fake(
            const StorySpeedrunLoaded(entries: [_extEntry], myUserId: 'me', hasCompleted: false),
            SpeedrunBoard.ext,
          ),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StorySpeedrunPage(),
      ),
    );

void main() {
  testWidgets('mỗi tab hiện đúng bảng và đúng banner của mình', (tester) async {
    await tester.pumpWidget(_app(const Locale('vi')));
    await tester.pumpAndSettle();

    // Tab Hồi 1: có dữ liệu Hồi 1, đã hoàn thành nên không có banner nào.
    expect(find.text('NguoiHoiMot'), findsOneWidget);
    expect(find.textContaining('NguoiChoiTenRatRatRatDaiHoiHai'), findsNothing);
    expect(find.textContaining('Chương 28'), findsNothing);

    await tester.tap(find.text('Hồi 2'));
    await tester.pumpAndSettle();

    // Tab Hồi 2: dữ liệu Hồi 2 + banner nhắc hoàn thành Chương 28.
    expect(find.textContaining('NguoiChoiTenRatRatRatDaiHoiHai'), findsOneWidget);
    expect(find.textContaining('Chương 28'), findsOneWidget);
    expect(find.text('NguoiHoiMot'), findsNothing);

    // Về lại Hồi 1: dữ liệu vẫn còn (tab giữ trạng thái, không tải lại).
    await tester.tap(find.text('Hồi 1'));
    await tester.pumpAndSettle();
    expect(find.text('NguoiHoiMot'), findsOneWidget);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('không tràn ở ${locale.languageCode}, máy nhỏ + chữ to, cả 2 tab', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.6)),
          child: _app(locale),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(TabBar)))!;
      await tester.tap(find.text(l10n.storySpeedrunTabExt));
      await tester.pumpAndSettle(); // ném FlutterError nếu RenderFlex tràn
    });
  }
}
